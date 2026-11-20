-- Free plans for friends (docs/COMP-PLANS-PLAN.md). Only the server creates comps and codes;
-- workspaces see their comp through the billing summary, never these tables.

alter table public.billing_settings
  add column comps_enabled boolean not null default false,
  -- Plans an owner may grant directly, and the (narrower) plans a gift code may carry.
  add column comp_grant_plans text[] not null default array['plus', 'pro', 'max'],
  add column comp_code_plans text[] not null default array['plus', 'pro'],
  add column comp_max_months integer not null default 12 check (comp_max_months between 1 and 36),
  add column comp_max_active integer not null default 50 check (comp_max_active between 1 and 100000);

create table public.comp_codes (
  id uuid primary key default gen_random_uuid(),
  -- sha256 of the normalized code; the code itself is shown once, when it is made.
  code_hash text not null unique,
  code_hint text not null check (length(code_hint) between 1 and 12),
  plan_code text not null references public.plans (code),
  months integer not null check (months between 1 and 36),
  max_redemptions integer not null default 1 check (max_redemptions between 1 and 10000),
  redeemed_count integer not null default 0 check (redeemed_count >= 0),
  redeem_by timestamptz,
  note text check (note is null or length(note) <= 200),
  created_by uuid not null,
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  check (redeemed_count <= max_redemptions)
);

create table public.comps (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete set null,
  -- public.user_email_key of the person, so one inbox redeems one gift code.
  redeemer_key text,
  plan_code text not null references public.plans (code),
  months integer not null check (months between 1 and 36),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  subscription_id uuid references public.subscriptions (id) on delete set null,
  granted_by uuid,
  code_id uuid references public.comp_codes (id),
  note text check (note is null or length(note) <= 200),
  ended_at timestamptz,
  end_reason text check (end_reason in ('expired', 'revoked', 'replaced_by_purchase')),
  ended_by uuid,
  reminder_sent_at timestamptz,
  converted_at timestamptz,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check ((ended_at is null) = (end_reason is null))
);
create unique index comps_one_running on public.comps (org_id) where ended_at is null;
create unique index comps_one_code_per_user on public.comps (user_id) where code_id is not null;
create unique index comps_one_code_per_inbox on public.comps (redeemer_key) where code_id is not null and redeemer_key is not null;
create index comps_due on public.comps (ends_at) where ended_at is null;

create table public.comp_events (
  id uuid primary key default gen_random_uuid(),
  comp_id uuid,
  code_id uuid,
  org_id uuid,
  actor_id uuid,
  action text not null,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index comp_events_comp on public.comp_events (comp_id, created_at);
-- No foreign keys on the log: deleting a workspace must not delete its history.
create function public.comp_log_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'comp_events is append only';
end;
$$;
create trigger comp_events_immutable before update or delete or truncate
on public.comp_events for each statement execute function public.comp_log_immutable();

alter table public.comp_codes enable row level security;
alter table public.comps enable row level security;
alter table public.comp_events enable row level security;
revoke all on public.comp_codes, public.comps, public.comp_events from anon, authenticated;
select public.allow_worker('public.comp_codes');
select public.allow_worker('public.comps');
select public.allow_worker('public.comp_events');
revoke update, delete, truncate on public.comp_events from casama_worker;

-- The person with this exact address (comps are granted by email; the worker never reads auth).
create or replace function public.worker_user_by_email(p_email text)
returns uuid
language sql stable security definer set search_path = ''
as $$
  select u.id from auth.users u
  where lower(u.email) = lower(btrim(coalesce(p_email, '')))
  order by u.created_at limit 1
$$;
revoke all on function public.worker_user_by_email(text) from public, anon, authenticated;
grant execute on function public.worker_user_by_email(text) to casama_worker;
