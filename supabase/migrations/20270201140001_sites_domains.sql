-- Sites and domains (docs/SITES-AND-DOMAINS-PLAN.md §7.14). A site is a public page served at its
-- own address (name.<sites zone>) and on domains a workspace connects or buys. No existing table
-- changes shape a shipped app reads, and no enum value is added.
--
-- Clients only read: every write goes through the API (a column on pages would have been writable
-- through the existing pages_update policy, which is why sites get their own table).

-- ---------------------------------------------------------------------------- Sites

create table public.sites (
  page_id uuid primary key references public.pages (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  -- Search engines may list it (off by default; Plus and up can turn it on).
  indexable boolean not null default false,
  -- "Made with Casama · Report" (always on site addresses; can go on a custom domain from Plus).
  badge boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  -- One change of address a day.
  label_changed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index sites_org_idx on public.sites (org_id);

-- A connected or bought domain. org_id is set null when the workspace is deleted: the registrant
-- still owns a bought domain until it expires (§7.10).
create table public.domains (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (
    name = lower(name) and char_length(name) between 3 and 253
    and name ~ '^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{0,61}[a-z0-9]$'),
  kind text not null check (kind in ('connected', 'registered')),
  org_id uuid references public.organizations (id) on delete set null,
  -- The name this domain's records point at, d-<16>.<zone>; never reused (§7.4).
  target text not null unique check (target = lower(target) and target ~ '^d-[a-z0-9]{16}\.'),
  -- Casama's own code for a TXT proof (_casama.<host> on a self-hosted server, _casama-claim to
  -- move a proved host between workspaces).
  verify_code text not null,
  -- The DNS company found from the domain's nameservers, for the right instructions.
  dns_provider text,
  checked_at timestamptz,
  -- Over the plan's domain limit since (§7.13): paused after 14 days.
  over_limit_since timestamptz,
  -- Bought domains (§7.6–7.10).
  registrar text,
  status text check (status in ('active', 'expired', 'lapsed', 'gone', 'moved_out', 'suspended')),
  expires_at timestamptz,
  auto_renew boolean not null default true,
  locked boolean not null default true,
  privacy boolean not null default true,
  transfer_after timestamptz,
  unlocked_at timestamptz,
  registrant_verified_at timestamptz,
  renew_price_usd numeric(10, 2),
  mandate_ref text,
  -- Record ids at the registrar that Casama manages for the site (shown locked in DNS Records).
  managed_records text[] not null default '{}',
  purchased_by uuid references auth.users (id) on delete set null,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((kind = 'registered') = (registrar is not null and status is not null))
);
create index domains_org_idx on public.domains (org_id);
create index domains_expiry_idx on public.domains (expires_at) where kind = 'registered';

-- Every host name a site answers on (§7.1, §7.4).
create table public.site_hosts (
  id uuid primary key default gen_random_uuid(),
  hostname text not null unique check (
    hostname = lower(hostname) and char_length(hostname) between 3 and 253
    and hostname ~ '^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{0,61}[a-z0-9]$'),
  kind text not null check (kind in ('address', 'custom')),
  org_id uuid not null references public.organizations (id) on delete cascade,
  page_id uuid references public.sites (page_id) on delete set null,
  domain_id uuid references public.domains (id) on delete cascade,
  is_primary boolean not null default false,
  status text not null default 'pending_dns' check (status in
    ('pending_dns', 'pending_cert', 'active', 'failed', 'disconnected', 'paused', 'suspended')),
  status_reason text,
  status_changed_at timestamptz not null default now(),
  -- The edge's id for this host (a Cloudflare custom hostname) and its ownership record (proof B).
  provider_ref text,
  ownership_name text,
  ownership_value text,
  verified_at timestamptz,
  last_checked_at timestamptz,
  proof_missing_since timestamptz,
  created_at timestamptz not null default now(),
  check ((kind = 'address') = (domain_id is null))
);
create unique index site_hosts_one_primary on public.site_hosts (page_id) where is_primary;
create index site_hosts_org_idx on public.site_hosts (org_id);
create index site_hosts_domain_idx on public.site_hosts (domain_id);
create index site_hosts_page_idx on public.site_hosts (page_id);
create index site_hosts_check_idx on public.site_hosts (status, last_checked_at)
  where status in ('pending_dns', 'pending_cert', 'active');

-- Address names that may not be taken again yet: 90 days for others, at once by the old workspace.
create table public.site_labels_retired (
  label text primary key check (label = lower(label) and char_length(label) between 1 and 63),
  org_id uuid references public.organizations (id) on delete set null,
  retired_at timestamptz not null default now()
);

-- Things to remove at a provider after their row is gone, so a cascade can't leave a billed,
-- serving hostname behind.
create table public.provider_cleanups (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('hostname')),
  ref text not null,
  hostname text,
  attempts integer not null default 0,
  last_error text,
  done_at timestamptz,
  created_at timestamptz not null default now()
);
create index provider_cleanups_open_idx on public.provider_cleanups (created_at) where done_at is null;

-- ---------------------------------------------------------------------------- Buying

-- The registrant's details, one set per workspace (sealed like other content). mandate_ref is the
-- workspace's stored payment for renewals and later purchases (§2.4).
create table public.domain_contacts (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  data jsonb not null,
  mandate_ref text,
  updated_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);

-- The registrant's email for a bought domain, kept when the workspace is deleted so the registrant
-- hears what happens to it (§7.10). Server only.
create table public.domain_registrants (
  domain_id uuid primary key references public.domains (id) on delete cascade,
  email text not null,
  updated_at timestamptz not null default now()
);

-- Every payment for a domain (§7.7).
create table public.domain_orders (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.organizations (id) on delete set null,
  domain_id uuid references public.domains (id) on delete set null,
  kind text not null check (kind in ('register', 'renew', 'restore')),
  name text not null check (name = lower(name) and char_length(name) between 3 and 253),
  years integer not null default 1 check (years = 1),
  price_usd numeric(10, 2) not null check (price_usd > 0),
  cost_usd numeric(10, 2) not null check (cost_usd > 0),
  status text not null default 'quote' check (status in ('quote', 'checkout', 'paid', 'registering',
    'registered', 'done', 'abandoned', 'refunding', 'refunded', 'needs_attention')),
  -- How it's paid: a browser checkout, or a charge on the workspace's mandate.
  charge_mode text not null default 'checkout' check (charge_mode in ('checkout', 'mandate')),
  payment_ref text unique,
  checkout_ref text,
  -- The site chosen at checkout.
  page_id uuid references public.pages (id) on delete set null,
  terms_version text,
  terms_accepted_at timestamptz,
  auto_renew boolean not null default true,
  -- Waiting for an instance owner (the first purchase of a workspace younger than a day, §7.11).
  needs_approval boolean not null default false,
  approved_at timestamptz,
  attempts integer not null default 0,
  next_attempt_at timestamptz,
  failure text,
  paid_at timestamptz,
  refunded_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- One live checkout per name.
create unique index domain_orders_one_live on public.domain_orders (name)
  where status in ('checkout', 'paid', 'registering');
create index domain_orders_org_idx on public.domain_orders (org_id, created_at desc);
create index domain_orders_open_idx on public.domain_orders (status) where status in
  ('checkout', 'paid', 'registering', 'refunding', 'needs_attention');

-- The domain's history, shown on its screen.
create table public.domain_events (
  id uuid primary key default gen_random_uuid(),
  domain_id uuid not null references public.domains (id) on delete cascade,
  org_id uuid references public.organizations (id) on delete set null,
  kind text not null check (char_length(kind) between 1 and 60),
  detail jsonb not null default '{}'::jsonb,
  -- One per domain, expiry and step: a repeated upkeep run never acts twice (§7.8).
  dedupe text unique,
  created_at timestamptz not null default now()
);
create index domain_events_domain_idx on public.domain_events (domain_id, created_at desc);

-- The domain price (§8), changed from Admin like the credit markup.
alter table public.billing_settings
  add column domain_markup numeric(6, 3) not null default 1.25 check (domain_markup >= 1),
  add column domain_fee_usd numeric(6, 2) not null default 1.50 check (domain_fee_usd >= 0);

-- ---------------------------------------------------------------------------- Triggers

-- A deleted host is always cleaned up at the edge, and a deleted address stays retired.
create function public.site_hosts_after_delete() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.provider_ref is not null then
    insert into public.provider_cleanups (kind, ref, hostname) values ('hostname', old.provider_ref, old.hostname);
  end if;
  if old.kind = 'address' then
    insert into public.site_labels_retired (label, org_id, retired_at)
    values (split_part(old.hostname, '.', 1), old.org_id, now())
    on conflict (label) do update set org_id = excluded.org_id, retired_at = excluded.retired_at;
  end if;
  return old;
end $$;
create trigger site_hosts_after_delete after delete on public.site_hosts
  for each row execute function public.site_hosts_after_delete();

-- A site that goes away takes its address with it (the address is retired, a domain's hosts stay
-- for another site).
create function public.sites_before_delete() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.site_hosts where page_id = old.page_id and kind = 'address';
  return old;
end $$;
create trigger sites_before_delete before delete on public.sites
  for each row execute function public.sites_before_delete();

-- ---------------------------------------------------------------------------- Access

alter table public.sites enable row level security;
alter table public.site_hosts enable row level security;
alter table public.site_labels_retired enable row level security;
alter table public.domains enable row level security;
alter table public.domain_contacts enable row level security;
alter table public.domain_registrants enable row level security;
alter table public.domain_orders enable row level security;
alter table public.domain_events enable row level security;
alter table public.provider_cleanups enable row level security;

create policy sites_select on public.sites for select to authenticated
  using (public.is_member(org_id));
create policy site_hosts_select on public.site_hosts for select to authenticated
  using (public.is_member(org_id));
create policy domains_select on public.domains for select to authenticated
  using (org_id is not null and public.is_member(org_id));
create policy domain_events_select on public.domain_events for select to authenticated
  using (org_id is not null and public.is_member(org_id));
create policy domain_contacts_select on public.domain_contacts for select to authenticated
  using (public.has_role(org_id, 'admin'));
create policy domain_orders_select on public.domain_orders for select to authenticated
  using (org_id is not null and public.has_role(org_id, 'admin'));
-- site_labels_retired, domain_registrants, provider_cleanups: server only (no policies).

select public.allow_worker('public.sites');
select public.allow_worker('public.site_hosts');
select public.allow_worker('public.site_labels_retired');
select public.allow_worker('public.domains');
select public.allow_worker('public.domain_contacts');
select public.allow_worker('public.domain_registrants');
select public.allow_worker('public.domain_orders');
select public.allow_worker('public.domain_events');
select public.allow_worker('public.provider_cleanups');

-- ---------------------------------------------------------------------------- Plan limits

-- Merged, never replaced (§7.14, 20270201100301_restore_plan_limits.sql). A key a plan already has
-- is kept: the defaults go on the left of ||. Self-hosted has no value, which means no limit.
-- Search engines and turning the badge off on a custom domain follow max_custom_domains > 0.
update public.plans set limits = '{"max_sites": 1, "max_custom_domains": 0}'::jsonb || limits
where code = 'free';
update public.plans set limits = '{"max_sites": 3, "max_custom_domains": 1}'::jsonb || limits
where code in ('plus', 'plus_yearly');
update public.plans set limits = '{"max_sites": 10, "max_custom_domains": 5}'::jsonb || limits
where code in ('pro', 'pro_yearly');
update public.plans set limits = '{"max_sites": 50, "max_custom_domains": 20}'::jsonb || limits
where code in ('max', 'max_yearly');

update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';
