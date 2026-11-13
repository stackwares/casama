-- D-253: one General conversation per person per bot; every other direct chat with that bot is a
-- topic under it. Proactive messages, briefs and routine results land in General; accepted
-- suggestions open topics, which post their result back.

alter table public.conversations
  add column is_main boolean not null default false,
  add column parent_conversation_id uuid references public.conversations (id) on delete set null,
  -- No foreign key: messages already reference conversations, and a deleted anchor only loses the link.
  add column anchor_message_id uuid,
  -- Topics opened for a piece of work (an accepted suggestion) post their result back to General;
  -- result_run_id is the last run posted (no foreign key, for the same reason as the anchor).
  add column posts_result boolean not null default false,
  add column result_run_id uuid;

create index conversations_parent_idx on public.conversations (parent_conversation_id)
  where parent_conversation_id is not null;

-- The message a suggestion was posted as in General (null until posted).
alter table public.suggestions
  add column message_id uuid references public.messages (id) on delete set null;

-- Which direct chats take part: a person's own chats with a bot in the app (not a chat app's
-- thread, not a project's or a group chat).
create or replace function public.is_personal_chat(c public.conversations)
returns boolean
language sql immutable set search_path = ''
as $$
  select c.kind = 'direct' and c.channel_id is null and c.project_id is null and c.created_by is not null
$$;

-- Backfill: each person's latest chat with a bot becomes General, the rest become its topics.
with ranked as (
  select id, bot_id, created_by,
         row_number() over (partition by bot_id, created_by
                            order by coalesce(last_message_at, created_at) desc, id) as n
  from public.conversations c
  where public.is_personal_chat(c)
)
update public.conversations c set is_main = true
from ranked r where r.id = c.id and r.n = 1;

update public.conversations t set parent_conversation_id = m.id
from public.conversations m
where public.is_personal_chat(t) and not t.is_main
  and m.is_main and m.bot_id = t.bot_id and m.created_by = t.created_by;

create unique index conversations_one_main on public.conversations (bot_id, created_by) where is_main;

-- A new personal chat: General when the person has none with this bot yet, else a topic under it.
create or replace function public.conversations_assign_main()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_main uuid;
begin
  if not public.is_personal_chat(new) then
    new.is_main := false;
    return new;
  end if;
  -- One at a time per person and bot, so two chats made at once can't both become General.
  perform pg_advisory_xact_lock(hashtextextended(new.bot_id::text || new.created_by::text, 0));
  select id into v_main from public.conversations
  where bot_id = new.bot_id and created_by = new.created_by and is_main;
  if v_main is null then
    new.is_main := true;
    new.parent_conversation_id := null;
  else
    new.is_main := false;
    new.parent_conversation_id := coalesce(new.parent_conversation_id, v_main);
  end if;
  return new;
end;
$$;

drop trigger if exists conversations_assign_main on public.conversations;
create trigger conversations_assign_main
  before insert on public.conversations
  for each row execute function public.conversations_assign_main();

-- General deleted: the person's latest remaining chat with the bot takes its place.
create or replace function public.conversations_replace_main()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_next uuid;
begin
  if not old.is_main then
    return null;
  end if;
  select id into v_next from public.conversations c
  where c.bot_id = old.bot_id and c.created_by = old.created_by and public.is_personal_chat(c)
  order by coalesce(c.last_message_at, c.created_at) desc, c.id limit 1;
  if v_next is not null then
    update public.conversations set is_main = true, parent_conversation_id = null where id = v_next;
    update public.conversations set parent_conversation_id = v_next
    where bot_id = old.bot_id and created_by = old.created_by and id <> v_next
      and (parent_conversation_id is null or parent_conversation_id = old.id)
      and kind = 'direct' and channel_id is null and project_id is null;
  end if;
  return null;
end;
$$;

drop trigger if exists conversations_replace_main on public.conversations;
create trigger conversations_replace_main
  after delete on public.conversations
  for each row execute function public.conversations_replace_main();

-- The person's General with a bot, made when they have none (the worker posts proactive messages there).
create or replace function public.main_conversation(p_org uuid, p_bot uuid, p_user uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  select id into v_id from public.conversations
  where bot_id = p_bot and created_by = p_user and is_main;
  if v_id is null then
    insert into public.conversations (org_id, bot_id, created_by)
    values (p_org, p_bot, p_user) returning id into v_id;
  end if;
  return v_id;
end;
$$;

revoke execute on function public.main_conversation(uuid, uuid, uuid) from public, anon, authenticated;
grant execute on function public.main_conversation(uuid, uuid, uuid) to casama_worker;
revoke execute on function public.conversations_assign_main() from public, anon, authenticated;
revoke execute on function public.conversations_replace_main() from public, anon, authenticated;

-- A message posted without a run (a suggestion card, a topic's result): open apps reload the
-- thread, like they do when a run starts (D-224).
create or replace function public.broadcast_conversation_post()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.run_id is not null or new.role <> 'assistant' then
    return null;
  end if;
  perform realtime.send(
    jsonb_build_object('kind', 'post', 'message_id', new.id),
    'conversation_activity',
    'conversation:' || new.conversation_id::text,
    true
  );
  return null;
end;
$$;

drop trigger if exists messages_broadcast_post on public.messages;
create trigger messages_broadcast_post
  after insert on public.messages
  for each row execute function public.broadcast_conversation_post();

revoke execute on function public.broadcast_conversation_post() from public, anon, authenticated;
