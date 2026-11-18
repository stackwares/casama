-- Edit and resend (SPEC: Post-v1 roadmap → App polish; D-108). Messages form a tree: each points at
-- the message before it in its branch, and a conversation shows the branch ending at its head.
-- Editing a message adds a sibling (same parent) and reruns from there; the old branch stays.

alter table public.messages add column parent_message_id uuid references public.messages (id) on delete set null;
alter table public.conversations add column head_message_id uuid references public.messages (id) on delete set null;
create index messages_parent_idx on public.messages (parent_message_id);

-- Existing conversations are one straight branch.
update public.messages m set parent_message_id = p.prev
from (select id, lag(id) over (partition by conversation_id order by created_at, id) as prev from public.messages) p
where p.id = m.id and p.prev is not null;
update public.conversations c set head_message_id = (
  select id from public.messages m where m.conversation_id = c.id order by created_at desc, id desc limit 1);

-- New messages continue the current branch unless they say where they go (edits, a run's reply
-- after the person switched branches). `casama.branch_root` = 'on' starts a new first message.
create or replace function public.messages_branch()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.parent_message_id is null and coalesce(current_setting('casama.branch_root', true), '') <> 'on' then
    select head_message_id into new.parent_message_id from public.conversations where id = new.conversation_id;
  end if;
  return new;
end;
$$;
create trigger messages_branch before insert on public.messages
  for each row execute function public.messages_branch();

create or replace function public.messages_set_head()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- Only when the message continues the branch being shown (a reply arriving after the person
  -- switched branches doesn't pull them back; edits set the head themselves).
  update public.conversations set head_message_id = new.id
  where id = new.conversation_id
    and (head_message_id is null or head_message_id is not distinct from new.parent_message_id);
  return null;
end;
$$;
create trigger messages_set_head after insert on public.messages
  for each row execute function public.messages_set_head();

-- The branch ending at the conversation's head, oldest first, with each message's place among its
-- siblings (for the < 2/3 > arrows). Security invoker: RLS applies.
create or replace function public.conversation_thread(p_conversation uuid)
returns table (
  id uuid, role text, content jsonb, run_id uuid, created_at timestamptz,
  parent_message_id uuid, sibling_index int, sibling_count int
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
             and s.parent_message_id is not distinct from p.parent_message_id) as sibling_count
  from path p order by p.depth desc
$$;
grant execute on function public.conversation_thread(uuid) to authenticated, casama_worker;

-- The newest leaf under a message: where switching to that branch lands.
create or replace function public.branch_leaf(p_message uuid)
returns uuid
language sql stable security invoker set search_path = ''
as $$
  with recursive down as (
    select p_message as id, 0 as depth
    union all
    select (select c.id from public.messages c where c.parent_message_id = down.id order by c.created_at desc, c.id desc limit 1), depth + 1
    from down where down.id is not null and depth < 2000
  )
  select id from down where id is not null order by depth desc limit 1
$$;
grant execute on function public.branch_leaf(uuid) to authenticated, casama_worker;
