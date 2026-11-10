-- Group chats (SPEC: Post-v1 roadmap → Group chats; D-118): 2 to 10 bots in one conversation.
-- conversations.bot_id stays the lead; conversation_bots lists every bot with its role. A group
-- chat is visible only to people who can see every bot in it.

alter table public.conversations add column kind text not null default 'direct' check (kind in ('direct', 'group'));

create table public.conversation_bots (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  role text not null default 'member' check (role in ('lead', 'member')),
  position integer not null default 0,
  primary key (conversation_id, bot_id)
);
create index conversation_bots_bot_idx on public.conversation_bots (bot_id);

-- Which bot wrote an assistant message (group chats show it); which message a run answers (several
-- bots answer one message); how many bot-to-bot hops led to a run.
alter table public.messages add column bot_id uuid references public.bots (id) on delete set null;
alter table public.runs add column trigger_message_id uuid references public.messages (id) on delete set null;
alter table public.runs add column hop integer not null default 0;

create or replace function public.can_access_conversation(p_conversation uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
    where c.id = p_conversation and public.can_access_bot(c.bot_id)
      and not exists (select 1 from public.conversation_bots cb where cb.conversation_id = c.id and not public.can_access_bot(cb.bot_id)))
$$;
grant execute on function public.can_access_conversation(uuid) to authenticated, kasama_worker;

-- Only the group's bots (not the conversation row), so a new conversation is visible as it's inserted.
create or replace function public.group_bots_visible(p_conversation uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select not exists (select 1 from public.conversation_bots cb where cb.conversation_id = p_conversation and not public.can_access_bot(cb.bot_id))
$$;
grant execute on function public.group_bots_visible(uuid) to authenticated, kasama_worker;

drop policy conversations_select on public.conversations;
create policy conversations_select on public.conversations for select to authenticated
  using (public.can_access_bot(bot_id) and public.group_bots_visible(id));
drop policy messages_select on public.messages;
create policy messages_select on public.messages for select to authenticated using (public.can_access_conversation(conversation_id));
drop policy messages_insert on public.messages;
create policy messages_insert on public.messages for insert to authenticated
  with check (role = 'user' and author_user_id = (select auth.uid())
              and exists (select 1 from public.conversations c where c.id = conversation_id and c.org_id = messages.org_id)
              and public.can_access_conversation(conversation_id));

alter table public.conversation_bots enable row level security;
create policy conversation_bots_select on public.conversation_bots for select to authenticated using (public.can_access_conversation(conversation_id));
create policy conversation_bots_insert on public.conversation_bots for insert to authenticated
  with check (public.can_access_bot(bot_id) and exists (select 1 from public.bots b where b.id = bot_id and b.org_id = conversation_bots.org_id));
select public.allow_worker('public.conversation_bots');

-- The thread now says which bot wrote each message (group chats show it).
drop function public.conversation_thread(uuid);
create function public.conversation_thread(p_conversation uuid)
returns table (
  id uuid, role text, content jsonb, run_id uuid, created_at timestamptz,
  parent_message_id uuid, sibling_index int, sibling_count int, bot_id uuid
)
language sql stable security invoker set search_path = ''
as $$
  with recursive path as (
    select m.*, 0 as depth from public.messages m
    where m.id = (select head_message_id from public.conversations where id = p_conversation)
    union all
    select m.*, path.depth + 1 from public.messages m join path on m.id = path.parent_message_id
    where path.depth < 2000
  )
  select p.id, p.role, p.content, p.run_id, p.created_at, p.parent_message_id,
         (select count(*)::int from public.messages s
           where s.conversation_id = p.conversation_id and s.role = p.role
             and s.parent_message_id is not distinct from p.parent_message_id
             and (s.created_at, s.id) <= (p.created_at, p.id)) as sibling_index,
         (select count(*)::int from public.messages s
           where s.conversation_id = p.conversation_id and s.role = p.role
             and s.parent_message_id is not distinct from p.parent_message_id) as sibling_count,
         p.bot_id
  from path p order by p.depth desc
$$;
grant execute on function public.conversation_thread(uuid) to authenticated, kasama_worker;
