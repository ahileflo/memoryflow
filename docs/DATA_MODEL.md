# MemoryFlow — Data Model

> Milestone 1 uses in-memory Dart models only (no database). This document records (a) the current client models and (b) the **planned Supabase schema** to be implemented with migrations + RLS in Milestone 2. EU data residency: provision the Supabase project in an **EU region**; store only thumbnails + metadata, never originals.

## Client models (Milestone 1) — `lib/data/models/`
| Model | Key fields |
|---|---|
| `Photo` | id, url (thumbnail), qualityScore, isBestShot |
| `Album` | id, title, badge, photoCount, bestShotCount, coverUrl, heroUrl, bestShots[] |
| `ProductSize` | label, price (EUR) |
| `ProductSuggestion` | id, type (canvas/book/mug), name, description, tag, heroUrl, sizes[], defaultSizeIndex, sourceAlbumId, createdFromPhotoCount |
| `ConnectedAccount` | id, name, subtitle, emoji, brandColor, comingSoon, connected |
| `UserProfile` | name, email, planLabel, isPremium, totalPhotos, albumCount |
| `OrderDraft` / `OrderConfirmation` | product, size, shipping, total / orderId, createdFromPhotoCount |

## ✅ Postgres schema (Milestone 2 — implemented in `supabase/migrations/20260609000001_init.sql`)
All user-owned tables carry `user_id uuid references auth.users` and are protected by **RLS** (`user_id = auth.uid()`), so users see only their own rows. Every table has a SQL comment. `handle_new_user()` bootstraps a profile + zero credit balance on signup; `set_updated_at()` keeps timestamps fresh.

- **profiles** — 1:1 with `auth.users`. display_name, plan, created_at. _(EU residency note in comment.)_
- **connected_accounts** — provider (`google_photos`|`gmail`|…), status, scopes, oauth token refs (server-only), `revoked_at`. Supports **per-account revoke**.
- **photos** — source_account_id, storage_path (thumbnail), `perceptual_hash` (for dedupe), `quality_score`, `faces jsonb`, `entities jsonb` (pets/places), taken_at, exif jsonb. _Originals are never copied — we store metadata + thumbnail only._
- **albums** — title, type (trip/event/people/pet/best-of), cover_photo_id, ai_generated bool, `signature` (idempotency key for re-runs).
- **album_photos** — (album_id, photo_id), is_best_shot, rank. Join table.
- **products** — catalog of printable product types mapped to print-partner SKUs.
- **product_suggestions** — album_id, product_id, ai_copy, hero_photo_id, created_from_photo_count, status.
- **orders** — product_suggestion_id, size, price, currency, partner (`gelato`), partner_order_id, status, shipping jsonb.
- **subscriptions** — stripe_customer_id, stripe_subscription_id, status, current_period_end.
- **ai_credits** — balance, ledger of grants/spends (enhance/restore/bg-removal).
- **oauth_tokens** _(M3)_ — server-only Google tokens. **RLS enabled with no policies** (deny-all to clients); only the service role touches it. Never returned to the app.
- **import_jobs** _(M3)_ — one row per import run: status, total/processed/duplicates, `cursor` (paging token for resume). Owner-readable (drives the live scan screen); written by the import Edge Function.

## Dedupe & best-shot (Milestones 3–4)
- **Dedupe:** compute a perceptual hash on import; near-duplicate clusters collapsed by Hamming distance.
- **Quality / best-shot:** `quality_score` from blur/exposure heuristics + Claude reasoning; top-N flagged `is_best_shot`.
- **Idempotency:** organization runs keyed by an album `signature` so re-running doesn't duplicate albums.

## GDPR data flows
- **Export:** per-user dump of profiles + metadata + thumbnails.
- **Delete account:** cascade delete of all user-owned rows + Storage objects + token revocation.
- See `PRIVACY_GDPR.md`.
