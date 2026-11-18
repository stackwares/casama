-- Live calls that keep going (D-327): the server's record of each in-app live call, so a call that
-- dies with the app (swiped away, crashed, the phone off) still ends, keeps its transcript and is
-- billed its real length. voice_calls stays the phone-style ring a bot starts (D-135).
--
-- The API writes these rows; the worker's minute tick ends calls with no heartbeat for 2 minutes.
-- People can read their own calls; nobody writes them from the app directly.
create table public.live_calls (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  -- A phone-style ring that was answered (D-135), when the call started that way.
  phone_call_id uuid references public.voice_calls (id) on delete set null,
  provider text not null default 'gemini' check (provider in ('gemini', 'openai')),
  -- Paid from the workspace's credits on the server's key (D-248); fixed when the call starts.
  billable boolean not null default false,
  started_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  -- Gemini Live's token counts so far, from the last heartbeat.
  usage jsonb,
  -- Runs start_task began on this call (stop_task stops them, D-327 Phase 2).
  task_run_ids uuid[] not null default '{}',
  ended_at timestamptz,
  end_reason text check (end_reason in ('hung_up', 'silent')),
  seconds integer check (seconds >= 0)
);
create index live_calls_user_idx on public.live_calls (user_id, started_at desc);
create index live_calls_open_idx on public.live_calls (last_seen_at) where ended_at is null;
alter table public.live_calls enable row level security;
create policy live_calls_select on public.live_calls for select to authenticated
  using (user_id = (select auth.uid()) and public.is_member(org_id));
select public.allow_worker('public.live_calls');

-- Turns already saved for a call, by the app's turn id, so a retried post never saves one twice.
create table public.live_call_turns (
  live_call_id uuid not null references public.live_calls (id) on delete cascade,
  turn_id text not null check (char_length(turn_id) between 1 and 100),
  message_id uuid references public.messages (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (live_call_id, turn_id)
);
alter table public.live_call_turns enable row level security;
select public.allow_worker('public.live_call_turns');
