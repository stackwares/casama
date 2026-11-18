-- Phase 8: privacy (retention, account deletion), first-token timing, opt-in telemetry (D-072..D-075).

-- Run events are kept for a set number of days per workspace (default 180).
alter table public.organizations add column run_event_retention_days integer not null default 180
  check (run_event_retention_days between 7 and 3650);

-- Time to first token per run, for dashboards and the load test (set by the worker).
alter table public.runs add column first_token_at timestamptz;

-- Account deletion: the user is signed out at once; data is purged after the grace period.
create table public.account_deletions (
  user_id uuid primary key,
  requested_at timestamptz not null default now(),
  purge_after timestamptz not null,
  completed_at timestamptz,
  orgs_deleted integer
);
alter table public.account_deletions enable row level security;
-- No policies: only the server reads and writes it.

-- Opt-in anonymous telemetry. Self-hosted side: one random instance id. Cloud side: received pings.
create table public.instance_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.instance_settings enable row level security;

create table public.telemetry_pings (
  id uuid primary key default gen_random_uuid(),
  instance_id uuid not null,
  version text not null,
  weekly_active_bots integer not null,
  weekly_active_users integer not null,
  received_at timestamptz not null default now()
);
create index telemetry_pings_instance_idx on public.telemetry_pings (instance_id, received_at desc);
alter table public.telemetry_pings enable row level security;
