// ============================================================================
// organize-photos — AI organization pipeline (Milestone 4).
//
// Clusters a user's imported photos into smart albums (events/trips/people/
// pets/best-of), picks best shots, and labels each album. Idempotent &
// re-runnable: it clears the user's AI-generated albums first, then rebuilds.
//
//  • mode=ai        — uses the Claude API (claude-opus-4-8, structured JSON
//    output) to reason over photo metadata. Requires ANTHROPIC_API_KEY.
//  • mode=heuristic — deterministic clustering with no external dependency.
//    The default, and the testable path without an Anthropic key.
//
// All Claude calls happen here, server-side. The key never reaches the client.
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
type Photo = any;

interface Cluster {
  title: string;
  type: string;
  badge: string;
  photoIds: string[];
  bestShotIds: string[];
}

const THEMES = [
  { title: 'Best of your library', type: 'best_of', badge: 'Best-of' },
  { title: 'Everyday moments', type: 'event', badge: 'Event' },
  { title: 'People & places', type: 'people', badge: 'People' },
];

/** Deterministic clustering — no external dependency. */
function clusterHeuristic(photos: Photo[]): Cluster[] {
  const sorted = [...photos].sort(
    (a, b) => (b.quality_score ?? 0) - (a.quality_score ?? 0),
  );
  const groupCount = Math.min(THEMES.length, Math.max(1, Math.ceil(sorted.length / 6)));
  const clusters: Cluster[] = [];
  for (let g = 0; g < groupCount; g++) {
    const members = sorted.filter((_, i) => i % groupCount === g);
    if (members.length === 0) continue;
    clusters.push({
      ...THEMES[g],
      photoIds: members.map((p) => p.id),
      bestShotIds: members.slice(0, Math.min(6, members.length)).map((p) => p.id),
    });
  }
  return clusters;
}

/** Claude-powered clustering (claude-opus-4-8, structured JSON output). */
async function clusterWithClaude(photos: Photo[]): Promise<Cluster[]> {
  const key = Deno.env.get('ANTHROPIC_API_KEY');
  if (!key) throw new Error('no_anthropic_key');

  const summary = photos.map((p, i) => ({
    i,
    taken_at: p.taken_at ?? null,
    quality: p.quality_score ?? 0,
  }));

  const schema = {
    type: 'object',
    properties: {
      albums: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            title: { type: 'string' },
            type: { type: 'string', enum: ['trip', 'event', 'people', 'pet', 'best_of', 'other'] },
            badge: { type: 'string' },
            photo_indices: { type: 'array', items: { type: 'integer' } },
            best_shot_indices: { type: 'array', items: { type: 'integer' } },
          },
          required: ['title', 'type', 'badge', 'photo_indices', 'best_shot_indices'],
          additionalProperties: false,
        },
      },
    },
    required: ['albums'],
    additionalProperties: false,
  };

  const prompt =
    `You are MemoryFlow's photo organizer. Cluster these ${photos.length} photos into 2-5 smart albums ` +
    `(events, trips, people, pets, or best-of). For each album: a warm human title, a type, a short badge ` +
    `(e.g. "Trip", "People"), the photo_indices that belong to it, and best_shot_indices (the 3-6 best by quality). ` +
    `Every photo index should appear in exactly one album.\n` +
    `Photos (index, capture time, quality 0-1):\n${JSON.stringify(summary)}`;

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': key,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-opus-4-8',
      max_tokens: 8000,
      output_config: { format: { type: 'json_schema', schema } },
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!res.ok) throw new Error(`claude_${res.status}: ${await res.text()}`);
  const data = await res.json();
  // With output_config.format the first text block is valid JSON.
  const text =
    (data.content ?? []).find((b: { type: string }) => b.type === 'text')?.text ?? '{}';
  const parsed = JSON.parse(text);

  return (parsed.albums ?? []).map((a: Record<string, unknown>) => ({
    title: (a.title as string) ?? 'Album',
    type: (a.type as string) ?? 'other',
    badge: (a.badge as string) ?? '',
    photoIds: ((a.photo_indices as number[]) ?? []).map((i) => photos[i]?.id).filter(Boolean),
    bestShotIds: ((a.best_shot_indices as number[]) ?? []).map((i) => photos[i]?.id).filter(Boolean),
  }));
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

    const { data: photos } = await admin
      .from('photos')
      .select('id, thumbnail_url, quality_score, taken_at')
      .eq('user_id', userId);

    if (!photos || photos.length === 0) {
      return json({ albums: 0, message: 'No photos to organize. Run an import first.' });
    }

    // Idempotent: clear prior AI-generated albums (cascades album_photos).
    await admin.from('albums').delete().eq('user_id', userId).eq('ai_generated', true);

    let clusters: Cluster[];
    let usedMode = requestedMode;
    if (requestedMode === 'ai') {
      try {
        clusters = await clusterWithClaude(photos);
      } catch (_e) {
        // Fall back to heuristic if the Anthropic key is missing or the call fails.
        clusters = clusterHeuristic(photos);
        usedMode = 'heuristic_fallback';
      }
    } else {
      clusters = clusterHeuristic(photos);
    }

    const byId = new Map(photos.map((p: Photo) => [p.id, p]));
    for (const cluster of clusters) {
      if (cluster.photoIds.length === 0) continue;
      const cover = (byId.get(cluster.photoIds[0]) as Photo | undefined)?.thumbnail_url ?? null;
      const bestSet = new Set(cluster.bestShotIds);

      const { data: album } = await admin
        .from('albums')
        .insert({
          user_id: userId,
          title: cluster.title,
          type: cluster.type,
          badge: cluster.badge,
          cover_url: cover,
          hero_url: cover,
          photo_count: cluster.photoIds.length,
          best_shot_count: cluster.bestShotIds.length,
          ai_generated: true,
          signature: `${usedMode}:${cluster.title}`,
        })
        .select('id')
        .single();
      if (!album) continue;

      const rows = cluster.photoIds.map((pid, rank) => ({
        user_id: userId,
        album_id: album.id,
        photo_id: pid,
        is_best_shot: bestSet.has(pid),
        rank,
      }));
      await admin.from('album_photos').insert(rows);

      // Reflect best-shot flags on the photos themselves.
      if (cluster.bestShotIds.length > 0) {
        await admin.from('photos').update({ is_best_shot: true }).in('id', cluster.bestShotIds);
      }
    }

    return json({ albums: clusters.length, mode: usedMode });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
