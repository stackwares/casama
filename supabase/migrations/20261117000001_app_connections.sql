-- Built-in app connections (D-089): one-click OAuth for vendors' hosted MCP servers.

-- An OAuth sign-in in progress: created when someone presses Connect, finished by the provider's
-- redirect to the API. Holds the PKCE verifier and the OAuth client until then. Only the API's
-- service role reads it (RLS on, no policies).
create table public.integration_oauth_flows (
  id uuid primary key default gen_random_uuid(),
  state text not null unique,
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by uuid references auth.users (id) on delete cascade,
  app_id text not null,
  name text not null,
  -- the integration's config once connected: {url, app, auth: 'oauth'}
  config jsonb not null default '{}'::jsonb,
  -- {auth_server, metadata, client, code_verifier, redirect_uri, resource}
  oauth jsonb not null,
  -- set when reconnecting an existing integration
  integration_id uuid references public.integrations (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'connected', 'error')),
  error text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '15 minutes'
);
create index integration_oauth_flows_org_idx on public.integration_oauth_flows (org_id, created_at);
alter table public.integration_oauth_flows enable row level security;
