-- Milestone 3 — read-only import support.

create type import_status as enum ('queued','running','done','error');

-- SERVER-ONLY OAuth token store. RLS enabled with NO policies, so neither anon
-- nor authenticated can read it — only the service role (Edge Functions) can.
create table oauth_tokens (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  provider      account_provider not null,
  access_token  text,
  refresh_token text,
  token_type    text,
  scopes        text[] not null default '{}',
  expires_at    timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, provider)
);
comment on table oauth_tokens is 'SERVER-ONLY OAuth tokens for connected photo sources. RLS on with NO policies: never readable by anon/authenticated; only the service role (Edge Functions) touches it. Tokens are never returned to the Flutter client.';
alter table oauth_tokens enable row level security;
create trigger oauth_tokens_set_updated_at before update on oauth_tokens for each row execute function set_updated_at();

-- Tracks an import run for resumability + live progress (drives the scan screen).
create table import_jobs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  provider    account_provider,
  mode        text not null default 'sample',
  status      import_status not null default 'queued',
  total       integer not null default 0,
  processed   integer not null default 0,
  duplicates  integer not null default 0,
  message     text,
  cursor      jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
comment on table import_jobs is 'One row per import run. Owner can read (live progress for the scanning screen); writes are by the import Edge Function via the service role. cursor stores the Google paging token so an interrupted import can resume.';
create index import_jobs_user_idx on import_jobs (user_id);
alter table import_jobs enable row level security;
create policy "import_jobs: select own" on import_jobs for select using (user_id = auth.uid());
create trigger import_jobs_set_updated_at before update on import_jobs for each row execute function set_updated_at();
