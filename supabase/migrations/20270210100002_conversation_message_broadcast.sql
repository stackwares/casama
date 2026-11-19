-- A person's message is announced on the conversation's topic (D-413), like a run starting is
-- (D-224). A message sent from the person's other device while the bot works joins the run that
-- is working, so no run starts and the first device never learned of it: it showed its own
-- messages and the reply, with the other device's message missing until the chat was reopened.
-- Its own event, so apps from before it (which reload on conversation_activity) ignore it. The
-- message carries only the id; joining the topic needs access to the conversation.
create or replace function public.broadcast_conversation_message()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('kind', 'message', 'message_id', new.id),
    'conversation_message',
    'conversation:' || new.conversation_id::text,
    true
  );
  return null;
end;
$$;

drop trigger if exists messages_broadcast_message on public.messages;
create trigger messages_broadcast_message
  after insert on public.messages
  for each row when (new.role = 'user')
  execute function public.broadcast_conversation_message();

revoke execute on function public.broadcast_conversation_message() from public, anon, authenticated;
