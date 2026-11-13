-- Server capacity (D-252): the worker samples the host every 5 minutes, the server records each
-- computer start refused for lack of room, and alerts to the instance owner go out at most once per
-- kind per day. Only the server reads and writes these tables.

create table public.capacity_samples (
  at timestamptz primary key default now(),
  mem_total_mb int not null,
  mem_available_mb int not null,
  load1 numeric(8, 2) not null,
  cpus int not null,
  disk_used_pct numeric(5, 2),
  -- Hosted computers running, starting or idle, and the memory they're allowed (their size).
  computers_running int not null,
  computers_mem_mb int not null,
  -- COMPUTER_HOST_MEMORY_GB at the time, in MB; 0 = no budget set.
  budget_mb int not null default 0
);

create table public.capacity_events (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  kind text not null check (kind in ('capacity_full')),
  org_id uuid references public.organizations (id) on delete set null,
  computer_id uuid,
  detail jsonb not null default '{}'::jsonb
);
create index capacity_events_at_idx on public.capacity_events (at desc);

create table public.capacity_alerts (
  kind text not null check (kind in ('early_warning', 'capacity_full', 'low_memory', 'disk')),
  day date not null,
  sent_at timestamptz not null default now(),
  detail jsonb not null default '{}'::jsonb,
  primary key (kind, day)
);

alter table public.capacity_samples enable row level security;
alter table public.capacity_events enable row level security;
alter table public.capacity_alerts enable row level security;
revoke all on public.capacity_samples, public.capacity_events, public.capacity_alerts from anon, authenticated;
