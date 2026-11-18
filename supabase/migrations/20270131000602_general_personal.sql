-- D-253, corrected: only a person's own chats with a bot take part in General and topics. Chat-app
-- threads, ticket chats, watchers, linked-bot, A2A, replay and teach chats were counted too
-- (conversations.channel_id is never set; chat apps link threads in channel_threads), so one of
-- them could become someone's General. Chats now say so themselves (`personal`), set by the app's
-- chat, the welcome chat, bot setup, accepted suggestions, calls and General itself.

alter table public.conversations add column personal boolean not null default false;

update public.conversations c set personal = true
where c.kind = 'direct' and c.project_id is null and c.created_by is not null
  and not exists (select 1 from public.channel_threads t where t.conversation_id = c.id)
  and not exists (select 1 from public.watchers w where w.conversation_id = c.id)
  and not exists (select 1 from public.tasks k where k.conversation_id = c.id)
  and coalesce(c.title, '') !~ '^(Linked|A2A|Replay|Ticket|Watching|Teach): ';

create or replace function public.is_personal_chat(c public.conversations)
returns boolean
language sql immutable set search_path = ''
as $$
  select c.personal and c.kind = 'direct' and c.project_id is null and c.created_by is not null
$$;

-- Redo General and topics over personal chats only.
update public.conversations set is_main = false where is_main;
update public.conversations c set parent_conversation_id = null
where c.parent_conversation_id is not null and not public.is_personal_chat(c);

-- General is the chat the person last typed in themselves (routine posts and briefs move
-- last_message_at too), passing over the chats Do it opened before General existed (titled after
-- their suggestion), which become topics.
with ranked as (
  select c.id,
         row_number() over (
           partition by c.bot_id, c.created_by
           order by
             exists (select 1 from public.suggestions s
                     where s.bot_id = c.bot_id and s.user_id = c.created_by and s.status = 'accepted'
                       and left(s.title, 200) = c.title),
             coalesce((select max(r.created_at) from public.runs r
                       where r.conversation_id = c.id and r.created_by = c.created_by
                         and r.trigger in ('chat', 'welcome')),
                      c.created_at) desc,
             c.id) as n
  from public.conversations c
  where public.is_personal_chat(c)
)
update public.conversations c set is_main = true, parent_conversation_id = null
from ranked r where r.id = c.id and r.n = 1;

update public.conversations t set parent_conversation_id = m.id
from public.conversations m
where public.is_personal_chat(t) and not t.is_main
  and m.is_main and m.bot_id = t.bot_id and m.created_by = t.created_by;

-- General made for the worker is a personal chat.
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
    insert into public.conversations (org_id, bot_id, created_by, personal)
    values (p_org, p_bot, p_user, true) returning id into v_id;
  end if;
  return v_id;
end;
$$;

revoke execute on function public.main_conversation(uuid, uuid, uuid) from public, anon, authenticated;
grant execute on function public.main_conversation(uuid, uuid, uuid) to casama_worker;

-- Suggestions made before General existed stay in Needs you; only new ones are posted as cards,
-- so the first sweep after the deploy doesn't fill everyone's General with old ones.
alter table public.suggestions add column post_card boolean not null default true;
update public.suggestions set post_card = false where message_id is null;

-- The worker's minute sweep (postSuggestions, postTopicResults) reads only these rows.
create index suggestions_unposted_idx on public.suggestions (created_at)
  where status = 'pending' and message_id is null and post_card;
create index conversations_posts_result_idx on public.conversations (id)
  where posts_result and parent_conversation_id is not null;

-- A card deleted with its chat (General deleted) isn't posted again into the next General.
create or replace function public.suggestions_card_once()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if old.message_id is not null and new.message_id is null then
    new.post_card := false;
  end if;
  return new;
end;
$$;

drop trigger if exists suggestions_card_once on public.suggestions;
create trigger suggestions_card_once
  before update of message_id on public.suggestions
  for each row execute function public.suggestions_card_once();

revoke execute on function public.suggestions_card_once() from public, anon, authenticated;
