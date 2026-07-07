// ============================================================================
// import-photos — pulls a user's photos (read-only) into MemoryFlow.
//
// Returns its jobId immediately and runs the import in the background
// (EdgeRuntime.waitUntil), so the client can poll import_jobs for live progress.
//
// Modes:
//  • mode=sample  — no Google account needed. Generates a small library with
//    perceptual hashes (incl. duplicates) to exercise dedupe. Testable today.
//  • mode=google  — pages the real Google Photos Library API with the user's
//    stored read-only token. Rate-limit aware, resumable via import_jobs.cursor.
//
// Writes use the service-role key (RLS bypass); the caller is authenticated from
// their JWT so we only ever write that user's rows. Originals are NEVER
// downloaded — only a thumbnail reference + metadata.
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

function sampleHash(seed: string): string {
  let h = 0xcbf29ce4 >>> 0;
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return (h.toString(16).padStart(8, '0') + (h ^ 0x9e3779b9).toString(16).padStart(8, '0'));
}

async function aHash(bytes: Uint8Array): Promise<string> {
  try {
    const { Image } = await import('https://deno.land/x/imagescript@1.3.0/mod.ts');
    const img = await Image.decode(bytes);
    const small = img.resize(8, 8);
    const gray: number[] = [];
    for (let y = 0; y < 8; y++) {
      for (let x = 0; x < 8; x++) {
        const [r, g, b] = Image.colorToRGBA(small.getPixelAt(x + 1, y + 1));
        gray.push((r + g + b) / 3);
      }
    }
    const avg = gray.reduce((a, c) => a + c, 0) / gray.length;
    let bits = '';
    for (const v of gray) bits += v >= avg ? '1' : '0';
    let hex = '';
    for (let i = 0; i < 64; i += 4) hex += parseInt(bits.slice(i, i + 4), 2).toString(16);
    return hex;
  } catch (_e) {
    let h = 0xcbf29ce4 >>> 0;
    for (let i = 0; i < bytes.length; i += 97) {
      h ^= bytes[i];
      h = Math.imul(h, 0x01000193) >>> 0;
    }
    return h.toString(16).padStart(16, '0');
  }
}

function sampleSeeds(count: number): string[] {
  const seeds: string[] = [];
  for (let i = 0; i < count; i++) seeds.push(`mf-${i}`);
  if (count > 6) {
    seeds.push('mf-1');
    seeds.push('mf-3');
  }
  return seeds;
}

// deno-lint-ignore no-explicit-any
type Admin = any;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: 'unauthorized' }, 401);
    const userId = userData.user.id;

    const body = await req.json().catch(() => ({}));
    const provider: string = body.provider ?? 'google_photos';
    const mode: string = body.mode ?? 'sample';
    const count = Math.min(Math.max(Number(body.count ?? 24), 4), 60);

    const admin: Admin = createClient(SUPABASE_URL, SERVICE_KEY);

    const { data: job, error: jobErr } = await admin
      .from('import_jobs')
      .insert({ user_id: userId, provider, mode, status: 'running', total: count, processed: 0 })
      .select()
      .single();
    if (jobErr || !job) return json({ error: 'could not create job' }, 500);

    const run = async () => {
      try {
        if (mode === 'google') {
          await importGoogle(admin, userId, provider, job.id);
        } else {
          await importSample(admin, userId, provider, job.id, count);
        }
      } catch (e) {
        await admin.from('import_jobs').update({ status: 'error', message: String(e) }).eq('id', job.id);
      }
    };

    // Run the import in the background so the client gets the jobId immediately
    // and can poll import_jobs for live progress.
    // @ts-ignore EdgeRuntime is provided by the Supabase edge runtime.
    if (typeof EdgeRuntime !== 'undefined' && EdgeRuntime.waitUntil) {
      // @ts-ignore
      EdgeRuntime.waitUntil(run());
    } else {
      await run();
    }

    return json({ jobId: job.id, status: 'running' });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

async function importSample(
  admin: Admin,
  userId: string,
  provider: string,
  jobId: string,
  count: number,
): Promise<void> {
  const seeds = sampleSeeds(count);
  await admin.from('import_jobs').update({ total: seeds.length }).eq('id', jobId);

  let processed = 0;
  let duplicates = 0;
  const seen = new Set<string>();

  for (const seed of seeds) {
    const phash = sampleHash(seed);
    const { data: existing } = await admin
      .from('photos').select('id').eq('user_id', userId).eq('perceptual_hash', phash).maybeSingle();

    if (existing || seen.has(phash)) {
      duplicates++;
    } else {
      seen.add(phash);
      await admin.from('photos').insert({
        user_id: userId,
        external_id: seed,
        thumbnail_url: `https://picsum.photos/seed/${seed}/400/400`,
        storage_path: `${userId}/${seed}.jpg`,
        perceptual_hash: phash,
        quality_score: 0.6 + (seed.length % 4) * 0.1,
      });
    }
    processed++;
    await new Promise((r) => setTimeout(r, 140)); // visible live progress
    await admin.from('import_jobs').update({ processed, duplicates }).eq('id', jobId);
  }

  await admin.from('connected_accounts').upsert(
    { user_id: userId, provider, status: 'connected', external_account_label: 'Demo import', scopes: ['readonly'] },
    { onConflict: 'user_id,provider' },
  );
  await admin.from('import_jobs')
    .update({ status: 'done', processed, duplicates, message: 'Imported sample library' })
    .eq('id', jobId);
}

// Real Google Photos Library import (read-only). Resumable + rate-limit aware.
async function importGoogle(
  admin: Admin,
  userId: string,
  provider: string,
  jobId: string,
): Promise<void> {
  const { data: tok } = await admin
    .from('oauth_tokens').select('*').eq('user_id', userId).eq('provider', provider).maybeSingle();

  if (!tok) {
    await admin.from('import_jobs')
      .update({ status: 'error', message: 'No Google account connected. Configure OAuth (see docs/API_INTEGRATIONS.md).' })
      .eq('id', jobId);
    return;
  }

  let accessToken = tok.access_token as string;
  if (tok.expires_at && new Date(tok.expires_at as string).getTime() < Date.now()) {
    accessToken = await refreshGoogleToken(admin, userId, provider, tok.refresh_token as string);
  }

  const { data: jobRow } = await admin.from('import_jobs').select('cursor').eq('id', jobId).single();
  let pageToken: string | undefined = (jobRow?.cursor as { pageToken?: string } | null)?.pageToken;

  let processed = 0;
  let duplicates = 0;
  const MAX_PER_RUN = 200;

  while (processed < MAX_PER_RUN) {
    const url = new URL('https://photoslibrary.googleapis.com/v1/mediaItems');
    url.searchParams.set('pageSize', '50');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
    if (res.status === 429 || res.status === 503) {
      await admin.from('import_jobs').update({ cursor: { pageToken }, processed, duplicates }).eq('id', jobId);
      await new Promise((r) => setTimeout(r, 2000));
      continue;
    }
    if (!res.ok) {
      await admin.from('import_jobs').update({ status: 'error', message: `Google API ${res.status}` }).eq('id', jobId);
      return;
    }

    const data = await res.json();
    const items: Array<Record<string, unknown>> = data.mediaItems ?? [];
    for (const item of items) {
      const mime = (item.mimeType as string) ?? '';
      if (!mime.startsWith('image/')) continue;
      const thumbUrl = `${item.baseUrl as string}=w400-h400`;
      let phash = '';
      try {
        const imgRes = await fetch(thumbUrl);
        phash = await aHash(new Uint8Array(await imgRes.arrayBuffer()));
      } catch {
        phash = sampleHash(item.id as string);
      }
      const { data: existing } = await admin
        .from('photos').select('id').eq('user_id', userId).eq('perceptual_hash', phash).maybeSingle();
      if (existing) {
        duplicates++;
      } else {
        await admin.from('photos').insert({
          user_id: userId,
          external_id: item.id as string,
          thumbnail_url: thumbUrl,
          perceptual_hash: phash,
          taken_at: (item.mediaMetadata as { creationTime?: string } | undefined)?.creationTime,
        });
      }
      processed++;
      await admin.from('import_jobs').update({ processed, duplicates }).eq('id', jobId);
    }

    pageToken = data.nextPageToken;
    await admin.from('import_jobs').update({ cursor: { pageToken: pageToken ?? null } }).eq('id', jobId);
    if (!pageToken) break;
  }

  const done = !pageToken;
  await admin.from('import_jobs')
    .update({ status: done ? 'done' : 'running', message: done ? 'Import complete' : 'Batch complete — re-run to continue' })
    .eq('id', jobId);
}

async function refreshGoogleToken(
  admin: Admin,
  userId: string,
  provider: string,
  refreshToken: string,
): Promise<string> {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: Deno.env.get('GOOGLE_CLIENT_ID') ?? '',
      client_secret: Deno.env.get('GOOGLE_CLIENT_SECRET') ?? '',
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });
  const data = await res.json();
  const accessToken = data.access_token as string;
  const expiresAt = new Date(Date.now() + (data.expires_in ?? 3600) * 1000).toISOString();
  await admin.from('oauth_tokens').update({ access_token: accessToken, expires_at: expiresAt })
    .eq('user_id', userId).eq('provider', provider);
  return accessToken;
}
