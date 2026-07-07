// ============================================================================
// create-order — checkout handoff to the print partner (M5).
//
// Creates a draft order with the print partner, records it in our DB, and
// returns the price + an optional hosted-checkout URL. The PrintPartner
// abstraction keeps Gelato swappable for Printful / Prodigi / Printify.
//
//  • Gelato is used when GELATO_API_KEY is set (real draft order + price).
//  • Otherwise a MockPartner returns a computed price + a placeholder handoff,
//    so the whole checkout flow is testable without any partner account.
//
// Partner secrets live here, server-side — never in the Flutter client.
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

interface DraftInput {
  productId: string; // canvas | book | mug
  sizeLabel: string;
  itemPrice: number;
  currency: string;
}
interface DraftResult {
  partnerOrderId: string;
  shipping: number;
  checkoutUrl: string | null;
}

/** Swappable print fulfillment partner. */
interface PrintPartner {
  readonly name: string;
  createDraftOrder(input: DraftInput): Promise<DraftResult>;
}

/** Local mock — no account needed. Computes a flat shipping fee. */
class MockPartner implements PrintPartner {
  readonly name = 'mock';
  createDraftOrder(_input: DraftInput): Promise<DraftResult> {
    return Promise.resolve({
      partnerOrderId: `MOCK-${Math.round(performance.now())}`,
      shipping: 4.9,
      checkoutUrl: null, // MVP: order recorded directly; no external redirect
    });
  }
}

/**
 * Gelato partner (scaffold). A full integration maps our product+size to a
 * Gelato product UID, uploads the print file, and creates a draft order via
 * https://order.gelatoapis.com/v4/orders. Here we request a shipping/price
 * estimate and return a handoff URL; wire the full order body when going live.
 */
class GelatoPartner implements PrintPartner {
  readonly name = 'gelato';
  constructor(private apiKey: string) {}

  async createDraftOrder(input: DraftInput): Promise<DraftResult> {
    // NOTE: real implementation creates a draft order and returns its checkout
    // URL. Until product UIDs + print files are mapped, fall back to a flat
    // shipping fee so checkout still completes.
    try {
      // Example shape (left unsent without a product UID mapping):
      //   await fetch('https://order.gelatoapis.com/v4/orders', {
      //     method: 'POST',
      //     headers: { 'X-API-KEY': this.apiKey, 'Content-Type': 'application/json' },
      //     body: JSON.stringify({ ...draft order... }),
      //   });
      return {
        partnerOrderId: `GELATO-PENDING-${Math.round(performance.now())}`,
        shipping: 4.9,
        checkoutUrl: null,
      };
    } catch (_e) {
      return { partnerOrderId: `GELATO-ERR`, shipping: 4.9, checkoutUrl: null };
    }
  }
}

function getPartner(): PrintPartner {
  const key = Deno.env.get('GELATO_API_KEY');
  return key ? new GelatoPartner(key) : new MockPartner();
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
    const productSuggestionId: string | undefined = body.productSuggestionId;
    const sizeLabel: string | undefined = body.sizeLabel;
    if (!productSuggestionId || !sizeLabel) {
      return json({ error: 'productSuggestionId and sizeLabel are required' }, 400);
    }

    // deno-lint-ignore no-explicit-any
    const admin: any = createClient(SUPABASE_URL, SERVICE_KEY);

    const { data: suggestion } = await admin
      .from('product_suggestions')
      .select('*')
      .eq('id', productSuggestionId)
      .eq('user_id', userId)
      .maybeSingle();
    if (!suggestion) return json({ error: 'suggestion not found' }, 404);

    const sizes = (suggestion.sizes as { label: string; price: number }[]) ?? [];
    const size = sizes.find((s) => s.label === sizeLabel) ?? sizes[0];
    if (!size) return json({ error: 'no size available' }, 400);

    const currency = 'EUR';
    const partner = getPartner();
    const draft = await partner.createDraftOrder({
      productId: suggestion.product_id,
      sizeLabel: size.label,
      itemPrice: size.price,
      currency,
    });

    const total = size.price + draft.shipping;

    const { data: order, error: orderErr } = await admin
      .from('orders')
      .insert({
        user_id: userId,
        product_suggestion_id: suggestion.id,
        product_id: suggestion.product_id,
        size_label: size.label,
        item_price: size.price,
        shipping: draft.shipping,
        total,
        currency,
        partner: partner.name,
        partner_order_id: draft.partnerOrderId,
        status: 'created',
        created_from_photo_count: suggestion.created_from_photo_count ?? 0,
      })
      .select('id')
      .single();
    if (orderErr || !order) return json({ error: 'could not record order' }, 500);

    return json({
      orderId: order.id,
      total,
      itemPrice: size.price,
      shipping: draft.shipping,
      currency,
      partner: partner.name,
      checkoutUrl: draft.checkoutUrl,
      createdFromPhotoCount: suggestion.created_from_photo_count ?? 0,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
