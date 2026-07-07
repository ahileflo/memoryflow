# MemoryFlow — Runbook (how to run & test)

## Prerequisites
- **Flutter SDK** (stable) and **Chrome**. Check with `flutter doctor`.
- Internet connection (placeholder images load from picsum.photos; UI falls back to a gradient if offline).

## Run (Milestone 1)
```bash
flutter pub get
flutter run -d chrome
```
The app opens in Chrome inside a centered phone frame.

Other useful commands:
```bash
flutter analyze            # static analysis (should be clean)
flutter test               # widget tests (smoke test included)
flutter run -d chrome --web-renderer canvaskit   # crisper rendering if needed
flutter build web          # production web build → build/web
```

## Manual test script (click-through)
Walk this happy path and verify each step:

1. **Welcome** → tap **Get started**.
2. **Connect** → CTA is **disabled**. Tap **Google Photos** → it turns mint/checked and the CTA enables ("Continue (1 connected)"). Optionally tap **Gmail** too. The three "SOON" providers are not tappable.
3. Tap **Continue** → **Scanning**: ring sweeps 0→100%, the five steps light up in order, the photo counter climbs, then it **auto-advances to Home**.
4. **Home** → header greeting, "4,532 photos → 18 smart albums", a 2-column album grid, and the coral "3 gift ideas ready" banner.
5. Tap an album (e.g. **Italy 2024**) → **Album Detail**: hero, "Best of this album" 3-col grid, **Turn this into a gift**.
6. Tap **Turn this into a gift** → **Product**: framed preview, three size chips (40×30 pre-selected), live total. Tap a different size → total updates.
7. Tap **Order this gift** → **Checkout**: "handed off to Gelato" banner, item row, shipping, payment, totals. Tap **Pay €…**.
8. **Success**: confetti, "Order placed!", the "created from 4,532 photos" card. Tap **Share** → toast appears. Tap **Back to my memories** → Home.
9. **Bottom tabs**: switch between **Home · Gifts · Profile**. On **Gifts**, open any product. On **Profile**, see plan + premium upsell + connected accounts; tap **Upgrade**/**Connect** → toast.

✅ Pass = every transition works, the scan animation completes and auto-advances, sizes update the price, and the order flow reaches the success screen.

## Troubleshooting
| Symptom | Fix |
|---|---|
| `flutter: command not found` | Flutter SDK not installed / not on PATH. See README → Installing Flutter. |
| Chrome not listed as a device | `flutter config --enable-web`, then `flutter devices`. Ensure Chrome is installed. |
| Images are blank gradients | No internet (picsum unreachable) — expected fallback; the flow still works. |
| Analyzer/runtime errors after editing | `flutter clean && flutter pub get`. |
| Blank white screen on web | Check the browser console; try `--web-renderer canvaskit`. |

## Milestone 2 — running with the real Supabase backend (optional)

The app stays **fully mock by default**, so you can keep doing UI work with no backend. To exercise the real database + auth:

### 1. Start Supabase
You need the **Supabase CLI** + **Docker** (local), or a free hosted project.

**Local:**
```bash
supabase start          # boots Postgres, Auth, Storage in Docker
supabase db reset       # applies supabase/migrations + seeds the product catalog
```
`supabase start` prints your **API URL** and **anon key**.

**Hosted (cloud):** create a project (EU region), then:
```bash
supabase link --project-ref <your-ref>
supabase db push        # applies the migrations to the cloud project
```
Grab the URL + anon key from the project's API settings.

### 2. Run the app against it
```bash
flutter run -d chrome \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```
(See `.env.example` for the full list of variables.)

### 3. What you'll see
- The app now opens on a **Sign in / Sign up** screen (email or Google).
- Create an account → a `profiles` row + zero `ai_credits` are created automatically by the `handle_new_user` trigger.
- You land on the normal flow, but **Albums/Gifts are empty** — real data is populated by import (Milestone 3) and AI organization (Milestone 4). This is expected.
- **Profile → Sign out** ends the session and returns you to sign-in.

> **Google sign-in** also needs a Google OAuth client configured in Supabase Auth (`SUPABASE_AUTH_GOOGLE_CLIENT_ID` / `_SECRET`). Email sign-in works out of the box locally (email confirmation is disabled in `config.toml` for dev).

### Verifying RLS
In Supabase Studio (`http://localhost:54323`), open the SQL editor and confirm every user table has policies, or create two accounts and verify neither can see the other's rows.

## Milestone 3 — testing the read-only import (backend mode)

The import pipeline is **deployed and live** on the hosted project. To test it end-to-end:

1. Run in backend mode (`run_backend.ps1`, or the `--dart-define` command above) and **sign in**.
2. On **Connect**, tap a source (e.g. Google Photos) → **Continue**. In backend mode this calls the `import-photos` Edge Function in **sample** mode.
3. The **Scanning** screen now shows **real, live progress** — the ring + counter reflect rows landing in your `photos` table ("Imported X of Y photos · N duplicates skipped"). The intentional duplicates prove the perceptual-hash dedupe.
4. When it finishes you land on **Home**, which shows your real photo count (albums are still 0 — AI clustering is Milestone 4).
5. Verify in Supabase: **[Table editor → `photos`](https://supabase.com/dashboard/project/arvtedmfvulxkuabduqq/editor)** (rows exist, each with a `perceptual_hash`), and **`import_jobs`** (one `done` row with `processed`/`duplicates`). `oauth_tokens` is empty (no Google yet) and is server-only by design.

> The real Google Photos/Gmail path is shipped behind the same function (`mode=google`) but needs Google OAuth credentials configured — see `docs/API_INTEGRATIONS.md`.

## Milestone 4 — testing AI organization (backend mode)

The organization pipeline is **deployed and live**. It runs automatically right after import:

1. In backend mode, **Connect → Continue** runs the import, then the scanning screen shows **"Organizing your memories…"** while `organize-photos` clusters your photos.
2. You land on **Home** with **real smart albums** (e.g. "Best of your library", "Everyday moments", "People & places") built from your imported photos. Open one → **Album Detail** shows the AI-picked best shots.
3. Verify in Supabase: **[`albums`](https://supabase.com/dashboard/project/arvtedmfvulxkuabduqq/editor)** (rows with `ai_generated = true`), `album_photos` (membership + `is_best_shot`), and `photos.is_best_shot` flags.

By default it uses **heuristic** clustering (no Anthropic key). To switch on **real Claude** clustering:
- Supabase Dashboard → **Edge Functions → `organize-photos` → Secrets** → add `ANTHROPIC_API_KEY` (from console.anthropic.com).
- Change the scanning call from `organize(mode: 'heuristic')` to `mode: 'ai'` (in `lib/features/scanning/scanning_screen.dart`), or add a "Re-organize with AI" action. The function auto-falls-back to heuristic if the key is missing.

> Re-running organization is **idempotent** — it clears the prior AI albums and rebuilds, so you won't get duplicates.

## Milestone 5 — testing gift suggestions + checkout (backend mode)

Suggestions + the print-partner checkout are **deployed and live**. After import + organization (the scan flow), suggestions are generated automatically.

1. In backend mode, run the full flow (Connect → Continue). After "Organizing…", open the **Gifts** tab — you'll see **real AI suggestions** (a canvas/book/mug per top album, with generated copy).
2. Tap one → **Product** (framed preview, sizes, live total) → **Order this gift** → **Checkout** (Gelato handoff banner) → **Pay**.
3. `create-order` creates the order via the **PrintPartner** (MockPartner by default), records it in `orders`, and you land on **Success** with the **"created from N photos"** share.
4. Verify in Supabase: **[`product_suggestions`](https://supabase.com/dashboard/project/arvtedmfvulxkuabduqq/editor)** (rows per album) and **`orders`** (a `created` row with `partner` + `partner_order_id`).

**Real integrations (optional):**
- **AI copy:** set `ANTHROPIC_API_KEY` on `suggest-products` and call with `mode:'ai'`.
- **Real Gelato:** set `GELATO_API_KEY` on `create-order`. The `GelatoPartner` is scaffolded — going fully live needs Gelato product-UID mapping + print-file upload (documented inline in `supabase/functions/create-order/index.ts`).

## Milestone 6 — testing monetization (mock + backend)

Subscription + AI credits are **deployed and live** (mock-activated without Stripe).

1. Open **Profile**. You'll see the **Go Premium €4.99/mo** card, an **AI tools** card with your credit balance, and a **referral** card.
2. Tap **Upgrade** → (mock) you're flipped to **Premium** + granted 50 credits; the plan chip turns mint. (Backend mode persists this to `profiles.plan` + `subscriptions`.)
3. Tap **🪄 Enhance (1)** → as Premium it's unlimited; as Free it spends a credit (or prompts you to buy/upgrade when you hit 0). **Buy 50** tops up credits.
4. Backend verify: **[Supabase → `subscriptions` / `ai_credits` / `ai_credit_ledger`](https://supabase.com/dashboard/project/arvtedmfvulxkuabduqq/editor)**, and `analytics_events` (an `order_completed` row appears after checkout).
5. **Empty states**: a brand-new account (before import) shows friendly empty cards on Home + Gifts.

This all works in **mock mode** too (`flutter run -d chrome`) — the upgrade/credits flow is simulated in memory.

**Real Stripe:** set `STRIPE_SECRET_KEY` + `STRIPE_PRICE_ID` on the `billing` function; `subscribe` then returns a Stripe Checkout URL instead of mock-activating. See `docs/DEPLOY.md`.

## Switching data sources quickly
```bash
flutter run -d chrome                              # mock (default)
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
If `USE_MOCK_DATA=false` but no Supabase URL/key is provided, the app safely falls back to mock (`AppConfig.backendEnabled` is false).
