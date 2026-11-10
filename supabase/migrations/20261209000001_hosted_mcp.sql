-- Hosted MCP endpoint (SPEC: Post-v1 roadmap → Hosted MCP endpoint; D-117). The @kasama/mcp tools
-- over Streamable HTTP at /mcp, authorized with OAuth (dynamic client registration, PKCE) or a
-- workspace API key. Every token acts as one person in one workspace.

create table public.mcp_clients (
  client_id text primary key,
  name text not null check (char_length(name) between 1 and 200),
  redirect_uris text[] not null check (cardinality(redirect_uris) between 1 and 10),
  created_at timestamptz not null default now()
);

-- An authorization in progress: created at /oauth/authorize, approved in the app, then exchanged.
create table public.mcp_auth_requests (
  id uuid primary key default gen_random_uuid(),
  client_id text not null references public.mcp_clients (client_id) on delete cascade,
  redirect_uri text not null,
  code_challenge text not null,
  state text,
  user_id uuid references auth.users (id) on delete cascade,
  org_id uuid references public.organizations (id) on delete cascade,
  code_hash text unique,
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied', 'used')),
  expires_at timestamptz not null default now() + interval '10 minutes',
  created_at timestamptz not null default now()
);

create table public.mcp_tokens (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  kind text not null check (kind in ('access', 'refresh', 'api_key')),
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  client_id text references public.mcp_clients (client_id) on delete cascade,
  name text,
  hint text,
  expires_at timestamptz,
  revoked_at timestamptz,
  last_used_at timestamptz,
  created_at timestamptz not null default now()
);
create index mcp_tokens_org_idx on public.mcp_tokens (org_id, kind);

-- Approving or denying over MCP is off unless the workspace allows it.
alter table public.organizations add column mcp_decide_approvals boolean not null default false;

-- Only the API reads and writes these (it checks who may); members see their workspace's API keys.
alter table public.mcp_clients enable row level security;
alter table public.mcp_auth_requests enable row level security;
alter table public.mcp_tokens enable row level security;
create policy mcp_tokens_select on public.mcp_tokens for select to authenticated
  using (kind = 'api_key' and public.has_role(org_id, 'admin'));
select public.allow_worker('public.mcp_clients');
select public.allow_worker('public.mcp_auth_requests');
select public.allow_worker('public.mcp_tokens');
