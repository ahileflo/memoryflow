# MemoryFlow — Deploy Guide

How to take MemoryFlow from local to a live deployment. The app is **Flutter web + Supabase** (Postgres, Auth, Storage, Edge Functions).

---

## 0. Prerequisites
- Flutter SDK (stable), a Supabase project (EU region for residency), and the Supabase CLI for migrations/functions (or use the dashboard).
- This repo's `supabase/migrations/` + `supabase/functions/` define the whole backend.

## 1. Provision the backend (Supabase)
```bash
supabase link --project-ref <your-ref>
supabase db push                      # applies all migrations
supabase functions deploy             # deploys all Edge Functions
```
Or apply via the dashboard SQL editor + Functions UI. Migrations included:
`init`, `harden_functions`, `import`, `monetization`. Functions: `import-photos`,
`google-oauth`, `organize-photos`, `suggest-products`, `create-order`, `billing`.

> Run `get_advisors` (or the dashboard Advisors tab) after deploy and resolve any
> security findings. Enable **leaked-password protection** in Auth settings.

## 2. Configure secrets (server-side only — never in the client)
Set as **Edge Function secrets** (Dashboard → Edge Functions → Secrets, or `supabase secrets set`):

| Secret | Used by | Needed for |
|---|---|---|
| `ANTHROPIC_API_KEY` | organize-photos, suggest-products | real Claude organization + copy (M4/M5) |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | google-oauth, import-photos | real Google Photos/Gmail import (M3) |
| `OAUTH_REDIRECT_URL` / `APP_REDIRECT_URL` | google-oauth | OAuth redirect targets (M3) |
| `GELATO_API_KEY` | create-order | real print fulfillment (M5) |
| `STRIPE_SECRET_KEY` / `STRIPE_PRICE_ID` | billing | real €4.99/mo subscription (M6) |
| `STRIPE_WEBHOOK_SECRET` | (webhook) | confirm subscription activation (M6) |

Auth providers (email/Google) are configured in **Auth → Providers**. Add your
deployed origin to **Auth → URL Configuration** (Site URL + redirect URLs).

## 3. Build + host the Flutter web app
```bash
flutter build web --release \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```
Deploy the `build/web` folder to any static host:
- **Cloudflare Pages / Netlify / Vercel** — point at `build/web` (or set the build
  command above). Add a SPA fallback so deep links route to `index.html`.
- **Firebase Hosting** — `firebase init hosting` (public dir = `build/web`), `firebase deploy`.
- **Supabase Storage / CDN** — upload `build/web` to a public bucket.

> The **anon/publishable key is safe in the client** (RLS protects the data). The
> service-role key and all third-party secrets stay server-side.

## 4. Custom domain + HTTPS
Add your domain at the host (Pages/Netlify/etc.), point DNS, and let it issue TLS.
Update `APP_REDIRECT_URL` + Supabase Auth URLs to the production origin.

## 5. Pre-launch checklist
- [ ] Migrations applied; advisors clean; leaked-password protection on.
- [ ] All required secrets set; verified each real integration end-to-end.
- [ ] Google OAuth **verification review** submitted for the sensitive Photos/Gmail scopes.
- [ ] Privacy policy + sub-processor list published (see `PRIVACY_GDPR.md`); data-export + delete-account flows live.
- [ ] EU region confirmed for project + Storage.
- [ ] Free-tier limits + Stripe price verified; refunds/cancellation tested.
- [ ] Analytics events flowing; error/empty/loading states reviewed on web + mobile widths.

## Environments
Use a **separate Supabase project per environment** (dev/staging/prod), each with its
own URL + keys passed via `--dart-define`. Keep mock mode (`USE_MOCK_DATA=true`) for
fast UI iteration with no backend.
