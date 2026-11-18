-- One row per tool call the worker has started (D-268). If the worker restarts while an action is
-- in flight, the workflow engine runs that step again; this row is how the second attempt knows
-- the first one may already have happened, so an action with side effects isn't done twice.
create table public.run_tool_attempts (
  run_id uuid not null references public.runs (id) on delete cascade,
  call_id text not null check (char_length(call_id) between 1 and 200),
  started_at timestamptz not null default now(),
  primary key (run_id, call_id)
);
-- Server only: no policy for people.
alter table public.run_tool_attempts enable row level security;
select public.allow_worker('public.run_tool_attempts');
