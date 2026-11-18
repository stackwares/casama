-- Phase 4: approvals, secrets, routines, integrations, task board, devices, notifications.
-- Every table carries org_id (except per-user devices and notifications) and has RLS enabled here.

-- ---------------------------------------------------------------------------
-- Approvals and "always allow" grants
-- ---------------------------------------------------------------------------
create table public.approvals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid not null references public.runs (id) on delete cascade,
  call_id text not null,
  tool_name text not null,
  args_redacted jsonb not null default '{}'::jsonb,
  summary text not null default '',
  risk text not null check (risk in ('low', 'medium', 'high')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied', 'expired')),
  always_allow boolean not null default false,
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  expires_at timestamptz not null default now() + interval '24 hours',
  created_at timestamptz not null default now(),
  unique (run_id, call_id)
);
create index approvals_org_status_idx on public.approvals (org_id, status, created_at desc);

create table public.tool_grants (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  tool_name text not null,
  granted_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (bot_id, tool_name)
);

-- Decide an approval (security definer: checks access, records the decision atomically).
create or replace function public.decide_approval(p_approval_id uuid, p_decision text, p_always_allow boolean default false)
returns public.approvals
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v public.approvals;
begin
  if p_decision not in ('approved', 'denied') then
    raise exception 'bad_decision' using errcode = '22023';
  end if;
  select * into v from public.approvals where id = p_approval_id for update;
  if not found or not public.can_access_bot(v.bot_id) then
    raise exception 'approval_not_found' using errcode = 'P0002';
  end if;
  if v.status <> 'pending' then
    raise exception 'approval_already_decided' using errcode = '55000';
  end if;
  if v.expires_at < now() then
    update public.approvals set status = 'expired' where id = v.id returning * into v;
    return v;
  end if;
  update public.approvals
     set status = p_decision, always_allow = (p_decision = 'approved' and p_always_allow),
         decided_by = (select auth.uid()), decided_at = now()
   where id = v.id returning * into v;
  if v.always_allow then
    insert into public.tool_grants (org_id, bot_id, tool_name, granted_by)
    values (v.org_id, v.bot_id, v.tool_name, (select auth.uid()))
    on conflict (bot_id, tool_name) do nothing;
  end if;
  return v;
end;
$$;
grant execute on function public.decide_approval(uuid, text, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Named secrets ({{secret:NAME}} placeholders)
-- ---------------------------------------------------------------------------
create table public.secrets (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (name ~ '^[A-Z][A-Z0-9_]{0,63}$'),
  vault_secret_id uuid,
  allowed_bot_ids uuid[],
  allowed_hosts text[] not null default '{}',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (org_id, name)
);

-- ---------------------------------------------------------------------------
-- Routines
-- ---------------------------------------------------------------------------
create table public.routines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  conversation_id uuid references public.conversations (id) on delete set null,
  created_by uuid references auth.users (id) on delete set null,
  name text not null check (char_length(name) between 1 and 120),
  instructions_md text not null check (char_length(instructions_md) between 1 and 20000),
  schedule_cron text,
  timezone text not null default 'UTC',
  -- {type: 'schedule' | 'github' | 'webhook', vault_secret_id?: uuid, events?: string[]}
  trigger jsonb not null default '{"type": "schedule"}'::jsonb,
  notify boolean not null default true,
  enabled boolean not null default true,
  next_run_at timestamptz,
  -- plain uuid: a foreign key back to runs would make the two tables reference each other
  last_run_id uuid,
  last_run_at timestamptz,
  created_at timestamptz not null default now()
);
create index routines_due_idx on public.routines (enabled, next_run_at);

alter table public.runs add column routine_id uuid references public.routines (id) on delete set null;

-- ---------------------------------------------------------------------------
-- Integrations (MCP, OpenAPI, Composio, Pipedream)
-- ---------------------------------------------------------------------------
create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null check (kind in ('mcp', 'openapi', 'composio', 'pipedream')),
  name text not null check (name ~ '^[a-z][a-z0-9_]{0,39}$'),
  -- mcp: {url, auth_header?}; openapi: {spec, base_url?, auth?}; composio: {base_url?, toolkits[], user_id?};
  -- pipedream: {base_url?, project_id, client_id, environment?, apps[], external_user_id?}
  config jsonb not null default '{}'::jsonb,
  vault_secret_id uuid,
  status text not null default 'pending' check (status in ('pending', 'ok', 'error')),
  error text,
  -- cached tool list: [{name, description, input_schema, risk}]
  tools_cache jsonb not null default '[]'::jsonb,
  tools_cached_at timestamptz,
  -- per-tool risk overrides set by admins: {tool_name: 'low'|'medium'|'high'}
  risk_overrides jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (org_id, name)
);

create table public.bot_integrations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  integration_id uuid not null references public.integrations (id) on delete cascade,
  -- null = every tool of the integration
  tool_allowlist text[],
  created_at timestamptz not null default now(),
  unique (bot_id, integration_id)
);

-- ---------------------------------------------------------------------------
-- Task board
-- ---------------------------------------------------------------------------
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by_bot_id uuid references public.bots (id) on delete set null,
  created_by_user_id uuid references auth.users (id) on delete set null,
  assignee_bot_id uuid references public.bots (id) on delete set null,
  title text not null check (char_length(title) between 1 and 300),
  details_md text not null default '',
  status text not null default 'todo' check (status in ('todo', 'doing', 'done', 'blocked')),
  parent_run_id uuid references public.runs (id) on delete set null,
  result_md text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index tasks_org_idx on public.tasks (org_id, status, updated_at desc);

-- ---------------------------------------------------------------------------
-- Devices (push targets) and notifications (in-app inbox)
-- ---------------------------------------------------------------------------
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux')),
  fcm_token text not null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (fcm_token)
);
create index devices_user_idx on public.devices (user_id);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid references public.organizations (id) on delete cascade,
  kind text not null,
  -- {title, body, link, run_id?, approval_id?, bot_id?}
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- Media jobs count in the ledger.
alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'media_images', 'media_video_seconds', 'search_queries'));

-- fal.ai (media) and search providers keep their keys with model credentials.
alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal', 'brave_search', 'tavily'));

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.approvals enable row level security;
alter table public.tool_grants enable row level security;
alter table public.secrets enable row level security;
alter table public.routines enable row level security;
alter table public.integrations enable row level security;
alter table public.bot_integrations enable row level security;
alter table public.tasks enable row level security;
alter table public.devices enable row level security;
alter table public.notifications enable row level security;

-- approvals: visible with the bot; decided through decide_approval()
create policy approvals_select on public.approvals for select to authenticated using (public.can_access_bot(bot_id));

create policy tool_grants_select on public.tool_grants for select to authenticated using (public.can_access_bot(bot_id));
create policy tool_grants_delete on public.tool_grants for delete to authenticated using (public.can_manage_bot(bot_id));

-- secrets: metadata for members, changes by admins (values only through the API into Vault)
create policy secrets_select on public.secrets for select to authenticated using (public.is_member(org_id));
create policy secrets_delete on public.secrets for delete to authenticated using (public.has_role(org_id, 'admin'));

-- routines: anyone who can use the bot
create policy routines_select on public.routines for select to authenticated using (public.can_access_bot(bot_id));
create policy routines_update on public.routines for update to authenticated
  using (public.can_access_bot(bot_id)) with check (public.can_access_bot(bot_id));
create policy routines_delete on public.routines for delete to authenticated using (public.can_access_bot(bot_id));

-- integrations: metadata for members, management by admins (credentials only through the API)
create policy integrations_select on public.integrations for select to authenticated using (public.is_member(org_id));
create policy integrations_update on public.integrations for update to authenticated
  using (public.has_role(org_id, 'admin')) with check (public.has_role(org_id, 'admin'));
create policy integrations_delete on public.integrations for delete to authenticated using (public.has_role(org_id, 'admin'));

create policy bot_integrations_select on public.bot_integrations for select to authenticated using (public.can_access_bot(bot_id));
create policy bot_integrations_write on public.bot_integrations for all to authenticated
  using (public.can_manage_bot(bot_id))
  with check (public.can_manage_bot(bot_id)
              and exists (select 1 from public.integrations i where i.id = integration_id and i.org_id = bot_integrations.org_id));

-- tasks: members of the org
create policy tasks_select on public.tasks for select to authenticated using (public.is_member(org_id));
create policy tasks_insert on public.tasks for insert to authenticated
  with check (public.is_member(org_id) and created_by_user_id = (select auth.uid()));
create policy tasks_update on public.tasks for update to authenticated
  using (public.is_member(org_id)) with check (public.is_member(org_id));
create policy tasks_delete on public.tasks for delete to authenticated using (public.is_member(org_id));

-- devices and notifications: your own
create policy devices_own on public.devices for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_select on public.notifications for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_delete on public.notifications for delete to authenticated using (user_id = (select auth.uid()));

-- New notifications are broadcast to the private topic user:{id} for live inbox updates.
create or replace function public.notifications_broadcast()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('id', new.id, 'kind', new.kind, 'payload', new.payload, 'created_at', new.created_at),
    'notification', 'user:' || new.user_id::text, true);
  return null;
end;
$$;
create trigger notifications_broadcast after insert on public.notifications
for each row execute function public.notifications_broadcast();

-- Extend topic authorization: user:{own id}.
create or replace function public.realtime_topic_allowed(p_topic text)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_kind text := split_part(p_topic, ':', 1);
  v_id text := split_part(p_topic, ':', 2);
begin
  if v_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  if v_kind = 'run' then return public.can_access_run(v_id::uuid); end if;
  if v_kind = 'bot' then return public.can_access_bot(v_id::uuid); end if;
  if v_kind = 'user' then return v_id::uuid = (select auth.uid()); end if;
  return false;
end;
$$;
