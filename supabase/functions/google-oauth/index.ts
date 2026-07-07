// ============================================================================
// google-oauth — server-side Google OAuth for read-only photo access.
//
// All token handling happens here, never in the Flutter client.
//   GET ?action=start&provider=google_photos|gmail   (Authorized: user JWT)
//        -> { url } : the Google consent URL to open.
//   GET ?code=...&state=...                            (Google redirect)
//        -> exchanges the code for tokens, stores them in oauth_tokens +
//           upserts connected_accounts, then redirects back to the app.
//
// Requires secrets: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, OAUTH_REDIRECT_URL
// (this function's public URL), APP_REDIRECT_URL (where to send the user after).
// See docs/API_INTEGRATIONS.md for the full setup.
// ============================================================================
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const SCOPES: Record<string, string> = {
  google_photos: 'https://www.googleapis.com/auth/photoslibrary.readonly',
  gmail: 'https://www.googleapis.com/auth/gmail.readonly',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const clientId = Deno.env.get('GOOGLE_CLIENT_ID');
  const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET');
  const redirectUrl = Deno.env.get('OAUTH_REDIRECT_URL');
  const appRedirect = Deno.env.get('APP_REDIRECT_URL') ?? 'http://localhost:3000';

  if (!clientId || !clientSecret || !redirectUrl) {
    return json({
      error: 'not_configured',
      message:
        'Google OAuth is not configured. Set GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET and OAUTH_REDIRECT_URL as function secrets. See docs/API_INTEGRATIONS.md.',
    }, 501);
  }

  const url = new URL(req.url);
  const action = url.searchParams.get('action');
  const code = url.searchParams.get('code');

  // ---- Step 1: build the consent URL --------------------------------------
  if (action === 'start') {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error } = await userClient.auth.getUser();
    if (error || !userData.user) return json({ error: 'unauthorized' }, 401);

    const provider = url.searchParams.get('provider') ?? 'google_photos';
    const scope = SCOPES[provider] ?? SCOPES.google_photos;

    // NOTE: production should sign/encrypt `state`. Here it carries user+provider.
    const state = btoa(JSON.stringify({ uid: userData.user.id, provider }));

    const consent = new URL('https://accounts.google.com/o/oauth2/v2/auth');
    consent.searchParams.set('client_id', clientId);
    consent.searchParams.set('redirect_uri', redirectUrl);
    consent.searchParams.set('response_type', 'code');
    consent.searchParams.set('scope', scope);
    consent.searchParams.set('access_type', 'offline');
    consent.searchParams.set('prompt', 'consent');
    consent.searchParams.set('state', state);

    return json({ url: consent.toString() });
  }

  // ---- Step 2: handle Google's redirect (exchange code for tokens) --------
  if (code) {
    const stateRaw = url.searchParams.get('state') ?? '';
    let uid = '';
    let provider = 'google_photos';
    try {
      const parsed = JSON.parse(atob(stateRaw));
      uid = parsed.uid;
      provider = parsed.provider;
    } catch {
      return json({ error: 'bad_state' }, 400);
    }

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUrl,
        grant_type: 'authorization_code',
      }),
    });
    const tokens = await tokenRes.json();
    if (!tokenRes.ok) return json({ error: 'token_exchange_failed', detail: tokens }, 400);

    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const expiresAt = new Date(Date.now() + (tokens.expires_in ?? 3600) * 1000).toISOString();

    await admin.from('oauth_tokens').upsert({
      user_id: uid,
      provider,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      token_type: tokens.token_type,
      scopes: [SCOPES[provider]],
      expires_at: expiresAt,
    }, { onConflict: 'user_id,provider' });

    await admin.from('connected_accounts').upsert({
      user_id: uid,
      provider,
      status: 'connected',
      scopes: [SCOPES[provider]],
    }, { onConflict: 'user_id,provider' });

    // Send the user back into the app.
    return new Response(null, { status: 302, headers: { Location: appRedirect } });
  }

  return json({ error: 'unknown_action' }, 400);
});
