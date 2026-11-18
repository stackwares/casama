-- Plugins (SPEC: Post-v1 roadmap → Plugins; D-121): Agent Plugins 1.0 packages from GitHub, pinned
-- to a commit, installed for a bot. A plugin's skills, MCP connections and files hang off the
-- plugin row, so uninstalling removes everything it added.
create table public.plugins (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  name text not null check (name ~ '^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$' and char_length(name) <= 64),
  version text check (char_length(version) <= 64),
  description text not null default '' check (char_length(description) <= 2000),
  -- {owner, repo, path, ref}
  source jsonb not null,
  commit_sha text not null check (commit_sha ~ '^[0-9a-f]{40}$'),
  -- What the check found: {skills, servers, secrets, hosts, warnings}
  summary jsonb not null default '{}'::jsonb,
  installed_by uuid references auth.users (id) on delete set null,
  installed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bot_id, name)
);

-- The package's files (without its skills), written to the bot's computer for stdio servers.
create table public.plugin_files (
  plugin_id uuid not null references public.plugins (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  path text not null check (char_length(path) between 1 and 500),
  content bytea not null check (octet_length(content) <= 5000000),
  executable boolean not null default false,
  primary key (plugin_id, path)
);

alter table public.skills add column plugin_id uuid references public.plugins (id) on delete cascade;
alter table public.skills drop constraint skills_source_check;
alter table public.skills add constraint skills_source_check check (source in ('manual', 'catalog', 'github', 'bot', 'plugin'));
alter table public.integrations add column plugin_id uuid references public.plugins (id) on delete cascade;
alter table public.integrations drop constraint integrations_kind_check;
-- computer_mcp: a plugin's stdio MCP server, run by computerd inside the bot's computer.
alter table public.integrations add constraint integrations_kind_check
  check (kind in ('mcp', 'openapi', 'composio', 'pipedream', 'local_mcp', 'computer_mcp'));

alter table public.plugins enable row level security;
alter table public.plugin_files enable row level security;
create policy plugins_select on public.plugins for select to authenticated using (public.can_access_bot(bot_id));
create policy plugins_delete on public.plugins for delete to authenticated using (public.can_manage_bot(bot_id));
create policy plugin_files_select on public.plugin_files for select to authenticated using (
  exists (select 1 from public.plugins p where p.id = plugin_id and public.can_access_bot(p.bot_id)));
select public.allow_worker('public.plugins');
select public.allow_worker('public.plugin_files');
