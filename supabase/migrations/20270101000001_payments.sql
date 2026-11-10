-- Payments (SPEC: Payments; D-142): single-use virtual cards from the workspace's own card issuing
-- account (Stripe Issuing), with monthly caps per workspace and per bot.
create table public.org_payments (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  provider text not null default 'stripe' check (provider in ('stripe')),
  vault_secret_id uuid not null,
  webhook_secret_id uuid not null,
  cardholder_id text not null,
  monthly_cap_usd numeric(12, 2) not null default 500 check (monthly_cap_usd >= 0),
  bot_monthly_cap_usd numeric(12, 2) not null default 200 check (bot_monthly_cap_usd >= 0),
  updated_at timestamptz not null default now()
);
alter table public.org_payments enable row level security;
create policy org_payments_select on public.org_payments for select to authenticated using (public.has_role(org_id, 'owner'));
select public.allow_worker('public.org_payments');

alter table public.bots add column payments_monthly_cap_usd numeric(12, 2) check (payments_monthly_cap_usd is null or payments_monthly_cap_usd >= 0);

create table public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  user_id uuid not null references auth.users (id) on delete cascade,
  merchant text not null check (char_length(merchant) between 2 and 200),
  amount_cents bigint not null check (amount_cents > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  reason text not null,
  status text not null default 'requested' check (status in ('requested', 'issued', 'used', 'declined', 'expired', 'failed', 'canceled')),
  provider_card_id text unique,
  last4 text,
  spent_cents bigint,
  error text,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index payment_requests_org_month_idx on public.payment_requests (org_id, created_at desc);
alter table public.payment_requests enable row level security;
create policy payment_requests_select on public.payment_requests for select to authenticated
  using (user_id = (select auth.uid()) or public.has_role(org_id, 'owner'));
select public.allow_worker('public.payment_requests');
