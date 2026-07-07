# MemoryFlow — Product Requirements (PRD)

## Vision
People's photos are scattered across Google Photos, phones, Gmail and cloud drives. MemoryFlow is an **AI memory concierge**: connect your accounts once, and we automatically organize everything into smart albums, surface your best shots, and turn them into beautiful, personalized physical products — canvases, photo books and gifts — fulfilled by a print-on-demand partner.

**One-liner:** _Your photos, organized into albums, gifts and memories — automatically._

## Target users
- **Busy memory-keepers** (parents, travellers, couples) with thousands of disorganized photos.
- **Gift-givers** who want something personal but have no time to design it.
- Later: **B2B** (photographers, event organizers) via API/white-label.

## Core value props
1. **Effortless organization** — no manual tagging; the AI clusters events/trips/people/pets.
2. **Best-shot curation** — we pick the keepers so you don't scroll through 4,000 photos.
3. **One-tap gifts** — AI-designed products from your best memories; partner prints & ships.
4. **Privacy as the product** — read-only, never deletes originals, GDPR-first, EU residency.

## Monetization
- Affiliate commission on print orders (primary, day 1).
- **€4.99/mo subscription** (unlimited accounts, full AI organization, family sharing, AI restore/enhance).
- **AI credits** for paywalled enhance / restore / background-removal.
- B2B / API (later).

## Primary user journey (the MVP flow — matches the prototype)
1. **Welcome** — brand promise.
2. **Connect** — link Google Photos and/or Gmail (read-only). CTA disabled until ≥1 source.
3. **AI Scanning** — animated: dedupe → detect faces/pets/places → group events → pick best shots → design gifts.
4. **Home** — "4,532 photos → 18 smart albums"; album grid; "gift ideas ready" CTA.
5. **Album Detail** — hero + best-of grid + "Turn this into a gift".
6. **Gifts** — AI-designed product suggestions.
7. **Product** — preview + size selection + live total.
8. **Checkout** — handoff to Gelato (print partner); shipping/payment summary.
9. **Success** — confetti + "created from N photos" **viral share**.
10. **Profile** — plan, premium upsell, connected accounts.

## Success metrics (post-launch)
- Activation: % of new users who connect ≥1 account and reach Home.
- Magic moment: % who open an album within first session.
- Monetization: order conversion, subscription take-rate, AI-credit ARPU.
- Virality: share rate on the success screen, referral signups.

## Non-goals (MVP)
- No in-app photo editing beyond AI enhance/restore credits.
- No social network / feed.
- No native print production (we integrate partners).

## Scope by milestone
See `ROADMAP.md`. **Milestone 1 (this build): the entire flow above, clickable, on mock data.**
