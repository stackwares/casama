-- Saved resets are issued by the instance owner through the server, never by clients.
alter table public.billing_settings
  add column limit_resets_enabled boolean not null default false,
  add column limit_resets_per_period integer not null default 1 check (limit_resets_per_period between 1 and 100),
  add column limit_resets_max_held integer not null default 3 check (limit_resets_max_held between 1 and 100),
  add column limit_resets_notify_owners boolean not null default true;

create table public.limit_reset_campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 120),
  message text not null check (length(message) between 1 and 120 and message !~ E'[\r\n]'),
  audience jsonb not null,
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  refill_percent integer not null default 100 check (refill_percent between 10 and 100),
  reset_daily boolean not null default true,
  reset_computer boolean not null default false,
  max_per_use_usd numeric(14,6) check (max_per_use_usd >= 0),
  budget_usd numeric(14,6) check (budget_usd >= 0),
  refilled_usd numeric(14,6) not null default 0 check (refilled_usd >= 0),
  notify_arrival boolean not null default true,
  notify_reminder boolean not null default true,
  state text not null default 'draft' check (state in ('draft','scheduled','live','paused','cancelled','ended')),
  created_by uuid not null,
  created_at timestamptz not null default now(),
  check (expires_at > starts_at)
);
create table public.limit_resets (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  campaign_id uuid not null references public.limit_reset_campaigns(id),
  used_at timestamptz,
  used_by uuid,
  revoked_at timestamptz,
  undone_at timestamptz,
  period_key text,
  period_end timestamptz,
  refilled_usd numeric(14,6) not null default 0 check (refilled_usd >= 0),
  daily_offset_usd numeric(14,6) not null default 0,
  computer_offset_seconds numeric(18,6) not null default 0,
  arrival_sent_at timestamptz,
  reminder_sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique(org_id,campaign_id),
  check ((used_at is null) = (used_by is null))
);
create index limit_resets_org on public.limit_resets(org_id,used_at);
create index limit_reset_campaigns_due on public.limit_reset_campaigns(state,starts_at,expires_at);
create table public.limit_reset_events (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid,
  reset_id uuid,
  org_id uuid,
  actor_id uuid,
  action text not null,
  "before" jsonb,
  "after" jsonb,
  created_at timestamptz not null default now()
);
create index limit_reset_events_campaign on public.limit_reset_events(campaign_id,created_at);
create index limit_reset_events_org on public.limit_reset_events(org_id,created_at);
-- No foreign keys on the log: deleting a workspace or draft must not delete history.
create function public.limit_reset_log_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'limit_reset_events is append only';
end;
$$;
create trigger limit_reset_events_immutable before update or delete or truncate
on public.limit_reset_events for each statement execute function public.limit_reset_log_immutable();

alter table public.limit_reset_campaigns enable row level security;
alter table public.limit_resets enable row level security;
alter table public.limit_reset_events enable row level security;
revoke all on public.limit_reset_campaigns, public.limit_resets, public.limit_reset_events from anon, authenticated;
grant select on public.limit_resets to authenticated;
create policy limit_resets_member_read on public.limit_resets for select to authenticated
using (public.is_member(org_id));
select public.allow_worker('public.limit_reset_campaigns');
select public.allow_worker('public.limit_resets');
select public.allow_worker('public.limit_reset_events');
revoke update, delete, truncate on public.limit_reset_events from casama_worker;

alter table public.credit_ledger drop constraint credit_ledger_reason_check;
alter table public.credit_ledger add constraint credit_ledger_reason_check
check (reason in ('purchase','usage','grant','refund','adjustment','expire','reset'));

-- Meter offsets do not edit historical usage or the real-cost ledger.
create function public.limit_reset_offset(p_org uuid,p_kind text) returns numeric
language sql stable security definer set search_path='' as $$
  select coalesce(max(case when p_kind='daily' then daily_offset_usd else computer_offset_seconds end),0)
  from public.limit_resets
  where org_id=p_org and used_at is not null and undone_at is null
    and used_at >= (case when p_kind='daily' then date_trunc('day',now() at time zone 'utc') else date_trunc('month',now() at time zone 'utc') end at time zone 'utc');
$$;
revoke execute on function public.limit_reset_offset(uuid,text) from public,anon,authenticated;
grant execute on function public.limit_reset_offset(uuid,text) to casama_worker;
alter table public.limit_reset_campaigns add column end_notice_sent boolean not null default false;
-- Analytics delivery markers belong outside the immutable audit log.
create table public.limit_reset_deliveries (
  event_id uuid primary key references public.limit_reset_events(id),
  delivered_at timestamptz not null default now()
);
alter table public.limit_reset_deliveries enable row level security;
revoke all on public.limit_reset_deliveries from anon,authenticated;
select public.allow_worker('public.limit_reset_deliveries');
alter table public.limit_reset_campaigns add column budget_notice_sent boolean not null default false;
create function public.limit_reset_instance_owners(p_emails text[]) returns table(user_id uuid)
language sql stable security definer set search_path='' as $$
 select u.id from auth.users u where case when cardinality(p_emails)>0 then lower(u.email)=any(p_emails)
 else u.id=(select id from auth.users order by created_at limit 1) end;
$$;
revoke execute on function public.limit_reset_instance_owners(text[]) from public,anon,authenticated;
grant execute on function public.limit_reset_instance_owners(text[]) to casama_worker;
