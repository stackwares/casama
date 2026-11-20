-- Decision models (docs/DECISION-MODEL-PLAN.md, D-452): every answer a decision model gives, in
-- shadow or acting, next to what really happened. Question names and probabilities only, never the
-- text that was judged. Read through the owner's admin API and written by the worker; workspace
-- members have no access. Rows go after 90 days, and with their workspace.

create table public.decision_log (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  -- What the decision was about, when it isn't the run itself (a suggestion, a watcher).
  subject_id uuid,
  use text not null check (use in ('scan_gate', 'reply_check', 'push_score', 'tool_gate', 'long_run', 'effort', 'watcher_gate')),
  model text not null check (char_length(model) between 1 and 200),
  shadow boolean not null,
  -- {question: probability} for yes/no, {question: {choice, p}} for a choice; {} when the call failed.
  answers jsonb not null default '{}'::jsonb,
  -- What the code did: skipped, ran, flagged, asked, held, lowered, none.
  action text not null default 'none' check (char_length(action) <= 40),
  -- Why there were no answers: timeout, http_429, refused... Null when it answered.
  error text check (char_length(error) <= 200),
  -- The label, filled when it is known: in the run, or by the worker's labelling sweep.
  outcome jsonb,
  input_tokens integer not null default 0 check (input_tokens >= 0),
  cost_usd numeric(12, 8) not null default 0 check (cost_usd >= 0),
  latency_ms integer not null default 0 check (latency_ms >= 0),
  created_at timestamptz not null default now()
);
create index decision_log_use_idx on public.decision_log (use, created_at desc);
create index decision_log_run_idx on public.decision_log (run_id) where run_id is not null;
create index decision_log_subject_idx on public.decision_log (subject_id) where subject_id is not null;

alter table public.decision_log enable row level security;
select public.allow_worker('public.decision_log');
revoke all on public.decision_log from anon, authenticated;
