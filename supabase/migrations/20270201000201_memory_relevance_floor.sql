-- Memory recall only by meaning was always filled to the limit, however unrelated (D-269): a
-- memory found only by its vector must now be at least loosely related (cosine distance under
-- 0.75, about 0.25 similarity; unrelated sentences sit near 0.1 on common embedding models).
-- Word matches are unchanged.
create or replace function public.search_memories(
  p_bot_id uuid, p_query text, p_embedding extensions.vector(1536), p_limit integer default 8
)
returns table (id uuid, kind text, content text, pinned boolean, importance real, score double precision)
language sql stable set search_path = ''
as $$
  with vec as (
    select m.id, row_number() over (order by m.embedding operator(extensions.<=>) p_embedding) as r
    from public.memories m
    where m.bot_id = p_bot_id and p_embedding is not null and m.embedding is not null
      and m.embedding operator(extensions.<=>) p_embedding < 0.75
    order by m.embedding operator(extensions.<=>) p_embedding
    limit 50
  ),
  fts as (
    select m.id, row_number() over (order by ts_rank_cd(m.tsv, q) desc) as r
    from public.memories m, websearch_to_tsquery('simple', p_query) q
    where m.bot_id = p_bot_id and m.tsv @@ q
    limit 50
  ),
  words as (
    -- OR of the query's words, so natural questions still match stored facts
    select m.id, row_number() over (order by ts_rank_cd(m.tsv, q) desc) as r
    from public.memories m,
         to_tsquery('simple', nullif(array_to_string(array(
           select distinct w from unnest(regexp_split_to_array(lower(p_query), '[^[:alnum:]]+')) w
           where char_length(w) > 2), ' | '), '')) q
    where m.bot_id = p_bot_id and m.tsv @@ q
    limit 50
  ),
  fused as (
    select id, sum(1.0 / (60 + r)) as score
    from (select * from vec union all select * from fts union all select * from words) s
    group by id
  )
  select m.id, m.kind, m.content, m.pinned, m.importance, f.score
  from fused f join public.memories m on m.id = f.id
  order by f.score desc, m.importance desc
  limit p_limit;
$$;
