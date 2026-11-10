-- Search (SPEC: Post-v1 roadmap → Search; D-103). Full-text search over message text plus trigram
-- matching for names, through a security-invoker function so RLS keeps results in the caller's
-- workspaces and bots. Files are searched separately, on computers that are awake.

create extension if not exists pg_trgm with schema extensions;

-- The text parts of a message, for indexing (tool calls and attachments are left out).
create or replace function public.message_plain_text(p_content jsonb)
returns text
language sql immutable parallel safe set search_path = ''
as $$
  select coalesce(string_agg(p ->> 'text', ' '), '')
  from jsonb_array_elements(case when jsonb_typeof(p_content) = 'array' then p_content else '[]'::jsonb end) p
  where p ->> 'type' = 'text'
$$;

alter table public.messages add column tsv tsvector
  generated always as (to_tsvector('simple', left(public.message_plain_text(content), 100000))) stored;
create index messages_tsv_idx on public.messages using gin (tsv);
create index conversations_title_trgm on public.conversations using gin (title extensions.gin_trgm_ops);
create index skills_name_trgm on public.skills using gin (name extensions.gin_trgm_ops);
create index routines_name_trgm on public.routines using gin (name extensions.gin_trgm_ops);
create index tasks_title_trgm on public.tasks using gin (title extensions.gin_trgm_ops);

-- Up to p_limit results per kind, best first. Security invoker: callers see only what RLS allows.
create or replace function public.search_workspace(p_org uuid, p_query text, p_limit int default 8)
returns table (
  kind text, id uuid, title text, snippet text, bot_id uuid, conversation_id uuid,
  created_at timestamptz, rank real
)
language plpgsql stable security invoker set search_path = ''
as $$
declare
  v_q text := btrim(coalesce(p_query, ''));
  v_ts tsquery;
  v_like text;
  v_n int := least(greatest(coalesce(p_limit, 8), 1), 25);
begin
  if char_length(v_q) < 2 then return; end if;
  v_ts := websearch_to_tsquery('simple', v_q);
  v_like := '%' || replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  return query
  (select 'message'::text, m.id, coalesce(c.title, ''),
          ts_headline('simple', public.message_plain_text(m.content), v_ts,
                      'MaxFragments=1, MaxWords=24, MinWords=8, StartSel=«, StopSel=»'),
          c.bot_id, c.id, m.created_at, ts_rank(m.tsv, v_ts)
   from public.messages m join public.conversations c on c.id = m.conversation_id
   where m.org_id = p_org and m.role in ('user', 'assistant') and m.tsv @@ v_ts
   order by ts_rank(m.tsv, v_ts) desc, m.created_at desc limit v_n)
  union all
  (select 'chat', c.id, coalesce(c.title, ''), ''::text, c.bot_id, c.id,
          coalesce(c.last_message_at, c.created_at), extensions.similarity(c.title, v_q)
   from public.conversations c
   where c.org_id = p_org and (c.title ilike v_like or c.title operator(extensions.%) v_q)
   order by extensions.similarity(c.title, v_q) desc limit v_n)
  union all
  (select 'memory', mm.id, left(mm.content, 120),
          ts_headline('simple', mm.content, v_ts, 'MaxFragments=1, MaxWords=24, MinWords=8, StartSel=«, StopSel=»'),
          mm.bot_id, null::uuid, mm.created_at, ts_rank(mm.tsv, v_ts)
   from public.memories mm
   where mm.org_id = p_org and (mm.tsv @@ v_ts or mm.content ilike v_like)
   order by ts_rank(mm.tsv, v_ts) desc limit v_n)
  union all
  (select 'skill', s.id, s.name, s.description, s.bot_id, null::uuid, s.created_at,
          greatest(extensions.similarity(s.name, v_q), case when s.description ilike v_like then 0.5 else 0 end)::real
   from public.skills s
   where s.org_id = p_org and (s.name ilike v_like or s.name operator(extensions.%) v_q or s.description ilike v_like
                               or to_tsvector('simple', s.body_md) @@ v_ts)
   order by 8 desc limit v_n)
  union all
  (select 'routine', r.id, r.name, left(r.instructions_md, 160), r.bot_id, r.conversation_id, r.created_at,
          extensions.similarity(r.name, v_q)
   from public.routines r
   where r.org_id = p_org and (r.name ilike v_like or r.name operator(extensions.%) v_q or r.instructions_md ilike v_like)
   order by 8 desc limit v_n)
  union all
  (select 'ticket', t.id, t.title, left(t.details_md, 160), t.assignee_bot_id, t.conversation_id, t.created_at,
          extensions.similarity(t.title, v_q)
   from public.tasks t
   where t.org_id = p_org and (t.title ilike v_like or t.title operator(extensions.%) v_q or t.details_md ilike v_like)
   order by 8 desc limit v_n);
end;
$$;
grant execute on function public.search_workspace(uuid, text, int) to authenticated, kasama_worker;
