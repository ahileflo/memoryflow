# MemoryFlow

> AI memory concierge + personalized gift marketplace.
> Connect your photo accounts → we organize them into smart albums → we turn the best memories into canvases, photo books and gifts.

**This repository is at Milestone 1: a fully clickable Flutter app running on 100% in-memory mock data.** No Supabase, no OAuth, no API keys required. You can click the entire flow end-to-end, exactly like the approved HTML prototype.

---

## Quick start

You need the **Flutter SDK** and **Chrome**. (Git and VS Code are handy but optional.)

```bash
flutter pub get
flutter run -d chrome
```

Then click through:

**Welcome → Get started → connect Google Photos (+ Gmail) → Continue → watch the AI scan → Home → open an album → "Turn this into a gift" → choose a size → Order → Checkout → Pay → Order placed 🎉 → Share. Use the bottom tabs (Home · Gifts · Profile) to jump around.**

> **First time on this machine?** If `flutter` is "not recognized", you don't have the SDK installed yet. See **[Installing Flutter](#installing-flutter-windows)** below.

---

## What's in Milestone 1

| Area | Delivered |
|---|---|
| **Screens** | Welcome, Connect, AI Scanning (animated), Home, Album Detail, Gifts (suggestions), Product/customize, Checkout (Gelato handoff), Order Success (confetti + viral share), Profile |
| **Navigation** | `go_router` with a persistent bottom tab bar (`StatefulShellRoute`) for Home/Gifts/Profile and full-screen routes for the flow |
| **State** | `Riverpod` providers over a single `Repository` interface |
| **Data** | `MockRepository` — fake albums, photos (picsum placeholders) and product suggestions, mirroring the prototype's data |
| **Theme** | Brand colors, type scale, "photo tile" motif, soft shadows — all in `lib/core/theme.dart` |
| **Scan animation** | Custom-painted progress ring, five staged steps lighting up, live photo counter, auto-advance |
| **Responsive** | Mobile-first; on web/desktop the app renders inside a centered phone frame (like the prototype preview) |

### The one thing to know about architecture
Every screen talks to a single **`Repository`** interface (`lib/data/repository/repository.dart`). Milestone 1 wires up `MockRepository`. Milestone 2 adds `SupabaseRepository` behind the *same* interface, chosen by a feature flag — so the UI never changes when we go from fake data to real data.

Flip data sources at build time:
```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false   # (real backend — Milestone 2+)
```

---

## Project layout

```
lib/
  main.dart                  app bootstrap (ProviderScope)
  app.dart                   MaterialApp.router + theme + phone frame
  core/
    theme.dart               brand colors, radii, shadows, ThemeData
    config.dart              feature flags (useMockData) + demo constants
    router.dart              go_router routes (incl. tab shell)
  data/
    models/                  Album, Photo, ProductSuggestion, Order, ...
    repository/
      repository.dart        the single data contract
      mock_repository.dart   in-memory implementation (Milestone 1)
    providers.dart           Riverpod providers
  features/
    welcome/ connect/ scanning/ home/ album/
    suggestions/ product/ checkout/ success/ profile/ shell/
  widgets/                   reusable brand widgets (buttons, tiles, cards, nav)
web/                         web entry (index.html, manifest)
docs/                        PRD, ARCHITECTURE, DATA_MODEL, API_INTEGRATIONS, ROADMAP, RUNBOOK, PRIVACY_GDPR
```

---

## Installing Flutter (Windows)

You already have Git, so the cleanest path:

```powershell
git clone --depth 1 -b stable https://github.com/flutter/flutter.git C:\src\flutter
# add to PATH (user-level), then restart your terminal:
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\src\flutter\bin", "User")
flutter config --enable-web
flutter doctor
```

- For **web** (our checkpoint target) you only need Chrome — which you have.
- `flutter doctor` will warn about "Android toolchain" and "Visual Studio". **Ignore those** for web; they're only for phone/desktop builds.

---

## Notes

- **Images** are random placeholders from `picsum.photos`, so they need an internet connection to display (the UI falls back to a brand gradient if offline). Everything else is local.
- **No secrets** live in this app, by design. From Milestone 2 onward, all third-party keys live in Supabase Edge Function env vars — never in the Flutter client.
- See **`docs/RUNBOOK.md`** for testing the flow and troubleshooting.

---

## Roadmap (high level)

1. ✅ **M1 — Clickable app, mock data**
2. ✅ **M2 — Supabase backend + auth + schema** (RLS, migrations, email/Google auth)
3. 🟡 **M3 — read-only import** (Edge Functions deployed; sample import testable now, real Google needs OAuth creds)
4. 🟡 **M4 — AI organization pipeline** (`organize-photos` deployed; heuristic clustering testable now, real Claude needs an Anthropic key)
5. 🟡 **M5 — Product suggestions + Gelato checkout** (`suggest-products` + `create-order` deployed; mock partner testable now, real Gelato needs an API key)
6. 🟡 **M6 — Monetization + polish** (`billing` deployed; subscription/credits/referral/analytics/empty-states + `docs/DEPLOY.md`; real Stripe needs keys) — **all milestones built**

Full detail in `docs/ROADMAP.md`.
