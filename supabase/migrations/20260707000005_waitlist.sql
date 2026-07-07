-- Public waitlist / early-access email capture (fed by the live demo).
create table waitlist (
  id          uuid primary key default gen_random_uuid(),
  email       text not null unique,
  source      text not null default 'web-demo',
  created_at  timestamptz not null default now(),
  constraint waitlist_email_shape check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);
comment on table waitlist is 'Early-access email signups from the public demo. Anonymous visitors may INSERT only; no client can SELECT (owner reads via dashboard/service role). GDPR: single-purpose list, delete on request.';

alter table waitlist enable row level security;
-- Visitors (anon) and signed-in users may add an email; nobody can read/modify.
create policy "waitlist: public insert" on waitlist
  for insert to anon, authenticated with check (true);
