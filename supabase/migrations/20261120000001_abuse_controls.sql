-- Casama Cloud abuse controls (SPEC: Phase 8 launch items; D-094).

-- A suspended workspace keeps its data, but its bots don't run and its computers don't start.
alter table public.organizations add column suspended_at timestamptz;
alter table public.organizations add column suspended_reason text
  check (suspended_reason is null or char_length(suspended_reason) <= 500);

-- What the egress proxy, the sign-up gate and the owner console saw or did. Service role only
-- (RLS on, no policies): instance owners read it through the admin API.
create table public.abuse_events (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.organizations (id) on delete cascade,
  computer_id uuid references public.computers (id) on delete set null,
  kind text not null check (kind in ('mining_pool', 'blocked_port', 'egress_flood', 'signup_blocked',
                                     'suspended', 'unsuspended')),
  detail jsonb not null default '{}'::jsonb,
  -- recorded | computer_stopped | workspace_suspended
  action text not null default 'recorded',
  created_at timestamptz not null default now()
);
create index abuse_events_time_idx on public.abuse_events (created_at desc);
create index abuse_events_org_idx on public.abuse_events (org_id, created_at desc);
alter table public.abuse_events enable row level security;

-- Proof-of-work sign-up challenges are single use (service role only).
create table public.used_signup_challenges (
  challenge_hash text primary key,
  used_at timestamptz not null default now()
);
alter table public.used_signup_challenges enable row level security;
