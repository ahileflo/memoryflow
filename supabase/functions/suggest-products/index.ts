// ============================================================================
// suggest-products — generate gift suggestions from a user's top albums (M5).
//
// For each top album, proposes a printable product (canvas / photo book / mug)
// and writes the marketing copy. Idempotent: clears the user's suggestions and
// rebuilds. Persists to product_suggestions.
//
//  • mode=ai        — Claude (claude-opus-4-8) writes the product name +
//    description per album, structured JSON output. Requires ANTHROPIC_API_KEY.
//  • mode=heuristic — template copy, no external dependency (default/testable).
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

// deno-lint-ignore no-explicit-any
type Admin = any;
// deno-lint-ignore no-explicit-any
type Album = any;

const SIZES: Record<string, { sizes: { label: string; price: number }[]; defaultIndex: number; tag: string }> = {
  canvas: {
    tag: 'Wall canvas',
    defaultIndex: 1,
    sizes: [
      { label: '30×20', price: 29 },
      { label: '40×30', price: 49 },
      { label: '60×40', price: 79 },
    ],
  },
  book: {
    tag: 'Photo book',
    defaultIndex: 1,
    sizes: [
      { label: '20 pages', price: 29 },
      { label: '28 pages', price: 39 },
      { label: '40 pages', price: 59 },
    ],
  },
  mug: {
    tag: 'Gift',
    defaultIndex: 0,
    sizes: [
      { label: 'Standard', price: 15 },
      { label: 'Large', price: 19 },
    ],
  },
};

/** Map an album type to the most fitting product. */
function productForAlbum(type: string): string {
  switch (type) {
    case 'people':
      return 'book';
    case 'pet':
      return 'mug';
    default:
      return 'canvas'; // trip / event / best_of / other
  }
}

function heuristicCopy(album: Album, productId: string): { name: string; description: string } {
  const title = album.title as string;
  switch (productId) {
    case 'book':
      return {
        name: `${title} photo book`,
        description: `A hardcover photo book, auto-laid-out from the best moments of "${title}".`,
      };
    case 'mug':
      return {
        name: `${title} mug`,
        description: `A ceramic mug featuring the standout portrait from "${title}".`,
      };
    default:
      return {
        name: `${title} canvas`,
        description: `A gallery-wrap canvas built from the best shots of "${title}".`,
      };
  }
}

/** Claude writes warmer, tailored copy for each album's product. */
async function aiCopy(
  albums: Album[],
  productIds: string[],
): Promise<{ name: string; description: string }[]> {
  const key = Deno.env.get('ANTHROPIC_API_KEY');
  if (!key) throw new Error('no_anthropic_key');

  const items = albums.map((a, i) => ({
    i,
    album_title: a.title,
    album_type: a.type,
    product: productIds[i],
  }));

  const schema = {
    type: 'object',
    properties: {
      products: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            i: { type: 'integer' },
            name: { type: 'string' },
            description: { type: 'string' },
          },
          required: ['i', 'name', 'description'],
          additionalProperties: false,
        },
      },
    },
    required: ['products'],
    additionalProperties: false,
  };

  const prompt =
    `You write warm, premium, concise product copy for MemoryFlow gifts. For each item below, write a ` +
    `short product name and a one-sentence description (premium, effortless tone, no emoji). ` +
    `Items (index, album title, album type, product type):\n${JSON.stringify(items)}`;

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': key, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({
      model: 'claude-opus-4-8',
      max_tokens: 2000,
      output_config: { format: { type: 'json_schema', schema } },
      messages: [{ role: 'user', content: prompt }],
    }),
  });
  if (!res.ok) throw new Error(`claude_${res.status}`);
  const data = await res.json();
  const text = (data.content ?? []).find((b: { type: string }) => b.type === 'text')?.text ?? '{}';
  const parsed = JSON.parse(text);

  const out: { name: string; description: string }[] = albums.map((a, i) => heuristicCopy(a, productIds[i]));
  for (const p of parsed.products ?? []) {
    const idx = p.i as number;
    if (idx >= 0 && idx < out.length) out[idx] = { name: p.name, description: p.description };
  }
  return out;
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
    const requestedMode: string = body.mode ?? 'heuristic';

    const admin: Admin = createClient(SUPABASE_URL, SERVICE_KEY);

    const { data: albums } = await admin
      .from('albums')
      .select('id, title, type, cover_url, photo_count')
      .eq('user_id', userId)
      .order('best_shot_count', { ascending: false })
      .limit(3);

    if (!albums || albums.length === 0) {
      return json({ suggestions: 0, message: 'No albums yet. Organize photos first.' });
    }

    // Idempotent: clear prior suggestions, then rebuild.
    await admin.from('product_suggestions').delete().eq('user_id', userId);

    const productIds = albums.map((a: Album) => productForAlbum(a.type));
    let copy: { name: string; description: string }[];
    let usedMode = requestedMode;
    if (requestedMode === 'ai') {
      try {
        copy = await aiCopy(albums, productIds);
      } catch (_e) {
        copy = albums.map((a: Album, i: number) => heuristicCopy(a, productIds[i]));
        usedMode = 'heuristic_fallback';
      }
    } else {
      copy = albums.map((a: Album, i: number) => heuristicCopy(a, productIds[i]));
    }

    for (let i = 0; i < albums.length; i++) {
      const album = albums[i];
      const productId = productIds[i];
      const cfg = SIZES[productId];
      await admin.from('product_suggestions').insert({
        user_id: userId,
        product_id: productId,
        source_album_id: album.id,
        name: copy[i].name,
        description: copy[i].description,
        tag: cfg.tag,
        hero_url: album.cover_url,
        sizes: cfg.sizes,
        default_size_index: cfg.defaultIndex,
        created_from_photo_count: album.photo_count ?? 0,
        status: 'ready',
      });
    }

    return json({ suggestions: albums.length, mode: usedMode });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
