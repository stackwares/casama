-- Teach a task by showing it (SPEC: Post-v1 roadmap → Teach a task; D-120). While a person holds
-- control, a recording keeps each step (the input, an accessibility snapshot, a screenshot and the
-- browser URL), the one exception to the take-control privacy rule. Stopping turns it into a draft
-- skill the person edits and saves.
create table public.teach_sessions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  computer_id uuid not null references public.computers (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'recording' check (status in ('recording', 'drafting', 'drafted', 'saved', 'cancelled', 'failed')),
  run_id uuid references public.runs (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  -- {name, description, body, inputs: [{name, description, secret}], checks: [text]}
  draft jsonb,
  skill_id uuid references public.skills (id) on delete set null,
  started_at timestamptz not null default now(),
  stopped_at timestamptz
);
create index teach_sessions_user_idx on public.teach_sessions (user_id, started_at desc);
create unique index teach_sessions_recording_idx on public.teach_sessions (computer_id) where status = 'recording';

create table public.teach_steps (
  session_id uuid not null references public.teach_sessions (id) on delete cascade,
  seq integer not null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null check (kind in ('click', 'type', 'key', 'scroll')),
  x integer,
  y integer,
  button smallint,
  -- Typed text; null for password fields and fields marked secret (secret_name holds the input).
  text text check (char_length(text) <= 2000),
  key text check (char_length(key) <= 40),
  dx integer,
  dy integer,
  secret_name text check (secret_name ~ '^[A-Z][A-Z0-9_]{0,63}$'),
  password boolean not null default false,
  url text check (char_length(url) <= 2000),
  snapshot text check (char_length(snapshot) <= 20000),
  screenshot bytea check (octet_length(screenshot) <= 3000000),
  created_at timestamptz not null default now(),
  primary key (session_id, seq)
);

alter table public.teach_sessions enable row level security;
alter table public.teach_steps enable row level security;
-- Recordings belong to the person who recorded them.
create policy teach_sessions_select on public.teach_sessions for select to authenticated using (user_id = (select auth.uid()));
create policy teach_steps_select on public.teach_steps for select to authenticated using (
  exists (select 1 from public.teach_sessions s where s.id = session_id and s.user_id = (select auth.uid())));
select public.allow_worker('public.teach_sessions');
select public.allow_worker('public.teach_steps');
