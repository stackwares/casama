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

-- Tells a conversation's open chats that a message changed (a call card posted, its summary or a
-- next step written). The worker's role has no grant on the realtime schema, so it goes through
-- this function like every other broadcast. The message carries only the id; joining the topic
-- needs access to the conversation.
create or replace function public.announce_message_change(p_conversation uuid, p_message uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('kind', 'changed', 'message_id', p_message),
    'message_changed',
    'conversation:' || p_conversation::text,
    true
  );
end;
$$;
revoke all on function public.announce_message_change(uuid, uuid) from public, anon, authenticated;
grant execute on function public.announce_message_change(uuid, uuid) to casama_worker;
