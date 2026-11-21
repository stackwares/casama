-- Bug hunt 2026-11-21: store refunds by transaction. A refund names one store transaction; only
-- the one that paid for the current period takes the period and its credits back. A refund of an
-- older renewal is recorded here and takes nothing. REFUND_REVERSED gives back exactly what the
-- refund took (clawed_usd), once.
create table public.store_refunds (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  subscription_id uuid not null references public.subscriptions (id) on delete cascade,
  transaction_id text not null,
  current_period boolean not null,
  clawed_usd numeric(14, 6) not null default 0 check (clawed_usd >= 0),
  refunded_at timestamptz not null default now(),
  reversed_at timestamptz,
  unique (subscription_id, transaction_id)
);
create index store_refunds_transaction on public.store_refunds (transaction_id);
alter table public.store_refunds enable row level security;
revoke all on public.store_refunds from anon, authenticated;
select public.allow_worker('public.store_refunds');
