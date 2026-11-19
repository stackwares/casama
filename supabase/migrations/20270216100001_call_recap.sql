-- The call card (docs/CALL-RECAP-PLAN.md): each live call knows its card message, so the summary
-- job and next steps can update it, and whether its summary is still to be written. The worker's
-- minute tick picks up summaries left pending (a call ended by the sweep or a limit, or a summary
-- job that never started).
alter table public.live_calls
  add column if not exists recap_message_id uuid references public.messages (id) on delete set null,
  add column if not exists summary_state text
    check (summary_state in ('pending', 'ready', 'skipped', 'failed'));

create index if not exists live_calls_summary_pending_idx on public.live_calls (ended_at)
  where summary_state = 'pending';
