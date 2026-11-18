-- Casama Link (D-296): a self-hosted server linked to a Casama Cloud workspace gets a public
-- https address through a tunnel that Casama Cloud creates for it. These tables are the cloud
-- side's records; a self-hosted server keeps them empty.

-- ---------------------------------------------------------------------------
-- Linking: the server shows a short code, a workspace admin approves it in the browser, and the
-- server's next poll receives a key. The key is made at that poll, so it never rests here.
-- ---------------------------------------------------------------------------
create table public.link_sign_in_requests (
  id uuid primary key default gen_random_uuid(),
  device_code_hash text not null unique,
  user_code text not null unique,
  instance_id text not null check (instance_id ~ '^[A-Za-z0-9-]{8,64}$'),
  instance_name text not null check (char_length(instance_name) between 1 and 80),
  platform text check (char_length(platform) <= 40),
  version text check (char_length(version) <= 40),
  org_id uuid references public.organizations (id) on delete cascade,
  approved_by uuid references auth.users (id) on delete set null,
  approved_at timestamptz,
  consumed_at timestamptz,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index link_sign_in_requests_expiry_idx on public.link_sign_in_requests (expires_at);
alter table public.link_sign_in_requests enable row level security;
-- No policies: only the API reads and writes link requests.

-- ---------------------------------------------------------------------------
-- Linked servers and their addresses. `label` is the address: https://<label>.<zone>, with bot
-- pages on https://<label>-p.<zone>. It is kept while the tunnel is parked or released, so a
-- server comes back at the same address.
--   active     a tunnel exists
--   parked     the server wasn't seen for a while; its tunnel was removed and returns when it is
--   released   the server turned remote access off; the address stays reserved for a time
--   suspended  taken down by the instance owner or with the workspace
-- `tunnel_id` set on a row that isn't active means the tunnel still has to be removed.
-- `generation` goes up whenever the tunnel changes; a server holding an older one asks again.
-- ---------------------------------------------------------------------------
create table public.link_servers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  key_id uuid references public.link_keys (id) on delete set null,
  instance_id text not null check (instance_id ~ '^[A-Za-z0-9-]{8,64}$'),
  instance_name text not null check (char_length(instance_name) between 1 and 80),
  label text not null unique check (label ~ '^[a-z][a-z0-9]{7,31}$'),
  tunnel_id text,
  generation integer not null default 0,
  status text not null default 'active' check (status in ('active', 'parked', 'released', 'suspended')),
  status_reason text,
  platform text,
  version text,
  last_seen_at timestamptz,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, instance_id)
);
create index link_servers_org_idx on public.link_servers (org_id);
create index link_servers_sweep_idx on public.link_servers (status, last_seen_at);
alter table public.link_servers enable row level security;
create policy link_servers_select on public.link_servers
  for select to authenticated using (public.has_role(org_id, 'admin'));

-- Keys made by linking carry the scopes remote_access and push, which can't spend money. Keys
-- made by hand keep computers and models unless told otherwise.

-- ---------------------------------------------------------------------------
-- Plan limit: how many servers a workspace may connect (D-296: Free 1, Plus 1, Pro 3, Max 10).
-- ---------------------------------------------------------------------------
update public.plans set limits = limits || '{"remote_servers": 1}'::jsonb
where code in ('free', 'plus', 'plus_yearly');
update public.plans set limits = limits || '{"remote_servers": 3}'::jsonb
where code in ('pro', 'pro_yearly');
update public.plans set limits = limits || '{"remote_servers": 10}'::jsonb
where code in ('max', 'max_yearly');
-- Workspaces already on a plan get the new key now (their own value, if any, wins).
update public.entitlements e
set limits = jsonb_build_object('remote_servers', p.limits -> 'remote_servers') || e.limits
from public.plans p
where p.code = e.plan_code and p.limits ? 'remote_servers';
