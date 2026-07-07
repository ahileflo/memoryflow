# MemoryFlow — Privacy & GDPR

> **Privacy is the product.** We handle people's personal photos. These principles are non-negotiable and are designed into the architecture and schema from day one.

## Core principles
1. **Read-only.** We request **read-only** scopes (Google Photos `readonly`, Gmail `readonly`). We **never delete or move originals.**
2. **We store metadata + thumbnails only** — never the user's original full-resolution files.
3. **Explicit consent.** Clear consent at connect time, stating exactly what we read and why.
4. **Per-account revoke.** Users can disconnect any source at any time; tokens are revoked server-side.
5. **Data export.** Users can export their data (profile + metadata + thumbnails).
6. **Delete account.** A full delete cascades across all user-owned rows, Storage objects, and revokes OAuth tokens.
7. **EU data residency.** Supabase project provisioned in an **EU region**; documented in schema comments.
8. **No secrets in the client.** All third-party keys live server-side (Edge Function env vars). OAuth token exchange/refresh is server-side only.

## How the architecture enforces this
- **RLS everywhere:** every user-owned table is protected by `user_id = auth.uid()` — users can only ever read/write their own rows. _(Milestone 2.)_
- **Server-side OAuth:** access/refresh tokens never reach the Flutter client. _(Milestone 3.)_
- **Thumbnails not originals:** the import function stores a downsized thumbnail + metadata; the original stays in the user's account. _(Milestone 3.)_
- **Idempotent processing:** re-running AI organization doesn't duplicate or mutate source data. _(Milestone 4.)_

## Consent surfaces (UI)
- **Connect screen:** "We never delete or move your originals — we only read them to organize," plus "🔒 GDPR-compliant · revoke access anytime." _(Implemented in Milestone 1 UI.)_
- **Profile → Connected accounts:** per-account status + revoke. _(UI in M1; live revoke in M3.)_

## Planned GDPR flows (Milestone 2/6)
- **Right to access / portability:** one-click export endpoint.
- **Right to erasure:** delete-account flow (cascade + Storage purge + token revoke), with confirmation.
- **Data minimization:** only store fields needed for organization and fulfillment.
- **Records of processing & sub-processors:** Supabase (hosting/DB), Google (source, read-only), Anthropic (image understanding), Gelato (fulfillment), Stripe (payments). To be listed in a public privacy policy before launch.

## Pre-launch checklist
- [ ] Privacy policy + sub-processor list published.
- [ ] Google OAuth verification review passed for sensitive scopes.
- [ ] EU region confirmed for Supabase project + Storage.
- [ ] Export + delete-account flows implemented and tested.
- [ ] DPA in place with each sub-processor.
