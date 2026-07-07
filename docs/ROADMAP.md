# MemoryFlow — Roadmap

Each milestone ends with a **runnable checkpoint**: what was built, how to run/test it, and what's next. We stop for review before proceeding.

## ✅ Milestone 1 — Runnable clickable app (MOCK data)
- Flutter scaffold, brand theme, `go_router` routes for every screen.
- All prototype screens, responsive/mobile-first, inside a centered phone frame on web.
- `MockRepository` (fake albums, photos via picsum, product suggestions) behind a `Repository` interface.
- Animated AI-scanning screen with progressing counters.
- `/docs` + README with run instructions.
- **Run:** `flutter pub get && flutter run -d chrome`.

## ✅ Milestone 2 — Supabase backend + auth + schema
- Project config (`supabase/config.toml`), `.env.example`, SQL migrations: profiles, connected_accounts, photos (perceptual-hash, quality_score, faces, entities), albums, album_photos, products, product_suggestions, orders, subscriptions, ai_credits (+ ai_credit_ledger).
- **RLS on every user-owned table** + comments on every table. Storage `thumbnails` bucket (owner-scoped). EU-region note. `handle_new_user` trigger bootstraps profile + credits.
- Email + Google sign-in (`SupabaseAuthService`), router auth gate, sign-out.
- `SupabaseRepository` behind the same `Repository` interface; `AppConfig.backendEnabled` feature flag keeps full-mock mode for UI work.
- `flutter analyze` clean · widget test passes · `flutter build web` succeeds.

## 🟡 Milestone 3 — Google Photos + Gmail import (read-only)
- Server-side OAuth scaffold (`google-oauth` function): consent URL + token exchange → `oauth_tokens` (server-only). **Deployed.**
- `import-photos` Edge Function: returns jobId + runs in background; pages the library, stores thumbnail + metadata, computes aHash, dedupes. Rate-limit aware, resumable via cursor. **Deployed.**
  - `mode=sample` (no Google account) fully working + testable today.
  - `mode=google` real path shipped; needs Google OAuth credentials to go live.
- Connect → starts a real import; Scanning reflects **live import progress** from `import_jobs`.
- `flutter analyze` clean · test passes · `flutter build web` succeeds · functions ACTIVE · advisors reviewed.
- _Remaining for full M3: configure Google Cloud OAuth creds (user) + optional Photos Picker API per Google's 2025 changes._

## ✅ Milestone 4 — AI organization pipeline
- `organize-photos` Edge Function **deployed**: clusters photos into events/trips/people/pets, picks best shots, labels albums. Idempotent + re-runnable (clears AI albums, rebuilds).
  - `mode=ai` → **Claude `claude-opus-4-8`** with structured JSON output (server-side, key in env). Auto-falls-back to heuristic if no key.
  - `mode=heuristic` (default) → deterministic clustering, testable today, produces real albums.
- Scanning screen, after import, runs organization; **Home + Album Detail now show real organized albums** from the DB.
- `flutter analyze` clean · test passes · `flutter build web` succeeds · function ACTIVE.
- _Remaining for full M4: set `ANTHROPIC_API_KEY` function secret to switch on real Claude clustering._

## ✅ Milestone 5 — Product suggestions + checkout handoff
- `suggest-products` Edge Function **deployed**: one product (canvas/book/mug) per top album, copy from Claude (`mode=ai`) or templates (`mode=heuristic`, default). Idempotent.
- `create-order` Edge Function **deployed**: `PrintPartner` interface (Gelato impl + Mock fallback) → draft order + price; records the order in `orders`; returns optional hosted-checkout URL.
- Gifts tab shows real suggestions; Product → Checkout → Pay runs the partner handoff; **Success shows "created from N photos"** from the real order.
- Suggestions are generated after organization in the scan flow.
- `flutter analyze` clean · test passes · `flutter build web` succeeds · functions ACTIVE.
- _Remaining for full M5: set `GELATO_API_KEY` + map product UIDs for real fulfillment; `ANTHROPIC_API_KEY` for AI copy._

## ✅ Milestone 6 — Monetization + polish
- `billing` Edge Function **deployed**: €4.99/mo subscribe (Stripe Checkout scaffold + mock activation), AI-credit balance, buy-credits, spend-credit (Premium = unlimited). Credits via ledger.
- Profile: Premium upsell/active, AI-credit balance + Enhance (paywalled) + Buy credits, referral loop, sign-out.
- `analytics_events` table + `logEvent` (order_completed logged). Empty states on Home + Gifts. Loading/error states throughout.
- **Deploy guide** (`docs/DEPLOY.md`): Flutter web hosting + Supabase + secrets checklist.
- `flutter analyze` clean · test passes · `flutter build web` succeeds · function ACTIVE.
- _Remaining for real billing: set `STRIPE_SECRET_KEY` + `STRIPE_PRICE_ID` + webhook._

---

## 🚀 Launch review
All six milestones built. Backend live on a hosted EU Supabase project; every external integration (Google, Claude, Gelato, Stripe) is shipped behind a flag/abstraction and activates with its API key. See `docs/DEPLOY.md` for go-live.

## Cross-cutting (every milestone)
- Privacy-first (see `PRIVACY_GDPR.md`), no client secrets, keep docs in `/docs` updated.
