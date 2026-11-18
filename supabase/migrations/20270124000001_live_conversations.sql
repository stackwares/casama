-- D-224: an open chat follows what happens in it from any device. When a run starts in a
-- conversation (someone sent a message from another phone, a routine woke the bot, a group member
-- was @mentioned), one small message goes out on the conversation's private topic; open apps then
-- reload the thread and follow the run. The message carries only ids, and joining the topic needs
-- access to the conversation (can_access_conversation), the same check as reading its messages.

create or replace function public.realtime_topic_allowed(p_topic text)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_kind text := split_part(p_topic, ':', 1);
  v_id text := split_part(p_topic, ':', 2);
begin
  if v_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  if v_kind = 'run' then return public.can_access_run(v_id::uuid); end if;
  if v_kind = 'bot' then return public.can_access_bot(v_id::uuid); end if;
  if v_kind = 'user' then return v_id::uuid = (select auth.uid()); end if;
  if v_kind = 'org' then return public.is_member(v_id::uuid); end if;
  if v_kind = 'conversation' then return public.can_access_conversation(v_id::uuid); end if;
  return false;
end;
$$;

create or replace function public.broadcast_conversation_run()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.conversation_id is null then
    return null;
  end if;
  perform realtime.send(
    jsonb_build_object('kind', 'run', 'run_id', new.id),
    'conversation_activity',
    'conversation:' || new.conversation_id::text,
    true
  );
  return null;
end;
$$;

drop trigger if exists runs_broadcast_conversation on public.runs;
create trigger runs_broadcast_conversation
  after insert on public.runs
  for each row execute function public.broadcast_conversation_run();

revoke execute on function public.broadcast_conversation_run() from public, anon, authenticated;
