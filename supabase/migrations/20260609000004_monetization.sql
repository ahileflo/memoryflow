-- Milestone 6 — monetization + analytics.

-- Referral code for the viral loop.
alter table profiles add column if not exists referral_code text unique;

-- Lightweight first-party analytics (owner-scoped).
create table analytics_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users (id) on delete cascade,
  event       text not null,
  props       jsonb not null default '{}',
  created_at  timestamptz not null default now()
);
comment on table analytics_events is 'First-party product analytics events (screen views, key actions). Owner can insert/read their own; aggregate analysis happens server-side.';
create index analytics_events_user_idx on analytics_events (user_id);
create index analytics_events_event_idx on analytics_events (event);

alter table analytics_events enable row level security;
create policy "analytics: insert own" on analytics_events
  for insert with check (user_id = auth.uid());
create policy "analytics: select own" on analytics_events
  for select using (user_id = auth.uid());
