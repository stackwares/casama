-- Paging the thread (Fix 10): the app loads the newest messages, then earlier ones as the person
-- scrolls up, instead of the whole branch on every open.
--
-- With no p_limit the function is what it was: the whole branch being shown (every role), oldest
-- first. With p_limit it returns only what people read (user and assistant messages):
--   p_limit            the newest p_limit of them;
--   p_before           the p_limit just before that message (the next page up);
--   p_around           the newest ones back to that message and half a page before it, so a search
--                      hit older than the first page opens with its context. A message that isn't on
--                      the branch being shown falls back to the newest p_limit.
drop function public.conversation_thread(uuid);
create function public.conversation_thread(
  p_conversation uuid,
  p_limit int default null,
  p_before uuid default null,
  p_around uuid default null
)
returns table (
  id uuid, role text, content jsonb, run_id uuid, created_at timestamptz,
  parent_message_id uuid, sibling_index int, sibling_count int, bot_id uuid
)
language sql stable security invoker set search_path = ''
as $$
  with recursive first as (
    select case
      when p_before is null then (select c.head_message_id from public.conversations c where c.id = p_conversation)
      else (select b.parent_message_id from public.messages b where b.id = p_before and b.conversation_id = p_conversation)
    end as id
  ),
  path as (
    select m.*, 0 as depth, (m.role in ('user', 'assistant'))::int as seen
    from public.messages m
    where m.id = (select f.id from first f) and m.conversation_id = p_conversation
    union all
    select m.*, path.depth + 1, path.seen + (m.role in ('user', 'assistant'))::int
    from public.messages m join path on m.id = path.parent_message_id
    where path.depth < 2000
      and (p_limit is null or p_around is not null or path.seen < p_limit)
  ),
  hit as (select h.seen from path h where h.id = p_around)
  select p.id, p.role, p.content, p.run_id, p.created_at, p.parent_message_id,
         (select count(*)::int from public.messages s
           where s.conversation_id = p.conversation_id and s.role = p.role
             and s.parent_message_id is not distinct from p.parent_message_id
             and (s.created_at, s.id) <= (p.created_at, p.id)) as sibling_index,
         (select count(*)::int from public.messages s
           where s.conversation_id = p.conversation_id and s.role = p.role
             and s.parent_message_id is not distinct from p.parent_message_id) as sibling_count,
         p.bot_id
  from path p
  where p_limit is null
     or (p.role in ('user', 'assistant')
         and p.seen <= greatest(p_limit, coalesce((select h.seen from hit h), 0) + p_limit / 2))
  order by p.depth desc
$$;
grant execute on function public.conversation_thread(uuid, int, uuid, uuid) to authenticated, casama_worker;
