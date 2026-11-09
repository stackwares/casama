-- Phase 7: billing (D-070). Plans and entitlements exist since Phase 0; this adds subscriptions,
-- credits, webhook events and Cloud Connect. Self-hosted installs keep BILLING_ENABLED=false and
-- never touch these tables beyond the default 'selfhost' entitlement.

-- ---------------------------------------------------------------------------
-- Plans and credit packs
-- ---------------------------------------------------------------------------
alter table public.plans add column sort integer not null default 0;
alter table public.plans add column price_label text;

-- Placeholder Kasama Cloud plans; names, prices and limits are open decisions (SPEC "Monetization").
-- Product ids are set per deployment (docs/NEEDS-FROM-OLIVER.md).
insert into public.plans (code, name, interval, limits, store_product_ids, sort, price_label) values
  ('free', 'Free', 'none',
   '{"credit_gate": true, "monthly_credits_usd": 1, "max_bots": 2, "max_computers": 1, "computer_hours": 5, "seats": 1}', '{}', 0, null),
  ('pro', 'Pro', 'month',
   '{"credit_gate": true, "monthly_credits_usd": 20, "max_bots": 20, "max_computers": 5, "computer_hours": 100, "seats": 5}',
   '{"app_store": "dev.kasama.pro.monthly", "google_play": "kasama_pro:monthly"}', 1, null),
  ('pro_yearly', 'Pro (yearly)', 'year',
   '{"credit_gate": true, "monthly_credits_usd": 20, "max_bots": 20, "max_computers": 5, "computer_hours": 100, "seats": 5}',
   '{"app_store": "dev.kasama.pro.yearly", "google_play": "kasama_pro:yearly"}', 2, null);

create table public.credit_packs (
  code text primary key,
  name text not null,
  credits_usd numeric(12, 2) not null check (credits_usd > 0),
  dodo_product_id text unique,
  store_product_ids jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
insert into public.credit_packs (code, name, credits_usd, store_product_ids) values
  ('credits_10', '$10 of credits', 10, '{"app_store": "dev.kasama.credits.10", "google_play": "kasama_credits_10"}');

-- ---------------------------------------------------------------------------
-- Subscriptions (one row per store subscription; purchases belong to the workspace)
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  source text not null check (source in ('dodo', 'app_store', 'google_play')),
  external_id text not null,
  customer_id text,
  plan_code text not null references public.plans (code),
  status text not null check (status in ('active', 'trialing', 'grace', 'past_due', 'on_hold', 'paused', 'cancelled', 'expired', 'refunded', 'pending')),
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source, external_id)
);
create index subscriptions_org_idx on public.subscriptions (org_id);

alter table public.entitlements add column source text not null default 'default';
alter table public.entitlements add constraint entitlements_subscription_fk
  foreign key (subscription_id) references public.subscriptions (id) on delete set null;
-- Owner overrides from the admin console survive recomputation.
alter table public.entitlements add column overrides jsonb not null default '{}'::jsonb;
alter table public.entitlements add column updated_at timestamptz not null default now();

-- ---------------------------------------------------------------------------
-- Credits: an append-only ledger with a running balance
-- ---------------------------------------------------------------------------
create table public.credit_ledger (
  id uuid primary key default gen_random_uuid(),
  seq bigserial not null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  delta numeric(14, 6) not null,
  reason text not null check (reason in ('purchase', 'usage', 'grant', 'refund', 'adjustment')),
  reference text,
  note text,
  balance_after numeric(14, 6) not null,
  created_at timestamptz not null default now()
);
create index credit_ledger_org_seq_idx on public.credit_ledger (org_id, seq desc);
create unique index credit_ledger_ref_idx on public.credit_ledger (org_id, reason, reference)
  where reference is not null;

-- Applies a credit change once per (org, reason, reference) and returns the new balance.
create or replace function public.credit_apply(
  p_org uuid, p_delta numeric, p_reason text, p_reference text, p_note text default null)
returns numeric
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_bal numeric;
begin
  perform 1 from public.organizations where id = p_org for update;
  select balance_after into v_bal from public.credit_ledger where org_id = p_org order by seq desc limit 1;
  v_bal := coalesce(v_bal, 0);
  if p_reference is not null and exists (
    select 1 from public.credit_ledger where org_id = p_org and reason = p_reason and reference = p_reference) then
    return v_bal;
  end if;
  insert into public.credit_ledger (org_id, delta, reason, reference, note, balance_after)
  values (p_org, p_delta, p_reason, p_reference, p_note, v_bal + p_delta);
  return v_bal + p_delta;
end;
$$;
revoke execute on function public.credit_apply(uuid, numeric, text, text, text) from public, anon, authenticated;

-- Usage that the platform pays for (computers, streams, cloud model credits) becomes credit deductions.
alter table public.usage_ledger add column billable boolean;
alter table public.usage_ledger add column billed_at timestamptz;
alter table public.usage_ledger add column meta jsonb not null default '{}'::jsonb;
create or replace function public.usage_ledger_billable()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.billable := coalesce(new.billable, new.kind in ('computer_seconds', 'stream_seconds'));
  return new;
end;
$$;
create trigger usage_ledger_billable before insert on public.usage_ledger
for each row execute function public.usage_ledger_billable();
update public.usage_ledger set billable = kind in ('computer_seconds', 'stream_seconds');
alter table public.usage_ledger alter column billable set not null;
create index usage_ledger_unbilled_idx on public.usage_ledger (org_id) where billable and billed_at is null;

-- ---------------------------------------------------------------------------
-- Webhook and notification log: stored first, processed once by event id
-- ---------------------------------------------------------------------------
create table public.billing_events (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('dodo', 'app_store', 'google_play')),
  event_id text not null,
  type text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  error text,
  unique (source, event_id)
);

-- ---------------------------------------------------------------------------
-- Cloud Connect: self-hosted instances use cloud computers and model credits
-- ---------------------------------------------------------------------------
create table public.cloud_connect_keys (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  key_hash text not null unique,
  key_hint text not null,
  instance_name text not null check (char_length(instance_name) between 1 and 80),
  scopes text[] not null default '{computers,models}',
  created_by uuid references auth.users (id) on delete set null,
  last_used_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index cloud_connect_keys_org_idx on public.cloud_connect_keys (org_id);

-- Which org owns a cloud computer, and how long it ran (metered on the proxy).
create table public.cloud_connect_computers (
  ref text primary key,
  org_id uuid not null references public.organizations (id) on delete cascade,
  key_id uuid references public.cloud_connect_keys (id) on delete set null,
  instance_name text not null,
  running_since timestamptz,
  created_at timestamptz not null default now()
);
create index cloud_connect_computers_org_idx on public.cloud_connect_computers (org_id);

-- ---------------------------------------------------------------------------
-- RLS: members read their workspace's billing; only the server writes
-- ---------------------------------------------------------------------------
alter table public.credit_packs enable row level security;
alter table public.subscriptions enable row level security;
alter table public.credit_ledger enable row level security;
alter table public.billing_events enable row level security;
alter table public.cloud_connect_keys enable row level security;
alter table public.cloud_connect_computers enable row level security;

create policy credit_packs_select on public.credit_packs for select to authenticated using (active);
create policy subscriptions_select on public.subscriptions
  for select to authenticated using (public.is_member(org_id));
create policy credit_ledger_select on public.credit_ledger
  for select to authenticated using (public.is_member(org_id));
create policy cloud_connect_keys_select on public.cloud_connect_keys
  for select to authenticated using (public.has_role(org_id, 'admin'));
create policy cloud_connect_computers_select on public.cloud_connect_computers
  for select to authenticated using (public.is_member(org_id));
-- billing_events: no policies; only the server reads and writes it.
