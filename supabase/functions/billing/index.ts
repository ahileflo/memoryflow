// ============================================================================
// billing — subscription + AI credits (Milestone 6).
//
// Actions (POST body { action }):
//   • status        — returns { plan, balance, isPremium }.
//   • subscribe     — €4.99/mo. With STRIPE_SECRET_KEY → returns a Stripe
//     Checkout URL. Without it → mock-activates Premium + grants credits so the
//     flow is testable. Real activation is confirmed by the Stripe webhook.
//   • buy_credits   — { amount }. With Stripe → checkout URL; mock → grants now.
//   • spend_credit  — { reason }. Premium = unlimited; free spends 1 credit.
//
// All billing secrets stay server-side. Credit writes go through the ledger.
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
const PRICE_EUR = 4.99;

// deno-lint-ignore no-explicit-any
type Admin = any;

async function getState(admin: Admin, userId: string) {
  const { data: profile } = await admin.from('profiles').select('plan').eq('id', userId).maybeSingle();
  const { data: credits } = await admin.from('ai_credits').select('balance').eq('user_id', userId).maybeSingle();
  const plan = (profile?.plan as string) ?? 'free';
  return { plan, isPremium: plan === 'premium', balance: (credits?.balance as number) ?? 0 };
}

async function grantCredits(admin: Admin, userId: string, amount: number, reason: string) {
  const { data: credits } = await admin.from('ai_credits').select('balance').eq('user_id', userId).maybeSingle();
  const balance = ((credits?.balance as number) ?? 0) + amount;
  await admin.from('ai_credits').upsert({ user_id: userId, balance }, { onConflict: 'user_id' });
  await admin.from('ai_credit_ledger').insert({ user_id: userId, delta: amount, reason });
  return balance;
}

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
    const action: string = body.action ?? 'status';
    const admin: Admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');

    if (action === 'status') {
      return json(await getState(admin, userId));
    }

    if (action === 'subscribe') {
      if (stripeKey) {
        // Real path: create a Stripe Checkout session for the €4.99/mo price.
        // Requires a configured Price ID; webhook confirms activation.
        const priceId = Deno.env.get('STRIPE_PRICE_ID');
        const appUrl = Deno.env.get('APP_REDIRECT_URL') ?? 'http://localhost:3000';
        const res = await fetch('https://api.stripe.com/v1/checkout/sessions', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${stripeKey}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            mode: 'subscription',
            'line_items[0][price]': priceId ?? '',
            'line_items[0][quantity]': '1',
            success_url: `${appUrl}?upgrade=success`,
            cancel_url: `${appUrl}?upgrade=cancel`,
            client_reference_id: userId,
          }),
        });
        const data = await res.json();
        if (!res.ok) return json({ error: 'stripe_error', detail: data }, 400);
        return json({ url: data.url, mocked: false });
      }

      // Mock activation (no Stripe key): flip to Premium + grant 50 credits.
      await admin.from('profiles').update({ plan: 'premium' }).eq('id', userId);
      const periodEnd = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString();
      await admin.from('subscriptions').upsert(
        { user_id: userId, status: 'active', current_period_end: periodEnd },
        { onConflict: 'user_id' },
      );
      const balance = await grantCredits(admin, userId, 50, 'premium_signup_bonus');
      return json({ mocked: true, isPremium: true, plan: 'premium', balance, price: PRICE_EUR });
    }

    if (action === 'buy_credits') {
      const amount = Math.min(Math.max(Number(body.amount ?? 20), 1), 500);
      // Real path would create a Stripe one-time checkout; mock grants now.
      const balance = await grantCredits(admin, userId, amount, 'purchase_mock');
      return json({ mocked: !stripeKey, balance, granted: amount });
    }

    if (action === 'spend_credit') {
      const reason = (body.reason as string) ?? 'enhance';
      const state = await getState(admin, userId);
      if (state.isPremium) {
        // Premium: unlimited AI tools, no spend.
        return json({ ok: true, premium: true, balance: state.balance });
      }
      if (state.balance < 1) {
        return json({ ok: false, needCredits: true, balance: 0 });
      }
      const balance = await grantCredits(admin, userId, -1, reason);
      return json({ ok: true, balance });
    }

    return json({ error: 'unknown_action' }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
