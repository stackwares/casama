-- Call guardrails (D-426): limits on live calls and on the rings bots start.
--
-- live_calls: the relay ends a call paid from credits at its maximum length or when the workspace's
-- credits, daily limit, monthly quota or the bot's daily budget run out. It warns the bot about a
-- minute before (limit_warned_at), asks for a goodbye (limit_wrap_at) and then closes the stream
-- (limit_closed_at), after which the relay takes no reconnect. The worker also ends any call that
-- runs past its maximum length, relayed or not.
alter table public.live_calls
  add column limit_reason text check (limit_reason in ('max_length', 'credits', 'daily_cap', 'quota', 'bot_budget')),
  add column limit_warned_at timestamptz,
  add column limit_wrap_at timestamptz,
  add column limit_closed_at timestamptz;

alter table public.live_calls drop constraint if exists live_calls_end_reason_check;
alter table public.live_calls add constraint live_calls_end_reason_check
  check (end_reason in ('hung_up', 'silent', 'max_length', 'credits', 'daily_cap', 'quota', 'bot_budget'));

-- voice_calls: a ring a limit stopped is kept, with why, so the next try knows a notification
-- already went out. Such rows are never 'ringing' and don't count toward the ring limits.
alter table public.voice_calls
  add column blocked text check (blocked in ('may_not_call', 'cooldown', 'daily_cap'));
create index voice_calls_bot_user_idx on public.voice_calls (bot_id, user_id, created_at desc);

-- Each person decides per bot whether it may phone them (default yes).
alter table public.user_bot_settings add column may_call boolean not null default true;
