-- Questions a connected MCP server asks the person mid-call (MCP elicitation, D-363). The bot's
-- tool call waits for an answer (or a decline, or 10 minutes) and passes it back to the server.
-- The answer is cleared once the run has read it.

create table public.mcp_questions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid not null references public.runs (id) on delete cascade,
  integration_id uuid references public.integrations (id) on delete set null,
  connection text not null check (char_length(connection) between 1 and 200),
  message text not null check (char_length(message) <= 4000),
  schema jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
  answer jsonb,
  resolved_by uuid references auth.users (id) on delete set null,
  resolved_at timestamptz,
  expires_at timestamptz not null default now() + interval '10 minutes',
  created_at timestamptz not null default now()
);
create index mcp_questions_run_idx on public.mcp_questions (run_id);
alter table public.mcp_questions enable row level security;
-- People who can use the bot see its questions (not the answers: the API reads those for the run).
-- The API records answers after checking who may answer.
create policy mcp_questions_select on public.mcp_questions for select to authenticated
  using (public.can_access_bot(bot_id));
revoke all on public.mcp_questions from anon, authenticated;
grant select (id, org_id, bot_id, run_id, integration_id, connection, message, schema, status,
  resolved_by, resolved_at, expires_at, created_at) on public.mcp_questions to authenticated;
select public.allow_worker('public.mcp_questions');
