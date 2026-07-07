# MemoryFlow — Architecture

## Stack
- **Frontend:** Flutter (iOS, Android, Web — web is the milestone-checkpoint target). State: **Riverpod**. Navigation: **go_router**.
- **Backend:** Supabase — Postgres, Auth, Storage, Edge Functions (TypeScript/Deno). _(Milestone 2+)_
- **AI:** Anthropic Claude API for image understanding (event/face/best-shot reasoning), product copy, and gift suggestions. **All Claude calls run server-side in Edge Functions.** _(Milestone 4+)_
- **Print fulfillment:** **Gelato** API first, behind a `PrintPartner` abstraction so Printful / Prodigi / Printify can be swapped. _(Milestone 5+)_

## High-level diagram
```
┌────────────────────────┐        ┌──────────────────────────────────────┐
│   Flutter app          │  HTTPS │  Supabase                            │
│  (iOS / Android / Web) │ ─────► │  • Auth (email + Google)             │
│                        │        │  • Postgres (RLS per-user)           │
│  Riverpod + go_router  │ ◄───── │  • Storage (thumbnails)              │
│                        │  data  │  • Edge Functions (Deno/TS):         │
│  Repository interface  │        │     - google import (Photos/Gmail)   │
└─────────┬──────────────┘        │     - ai-organize (Claude)           │
          │ MockRepository (M1)   │     - products/copy (Claude)         │
          │ SupabaseRepository(M2)│     - print-partner (Gelato)         │
          ▼                       └───────────────┬──────────────────────┘
   in-memory fake data                            │ server-side secrets only
                                     ┌─────────────┴───────────────┐
                                     │ Google APIs · Claude · Gelato · Stripe │
                                     └────────────────────────────────────────┘
```

## The Repository seam (key design decision)
The UI depends on **one interface** — `lib/data/repository/repository.dart`. Concrete implementations:
- `MockRepository` — in-memory (Milestone 1).
- `SupabaseRepository` — real data (Milestone 2+).

`repositoryProvider` (Riverpod) chooses based on `AppConfig.useMockData`. **No screen changes when we switch from mock to real data.** This is what makes the milestone plan safe.

## Layering
- **features/** — one folder per screen; widgets only, no business logic beyond view-state.
- **data/** — models, repository contract + implementations, Riverpod providers.
- **core/** — theme, config/feature-flags, router.
- **widgets/** — reusable brand components (buttons, photo tiles, cards, bottom nav, phone frame).

## Security & secrets
- **No third-party API keys in the Flutter client — ever.** Google/Claude/Gelato/Stripe secrets live in Supabase Edge Function env vars.
- Client holds only the Supabase publishable (anon) key, which is safe with RLS.
- OAuth token exchange and refresh happen **server-side** (Milestone 3).

## Why these choices
- **Flutter** → one codebase, fast iteration, great web preview for checkpoints.
- **Supabase** → Postgres + Auth + Storage + serverless functions with EU region option (data residency).
- **Claude server-side** → keeps keys safe, lets us batch image reasoning cost-efficiently.
- **PrintPartner abstraction** → avoids lock-in to a single fulfillment vendor.
