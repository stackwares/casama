-- Vendor monitoring data is instance-wide. Access is through the admin API or worker,
-- never directly by authenticated workspace users.
create table public.vendor_limits (
  vendor text primary key,
  label text not null,
  kind text not null check (kind in ('quota', 'balance', 'renewal')),
  unit text not null,
  limit_value numeric check (limit_value is null or limit_value > 0),
  period text check (period in ('day', 'month', 'billing_period', 'prepaid')),
  period_start timestamptz,
  expires_at timestamptz,
  warn_at numeric not null default 0.8 check (warn_at > 0 and warn_at <= 1),
  enabled boolean not null default true
);

create table public.vendor_checks (
  id bigint generated always as identity primary key,
  vendor text not null references public.vendor_limits(vendor) on delete cascade,
  checked_at timestamptz not null default now(),
  used numeric,
  remaining numeric,
  limit_value numeric,
  resets_at timestamptz,
  status text not null check (status in ('ok', 'low', 'out', 'unknown')),
  source text not null check (source in ('api', 'own_count', 'manual')),
  error text
);
create index vendor_checks_latest_idx on public.vendor_checks (vendor, checked_at desc);

create table public.vendor_counts (
  vendor text not null references public.vendor_limits(vendor) on delete cascade,
  day date not null,
  count bigint not null default 0 check (count >= 0),
  primary key (vendor, day)
);

alter table public.vendor_limits enable row level security;
alter table public.vendor_checks enable row level security;
alter table public.vendor_counts enable row level security;
select public.allow_worker('public.vendor_limits');
select public.allow_worker('public.vendor_checks');
select public.allow_worker('public.vendor_counts');
revoke all on public.vendor_limits, public.vendor_checks, public.vendor_counts from anon, authenticated;
