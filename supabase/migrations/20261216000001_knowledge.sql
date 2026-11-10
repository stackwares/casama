-- Knowledge sources (SPEC: Post-v1 roadmap → Knowledge sources; D-125): documents a bot (or the
-- whole workspace) can search, split into chunks with embeddings and full-text vectors.
create table public.knowledge_sources (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  kind text not null check (kind in ('upload', 'website', 'github', 'connection')),
  name text not null check (char_length(name) between 1 and 200),
  -- website: {url, max_pages}; github: {owner, repo, path, ref}; connection: {integration_id, documents: [{tool, args, title}]}
  config jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'syncing', 'ready', 'error')),
  error text,
  documents integer not null default 0,
  chunks integer not null default 0,
  last_synced_at timestamptz,
  next_sync_at timestamptz not null default now(),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index knowledge_sources_due_idx on public.knowledge_sources (next_sync_at) where status <> 'syncing';

-- Uploaded files, kept so the source can be parsed again.
create table public.knowledge_uploads (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.knowledge_sources (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 300),
  content bytea not null check (octet_length(content) <= 25000000),
  created_at timestamptz not null default now()
);

create table public.knowledge_chunks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  source_id uuid not null references public.knowledge_sources (id) on delete cascade,
  doc_ref text not null,
  doc_title text not null,
  -- "page 3" or a heading
  location text,
  url text,
  position integer not null default 0,
  text text not null check (char_length(text) between 1 and 8000),
  embedding extensions.vector(1536),
  tsv tsvector generated always as (to_tsvector('simple', doc_title || ' ' || coalesce(location, '') || ' ' || text)) stored,
  created_at timestamptz not null default now()
);
create index knowledge_chunks_source_idx on public.knowledge_chunks (source_id);
create index knowledge_chunks_tsv_idx on public.knowledge_chunks using gin (tsv);

alter table public.knowledge_sources enable row level security;
alter table public.knowledge_uploads enable row level security;
alter table public.knowledge_chunks enable row level security;
create policy knowledge_sources_select on public.knowledge_sources for select to authenticated
  using (case when bot_id is null then public.is_member(org_id) else public.can_access_bot(bot_id) end);
create policy knowledge_sources_delete on public.knowledge_sources for delete to authenticated
  using (case when bot_id is null then public.has_role(org_id, 'admin') else public.can_manage_bot(bot_id) end);
create policy knowledge_chunks_select on public.knowledge_chunks for select to authenticated
  using (exists (select 1 from public.knowledge_sources s where s.id = source_id));
select public.allow_worker('public.knowledge_sources');
select public.allow_worker('public.knowledge_uploads');
select public.allow_worker('public.knowledge_chunks');

-- Hybrid search (vector, phrase and any-word full text, fused by rank) over a bot's sources and
-- the workspace's shared ones.
create function public.search_knowledge(p_org_id uuid, p_bot_id uuid, p_query text, p_embedding extensions.vector(1536), p_limit integer default 6)
returns table (id uuid, source_id uuid, doc_ref text, doc_title text, location text, url text, text text, score double precision)
language sql stable set search_path = '' as $$
  with scope as (
    select s.id from public.knowledge_sources s
    where s.org_id = p_org_id and (s.bot_id is null or s.bot_id = p_bot_id)
  ),
  vec as (
    select c.id, row_number() over (order by c.embedding operator(extensions.<=>) p_embedding) as r
    from public.knowledge_chunks c
    where c.source_id in (select id from scope) and p_embedding is not null and c.embedding is not null
    order by c.embedding operator(extensions.<=>) p_embedding limit 50
  ),
  fts as (
    select c.id, row_number() over (order by ts_rank_cd(c.tsv, q) desc) as r
    from public.knowledge_chunks c, websearch_to_tsquery('simple', p_query) q
    where c.source_id in (select id from scope) and c.tsv @@ q limit 50
  ),
  words as (
    select c.id, row_number() over (order by ts_rank_cd(c.tsv, q) desc) as r
    from public.knowledge_chunks c,
         to_tsquery('simple', nullif(array_to_string(array(
           select distinct w from unnest(regexp_split_to_array(lower(p_query), '[^[:alnum:]]+')) w
           where char_length(w) > 2), ' | '), '')) q
    where c.source_id in (select id from scope) and c.tsv @@ q limit 50
  ),
  fused as (
    select id, sum(1.0 / (60 + r)) as score
    from (select * from vec union all select * from fts union all select * from words) s group by id
  )
  select c.id, c.source_id, c.doc_ref, c.doc_title, c.location, c.url, c.text, f.score
  from fused f join public.knowledge_chunks c on c.id = f.id
  order by f.score desc limit p_limit;
$$;
