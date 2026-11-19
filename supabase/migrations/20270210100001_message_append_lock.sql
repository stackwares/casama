-- Messages added to one conversation at the same moment (D-413). The branch trigger read the
-- conversation's head without a lock, so two inserts in flight (a second device of the same
-- account, a routine firing while the bot replies, two bots finishing together in a group chat)
-- both took the same parent. The first became the head; the second stayed a sibling off the shown
-- branch, and so did every reply under it: the message and its answer were missing from the chat.
--
-- Reading the head now locks the conversation's row, so appends go one after another and each
-- continues from the one before. "No key update" is the lock an update of the head takes anyway;
-- it doesn't block the foreign-key checks of runs and messages being inserted at the same time
-- (a plain "for update" would, and two senders could deadlock on it).
create or replace function public.messages_branch()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.parent_message_id is null and coalesce(current_setting('casama.branch_root', true), '') <> 'on' then
    select head_message_id into new.parent_message_id from public.conversations
    where id = new.conversation_id for no key update;
  end if;
  return new;
end;
$$;
