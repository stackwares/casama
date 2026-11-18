-- Agent-to-agent (SPEC: Agent-to-agent; D-140). Off by default: the workspace turns A2A on, then
-- chooses which bots are published as A2A agents. A2A tasks become runs.
alter table public.organizations add column a2a_enabled boolean not null default false;
alter table public.bots add column a2a_published boolean not null default false;

create table public.a2a_tasks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  -- The workspace API key's person; tasks and contexts are theirs.
  caller_user_id uuid not null references auth.users (id) on delete cascade,
  context_id uuid not null,
  conversation_id uuid references public.conversations (id) on delete set null,
  run_id uuid references public.runs (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index a2a_tasks_context_idx on public.a2a_tasks (bot_id, caller_user_id, context_id);
alter table public.a2a_tasks enable row level security;
create policy a2a_tasks_select on public.a2a_tasks for select to authenticated using (public.can_access_bot(bot_id));
select public.allow_worker('public.a2a_tasks');

alter table public.integrations drop constraint integrations_kind_check;
alter table public.integrations add constraint integrations_kind_check
  check (kind in ('mcp', 'openapi', 'composio', 'pipedream', 'local_mcp', 'computer_mcp', 'a2a'));
