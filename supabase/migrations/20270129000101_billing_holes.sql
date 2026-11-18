-- Billing holes from docs/MONETIZATION-AUDIT-2026-11-13.md, and credits that expire (D-246).
--
-- 1. A workspace made outside the API (a direct call to create_organization) started on the
--    unlimited `selfhost` plan even with billing on. The server now records whether billing is
--    on, and new workspaces start on `free` when it is.
-- 2. One person can own at most 5 workspaces on a server with billing on (billing_settings).
-- 3. Credits are kept in lots so they can expire: a month's included credits carry over into the
--    next month and then lapse; packs and rewards last 12 months. Spending takes the lot that
--    lapses first.

-- ---------------------------------------------------------------------------
-- Whether this server bills (written by the API and worker as they start; D-246)
-- ---------------------------------------------------------------------------
alter table public.billing_settings add column enabled boolean not null default false;
-- How many workspaces one person can own while billing is on.
alter table public.billing_settings add column max_owned_workspaces int not null default 5
  check (max_owned_workspaces >= 1);

create or replace function public.billing_on()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select enabled from public.billing_settings where id), false);
$$;
revoke execute on function public.billing_on() from public, anon, authenticated;

-- New workspaces start on the free plan when billing is on, however they're made.
create or replace function public.organizations_cloud_plan()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.plan = 'selfhost' and public.billing_on()
     and exists (select 1 from public.plans where code = 'free') then
    new.plan := 'free';
  end if;
  return new;
end;
$$;
create trigger organizations_cloud_plan
before insert on public.organizations
for each row execute function public.organizations_cloud_plan();

-- ---------------------------------------------------------------------------
-- At most `max_owned_workspaces` (5) workspaces of one's own on a server with billing on
-- ---------------------------------------------------------------------------
create or replace function public.create_organization(p_name text, p_slug text)
returns public.organizations
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_org public.organizations;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if public.billing_on() then
    perform pg_advisory_xact_lock(hashtext('create_organization:' || v_uid::text));
    if (select count(*) from public.organizations where created_by = v_uid)
       >= (select max_owned_workspaces from public.billing_settings where id) then
      raise exception 'workspace_limit' using errcode = 'PT402';
    end if;
  end if;
  insert into public.organizations (name, slug, created_by)
  values (p_name, p_slug, v_uid)
  returning * into v_org;
  insert into public.memberships (org_id, user_id, role) values (v_org.id, v_uid, 'owner');
  return v_org;
end;
$$;

-- ---------------------------------------------------------------------------
-- Credit lots and expiry
-- ---------------------------------------------------------------------------
alter table public.credit_ledger drop constraint credit_ledger_reason_check;
alter table public.credit_ledger add constraint credit_ledger_reason_check
  check (reason in ('purchase', 'usage', 'grant', 'refund', 'adjustment', 'expire'));

-- What's left of each credit top-up and when it lapses. The remaining amounts add up to the
-- balance whenever it's above zero (a top-up only adds the part that lifts the balance above zero).
create table public.credit_lots (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  reason text not null,
  reference text,
  amount numeric(14, 6) not null check (amount > 0),
  remaining numeric(14, 6) not null check (remaining >= 0),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index credit_lots_open_idx on public.credit_lots (org_id, expires_at) where remaining > 0;
create index credit_lots_due_idx on public.credit_lots (expires_at) where remaining > 0;
alter table public.credit_lots enable row level security;
revoke all on public.credit_lots from anon, authenticated;

-- When a top-up lapses: a month's included credits at the end of the following month; purchases and
-- rewards after 12 months; adjustments never.
create or replace function public.credit_lot_expiry(p_reason text, p_reference text)
returns timestamptz
language sql stable set search_path = ''
as $$
  select case
    when p_reason = 'grant' and p_reference like 'monthly:%'
      then date_trunc('month', now()) + interval '2 months'
    when p_reason in ('grant', 'purchase') then now() + interval '12 months'
    else null
  end;
$$;

create or replace function public.credit_apply(
  p_org uuid, p_delta numeric, p_reason text, p_reference text, p_note text default null)
returns numeric
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_bal numeric;
  v_new numeric;
  v_lot numeric;
  v_left numeric;
  r record;
begin
  perform 1 from public.organizations where id = p_org for update;
  select balance_after into v_bal from public.credit_ledger where org_id = p_org order by seq desc limit 1;
  v_bal := coalesce(v_bal, 0);
  if p_reference is not null and exists (
    select 1 from public.credit_ledger where org_id = p_org and reason = p_reason and reference = p_reference) then
    return v_bal;
  end if;
  v_new := v_bal + p_delta;
  insert into public.credit_ledger (org_id, delta, reason, reference, note, balance_after)
  values (p_org, p_delta, p_reason, p_reference, p_note, v_new);

  if p_delta > 0 then
    -- Only the part above zero becomes spendable credit; the rest pays off a negative balance.
    v_lot := greatest(v_new, 0) - greatest(v_bal, 0);
    if v_lot > 0 then
      insert into public.credit_lots (org_id, reason, reference, amount, remaining, expires_at)
      values (p_org, p_reason, p_reference, v_lot, v_lot, public.credit_lot_expiry(p_reason, p_reference));
    end if;
  elsif p_delta < 0 and p_reason <> 'expire' then
    -- Spend the credits that lapse first.
    v_left := -p_delta;
    for r in
      select id, remaining from public.credit_lots
      where org_id = p_org and remaining > 0
      order by expires_at nulls last, created_at
      for update
    loop
      exit when v_left <= 0;
      update public.credit_lots set remaining = remaining - least(r.remaining, v_left) where id = r.id;
      v_left := v_left - least(r.remaining, v_left);
    end loop;
  end if;
  return v_new;
end;
$$;
revoke execute on function public.credit_apply(uuid, numeric, text, text, text) from public, anon, authenticated;

-- Takes lapsed credits off the balance, once per lot. Run by the worker's settle step.
create or replace function public.expire_credits(p_limit int default 500)
returns numeric
language plpgsql volatile security definer set search_path = ''
as $$
declare
  r record;
  v_total numeric := 0;
begin
  for r in
    select id, org_id, remaining from public.credit_lots
    where remaining > 0 and expires_at is not null and expires_at <= now()
    order by expires_at
    limit p_limit
    for update skip locked
  loop
    update public.credit_lots set remaining = 0 where id = r.id;
    perform public.credit_apply(r.org_id, -r.remaining, 'expire', 'lot:' || r.id::text, 'Unused credits expired');
    v_total := v_total + r.remaining;
  end loop;
  return v_total;
end;
$$;
revoke execute on function public.expire_credits(int) from public, anon, authenticated;

-- Credits people already have: one lot per workspace with a positive balance, lasting 12 months.
insert into public.credit_lots (org_id, reason, reference, amount, remaining, expires_at)
select b.org_id, 'adjustment', 'opening-balance', b.balance_after, b.balance_after, now() + interval '12 months'
from (
  select distinct on (org_id) org_id, balance_after from public.credit_ledger order by org_id, seq desc
) b
where b.balance_after > 0;
