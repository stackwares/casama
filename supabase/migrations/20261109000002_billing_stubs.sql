-- Phase 0: billing-ready stubs. Phase 7 adds subscriptions, credit_ledger, billing_events.

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  interval text not null default 'none' check (interval in ('none', 'month', 'year')),
  limits jsonb not null default '{}'::jsonb,
  dodo_product_id text,
  store_product_ids jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.entitlements (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  plan_code text not null references public.plans (code),
  limits jsonb not null default '{}'::jsonb,
  valid_until timestamptz,
  subscription_id uuid,
  created_at timestamptz not null default now()
);
create index entitlements_org_id_idx on public.entitlements (org_id);

alter table public.plans enable row level security;
alter table public.entitlements enable row level security;

create policy plans_select on public.plans
  for select to authenticated using (active);
-- Entitlements are computed by the server; members can only read them.
create policy entitlements_select on public.entitlements
  for select to authenticated using (public.is_member(org_id));

-- One default plan for self-hosted installs: no limits.
insert into public.plans (code, name, interval, limits)
values ('selfhost', 'Self-hosted', 'none', '{"unlimited": true}'::jsonb);

-- Every new organization gets an entitlement for its plan.
create or replace function public.organizations_default_entitlement()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.entitlements (org_id, plan_code, limits)
  select new.id, p.code, p.limits from public.plans p where p.code = new.plan;
  return new;
end;
$$;
create trigger organizations_default_entitlement
after insert on public.organizations
for each row execute function public.organizations_default_entitlement();
