-- ============================================================================
-- MemoryFlow — initial schema (Milestone 2)
--
-- Privacy & residency: provision this project in an EU region (e.g. eu-central-1).
-- We store ONLY photo metadata + thumbnails, never originals. Every user-owned
-- table is protected by Row Level Security so a user can only ever read/write
-- their own rows. Server-only writes (subscriptions, ai_credits, orders status)
-- are performed with the service-role key, which bypasses RLS.
-- ============================================================================

-- gen_random_uuid() is provided by pgcrypto (bundled with Supabase).
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type account_provider as enum ('google_photos', 'gmail', 'icloud', 'dropbox', 'facebook');
create type account_status   as enum ('connected', 'revoked', 'error');
create type album_type       as enum ('trip', 'event', 'people', 'pet', 'best_of', 'other');
create type product_type     as enum ('canvas', 'book', 'mug', 'other');
create type suggestion_status as enum ('draft', 'ready', 'ordered', 'dismissed');
create type order_status      as enum ('created', 'submitted', 'in_production', 'shipped', 'delivered', 'cancelled');
create type plan_tier         as enum ('free', 'premium');
create type subscription_status as enum ('active', 'trialing', 'past_due', 'canceled', 'incomplete');

-- ---------------------------------------------------------------------------
-- Shared trigger: keep updated_at fresh
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ===========================================================================
-- profiles — 1:1 with auth.users. Created automatically on signup.
-- ===========================================================================
create table profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text,
  display_name  text,
  plan          plan_tier not null default 'free',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
comment on table profiles is 'User profile, 1:1 with auth.users. EU-resident. Created via handle_new_user() trigger on signup.';
comment on column profiles.plan is 'free | premium — drives free-tier limits and the upsell.';

create trigger profiles_set_updated_at before update on profiles
  for each row execute function set_updated_at();

-- ===========================================================================
-- connected_accounts — linked photo sources (read-only). OAuth tokens are NOT
-- stored here in the client-visible columns; refresh/access tokens live in a
-- server-only secure store and are never returned to the Flutter client.
-- ===========================================================================
create table connected_accounts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  provider      account_provider not null,
  status        account_status not null default 'connected',
  external_account_label text,                       -- e.g. masked email
  scopes        text[] not null default '{}',        -- read-only scopes granted
  connected_at  timestamptz not null default now(),
  revoked_at    timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, provider)
);
comment on table connected_accounts is 'Photo sources a user has linked (read-only). Per-account revoke supported via revoked_at + status. OAuth tokens are stored server-side only, never here.';

create index connected_accounts_user_idx on connected_accounts (user_id);
create trigger connected_accounts_set_updated_at before update on connected_accounts
  for each row execute function set_updated_at();

-- ===========================================================================
-- photos — metadata + thumbnail only. Originals are never copied.
-- ===========================================================================
create table photos (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  source_account_id uuid references connected_accounts (id) on delete set null,
  external_id     text,                              -- id in the source system
  storage_path    text,                              -- thumbnail path in Storage
  thumbnail_url   text,                              -- cached signed/public thumb URL
  perceptual_hash text,                              -- pHash for near-duplicate dedupe
  quality_score   real not null default 0,           -- 0..1 best-shot score (AI)
  is_best_shot    boolean not null default false,
  faces           jsonb not null default '[]',       -- detected faces (AI)
  entities        jsonb not null default '[]',       -- pets/places/objects (AI)
  taken_at        timestamptz,
  exif            jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  unique (user_id, source_account_id, external_id)
);
comment on table photos is 'Per-user photo metadata + thumbnail reference. Originals are never stored. perceptual_hash powers dedupe; quality_score/faces/entities are filled by the AI pipeline (Milestone 4).';
comment on column photos.storage_path is 'Path to the downsized thumbnail in the private "thumbnails" Storage bucket. Original full-res files are never uploaded.';

create index photos_user_idx on photos (user_id);
create index photos_phash_idx on photos (user_id, perceptual_hash);
create index photos_best_idx on photos (user_id, is_best_shot);

-- ===========================================================================
-- albums — AI-generated clusters (trips/events/people/pets).
-- ===========================================================================
create table albums (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  title            text not null,
  type             album_type not null default 'other',
  badge            text,                             -- short display label
  cover_url        text,
  hero_url         text,
  photo_count      integer not null default 0,
  best_shot_count  integer not null default 0,
  ai_generated     boolean not null default true,
  signature        text,                             -- idempotency key for re-runs
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (user_id, signature)
);
comment on table albums is 'Smart albums produced by the AI organization pipeline. signature makes re-running idempotent (no duplicate albums).';

create index albums_user_idx on albums (user_id);
create trigger albums_set_updated_at before update on albums
  for each row execute function set_updated_at();

-- ===========================================================================
-- album_photos — membership join (carries user_id for simple RLS).
-- ===========================================================================
create table album_photos (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  album_id      uuid not null references albums (id) on delete cascade,
  photo_id      uuid not null references photos (id) on delete cascade,
  is_best_shot  boolean not null default false,
  rank          integer not null default 0,
  unique (album_id, photo_id)
);
comment on table album_photos is 'Which photos belong to which album, with best-shot flag + ordering rank. user_id duplicated for direct RLS.';

create index album_photos_album_idx on album_photos (album_id);
create index album_photos_user_idx on album_photos (user_id);

-- ===========================================================================
-- products — GLOBAL catalog of printable product types (not user-owned).
-- ===========================================================================
create table products (
  id           text primary key,                     -- 'canvas' | 'book' | 'mug'
  type         product_type not null,
  name         text not null,
  description  text,
  tag          text,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);
comment on table products is 'Global catalog of printable products, mapped to print-partner SKUs (Milestone 5). Readable by all authenticated users; only writable server-side.';

-- ===========================================================================
-- product_suggestions — AI-designed gift ideas built from a user's album.
-- ===========================================================================
create table product_suggestions (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users (id) on delete cascade,
  product_id            text not null references products (id),
  source_album_id       uuid references albums (id) on delete set null,
  name                  text not null,
  description           text,
  tag                   text,
  hero_url              text,
  sizes                 jsonb not null default '[]', -- [{label, price}]
  default_size_index    integer not null default 0,
  created_from_photo_count integer not null default 0,
  status                suggestion_status not null default 'ready',
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
comment on table product_suggestions is 'Per-user AI-designed gift suggestions (copy + layout) generated from a top album. sizes is a JSON array of {label, price}.';

create index product_suggestions_user_idx on product_suggestions (user_id);
create trigger product_suggestions_set_updated_at before update on product_suggestions
  for each row execute function set_updated_at();

-- ===========================================================================
-- orders — recorded when a user checks out (handed off to the print partner).
-- ===========================================================================
create table orders (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references auth.users (id) on delete cascade,
  product_suggestion_id  uuid references product_suggestions (id) on delete set null,
  product_id             text references products (id),
  size_label             text not null,
  item_price             numeric(10,2) not null,
  shipping               numeric(10,2) not null default 0,
  total                  numeric(10,2) not null,
  currency               text not null default 'EUR',
  partner                text not null default 'gelato',
  partner_order_id       text,
  status                 order_status not null default 'created',
  shipping_address       jsonb,
  created_from_photo_count integer not null default 0,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
comment on table orders is 'Customer orders. Created at checkout, then fulfilled via the print partner (Gelato). Status transitions are updated server-side from partner webhooks.';

create index orders_user_idx on orders (user_id);
create trigger orders_set_updated_at before update on orders
  for each row execute function set_updated_at();

-- ===========================================================================
-- subscriptions — €4.99/mo plan (Stripe). Written server-side via webhooks.
-- ===========================================================================
create table subscriptions (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references auth.users (id) on delete cascade,
  stripe_customer_id     text,
  stripe_subscription_id text,
  status                 subscription_status not null default 'active',
  current_period_end     timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  unique (user_id)
);
comment on table subscriptions is 'Stripe subscription state (Milestone 6). Client may read its own row; all writes happen server-side via the service role from Stripe webhooks.';

create trigger subscriptions_set_updated_at before update on subscriptions
  for each row execute function set_updated_at();

-- ===========================================================================
-- ai_credits — paywalled enhance/restore/bg-removal balance.
-- ===========================================================================
create table ai_credits (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  balance     integer not null default 0,
  updated_at  timestamptz not null default now()
);
comment on table ai_credits is 'Per-user AI credit balance. Client reads own balance; grants/spends are written server-side (see ai_credit_ledger).';

create trigger ai_credits_set_updated_at before update on ai_credits
  for each row execute function set_updated_at();

create table ai_credit_ledger (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  delta       integer not null,                      -- + grant / - spend
  reason      text not null,                         -- 'purchase' | 'enhance' | ...
  created_at  timestamptz not null default now()
);
comment on table ai_credit_ledger is 'Append-only ledger of AI credit grants and spends. Written server-side only.';
create index ai_credit_ledger_user_idx on ai_credit_ledger (user_id);

-- ===========================================================================
-- New-user bootstrap: create a profile + zero credit balance on signup.
-- ===========================================================================
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;

  insert into public.ai_credits (user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ===========================================================================
-- Row Level Security
-- ===========================================================================
alter table profiles            enable row level security;
alter table connected_accounts  enable row level security;
alter table photos              enable row level security;
alter table albums              enable row level security;
alter table album_photos        enable row level security;
alter table products            enable row level security;
alter table product_suggestions enable row level security;
alter table orders              enable row level security;
alter table subscriptions       enable row level security;
alter table ai_credits          enable row level security;
alter table ai_credit_ledger    enable row level security;

-- profiles: read/update own row (insert handled by trigger).
create policy "profiles: select own" on profiles
  for select using (id = auth.uid());
create policy "profiles: update own" on profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Helper macro pattern: owner can do everything to their own rows.
create policy "connected_accounts: all own" on connected_accounts
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "photos: all own" on photos
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "albums: all own" on albums
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "album_photos: all own" on album_photos
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "product_suggestions: all own" on product_suggestions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "orders: all own" on orders
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- products: any authenticated user may read the active catalog; no client writes.
create policy "products: read active" on products
  for select to authenticated using (active);

-- subscriptions / ai_credits / ledger: read-only for the owner; writes are
-- server-side (service role bypasses RLS).
create policy "subscriptions: select own" on subscriptions
  for select using (user_id = auth.uid());
create policy "ai_credits: select own" on ai_credits
  for select using (user_id = auth.uid());
create policy "ai_credit_ledger: select own" on ai_credit_ledger
  for select using (user_id = auth.uid());

-- ===========================================================================
-- Storage: private bucket for thumbnails, owner-scoped access.
-- Files are stored under "<user_id>/...". Originals are never uploaded here.
-- ===========================================================================
insert into storage.buckets (id, name, public)
values ('thumbnails', 'thumbnails', false)
on conflict (id) do nothing;

create policy "thumbnails: owner read" on storage.objects
  for select using (bucket_id = 'thumbnails' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "thumbnails: owner write" on storage.objects
  for insert with check (bucket_id = 'thumbnails' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "thumbnails: owner modify" on storage.objects
  for update using (bucket_id = 'thumbnails' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "thumbnails: owner delete" on storage.objects
  for delete using (bucket_id = 'thumbnails' and (storage.foldername(name))[1] = auth.uid()::text);

-- ===========================================================================
-- Seed: global product catalog (canvas / book / mug).
-- ===========================================================================
insert into products (id, type, name, description, tag) values
  ('canvas', 'canvas', 'Wall canvas', 'Gallery-wrap canvas printed from your best shots.', 'Wall canvas'),
  ('book',   'book',   'Photo book',  'Hardcover photo book, auto-laid-out.',               'Photo book'),
  ('mug',    'mug',    'Photo mug',   'Ceramic mug featuring your best portrait.',          'Gift')
on conflict (id) do nothing;
