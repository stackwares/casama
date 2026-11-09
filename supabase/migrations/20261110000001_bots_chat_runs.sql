-- Phase 1: bots, chat, runs, run events, memory, skills, model keys, usage, quotas, audit log.
-- Every table carries org_id and has RLS enabled in this migration.

create extension if not exists vector with schema extensions;

-- ---------------------------------------------------------------------------
-- Bots
-- ---------------------------------------------------------------------------
create type public.bot_autonomy as enum ('ask_always', 'ask_risky', 'autonomous');
create type public.bot_visibility as enum ('private', 'team');

create table public.bots (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  name text not null check (char_length(name) between 1 and 80),
  avatar_url text,
  persona_md text not null default '' check (char_length(persona_md) <= 20000),
  -- { primary: {credential_id, model}, fallbacks: [{credential_id, model}], cheap: {credential_id, model} }
  model_policy jsonb not null default '{}'::jsonb,
  autonomy public.bot_autonomy not null default 'ask_risky',
  visibility public.bot_visibility not null default 'team',
  default_computer_id uuid,
  -- { per_run_usd, daily_usd }
  budget jsonb not null default '{"per_run_usd": 1, "daily_usd": 10}'::jsonb,
  status text not null default 'idle' check (status in ('idle', 'working', 'waiting', 'disabled')),
  created_at timestamptz not null default now()
);
create index bots_org_id_idx on public.bots (org_id);

-- Bot access: member of the bot's org, and the bot is team-visible or yours.
create or replace function public.can_access_bot(p_bot_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.bots b
    join public.memberships m on m.org_id = b.org_id and m.user_id = (select auth.uid())
    where b.id = p_bot_id and (b.visibility = 'team' or b.created_by = (select auth.uid()))
  );
$$;

-- Bot management: the creator, or an org admin for team bots.
create or replace function public.can_manage_bot(p_bot_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.bots b
    where b.id = p_bot_id
      and public.can_access_bot(b.id)
      and (b.created_by = (select auth.uid()) or (b.visibility = 'team' and public.has_role(b.org_id, 'admin')))
  );
$$;

-- ---------------------------------------------------------------------------
-- Conversations, messages, attachments
-- ---------------------------------------------------------------------------
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  channel_id uuid,
  external_thread_id text,
  title text check (char_length(title) <= 200),
  summary text not null default '',
  -- messages up to and including this time are folded into summary
  summary_through timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  last_message_at timestamptz,
  created_at timestamptz not null default now()
);
create index conversations_bot_id_idx on public.conversations (bot_id, last_message_at desc);

create table public.runs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  conversation_id uuid references public.conversations (id) on delete set null,
  parent_run_id uuid references public.runs (id) on delete set null,
  created_by uuid references auth.users (id) on delete set null,
  trigger text not null default 'chat',
  status text not null default 'queued' check (status in
    ('queued', 'running', 'waiting_approval', 'waiting_takeover', 'completed', 'failed', 'cancelled')),
  budget jsonb not null default '{}'::jsonb,
  tokens_in bigint not null default 0,
  tokens_out bigint not null default 0,
  cost_usd numeric(12, 6) not null default 0,
  last_seq integer not null default 0,
  cancel_requested_at timestamptz,
  cancelled_by uuid,
  started_at timestamptz,
  ended_at timestamptz,
  error jsonb,
  created_at timestamptz not null default now()
);
create index runs_bot_id_idx on public.runs (bot_id, created_at desc);
create index runs_conversation_id_idx on public.runs (conversation_id, created_at);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system', 'tool')),
  author_user_id uuid references auth.users (id) on delete set null,
  -- array of parts: {type:'text', text} | {type:'tool_call', ...} | {type:'attachment', attachment_id}
  content jsonb not null default '[]'::jsonb,
  run_id uuid references public.runs (id) on delete set null,
  created_at timestamptz not null default now()
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  message_id uuid references public.messages (id) on delete cascade,
  storage_path text not null,
  mime text not null,
  size bigint not null check (size >= 0),
  created_at timestamptz not null default now()
);
create index attachments_message_idx on public.attachments (message_id);

-- ---------------------------------------------------------------------------
-- Run events (append-only)
-- ---------------------------------------------------------------------------
create table public.run_events (
  run_id uuid not null references public.runs (id) on delete cascade,
  seq integer not null check (seq > 0),
  org_id uuid not null,
  bot_id uuid not null,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, seq)
);

-- Appends one event with the next gap-free seq for the run. Used by the worker.
create or replace function public.append_run_event(p_run_id uuid, p_type text, p_payload jsonb)
returns public.run_events
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_run public.runs;
  v_event public.run_events;
begin
  update public.runs set last_seq = last_seq + 1 where id = p_run_id returning * into v_run;
  if not found then
    raise exception 'run_not_found' using errcode = 'P0002';
  end if;
  insert into public.run_events (run_id, seq, org_id, bot_id, type, payload)
  values (p_run_id, v_run.last_seq, v_run.org_id, v_run.bot_id, p_type, p_payload)
  returning * into v_event;
  return v_event;
end;
$$;
revoke all on function public.append_run_event(uuid, text, jsonb) from public, anon, authenticated;

-- After commit, every event is broadcast on Realtime (topics run:{id} and bot:{id})
-- and announced with NOTIFY for the API's server-sent events.
create or replace function public.run_events_broadcast()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_msg jsonb := jsonb_build_object(
    'v', 1, 'run_id', new.run_id, 'seq', new.seq, 'ts', to_char(new.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'bot_id', new.bot_id, 'type', new.type, 'payload', new.payload);
begin
  perform realtime.send(v_msg, 'run_event', 'run:' || new.run_id::text, true);
  perform realtime.send(v_msg, 'run_event', 'bot:' || new.bot_id::text, true);
  perform pg_notify('kasama_run_events', new.run_id::text || ':' || new.seq::text);
  return null;
end;
$$;
create trigger run_events_broadcast after insert on public.run_events
for each row execute function public.run_events_broadcast();

create or replace function public.can_access_run(p_run_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.runs r where r.id = p_run_id and public.can_access_bot(r.bot_id));
$$;

-- Users request cancellation; the worker performs it.
create or replace function public.request_run_cancel(p_run_id uuid)
returns public.runs
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_run public.runs;
begin
  if not public.can_access_run(p_run_id) then
    raise exception 'run_not_found' using errcode = 'P0002';
  end if;
  update public.runs
     set cancel_requested_at = coalesce(cancel_requested_at, now()),
         cancelled_by = coalesce(cancelled_by, (select auth.uid()))
   where id = p_run_id
   returning * into v_run;
  update public.runs
     set cancel_requested_at = coalesce(cancel_requested_at, now()), cancelled_by = coalesce(cancelled_by, (select auth.uid()))
   where parent_run_id = p_run_id and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover');
  return v_run;
end;
$$;

-- Realtime Authorization: private broadcast topics run:{id} and bot:{id}.
create or replace function public.realtime_topic_allowed(p_topic text)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_kind text := split_part(p_topic, ':', 1);
  v_id text := split_part(p_topic, ':', 2);
begin
  if v_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  if v_kind = 'run' then return public.can_access_run(v_id::uuid); end if;
  if v_kind = 'bot' then return public.can_access_bot(v_id::uuid); end if;
  return false;
end;
$$;

-- Supabase enables RLS on realtime.messages itself (the table belongs to the Realtime admin role).
create policy kasama_broadcast_read on realtime.messages
  for select to authenticated
  using (realtime.messages.extension = 'broadcast' and public.realtime_topic_allowed((select realtime.topic())));

-- ---------------------------------------------------------------------------
-- Memory and skills
-- ---------------------------------------------------------------------------
create table public.memories (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  kind text not null check (kind in ('fact', 'episode', 'summary', 'preference')),
  content text not null check (char_length(content) between 1 and 8000),
  embedding extensions.vector(1536),
  tsv tsvector generated always as (to_tsvector('simple', content)) stored,
  importance real not null default 0.5 check (importance between 0 and 1),
  pinned boolean not null default false,
  source_run_id uuid references public.runs (id) on delete set null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index memories_bot_idx on public.memories (bot_id);
create index memories_embedding_idx on public.memories using hnsw (embedding extensions.vector_cosine_ops);
create index memories_tsv_idx on public.memories using gin (tsv);

-- Hybrid search: vector similarity + full text, merged with reciprocal rank fusion (k = 60).
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

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  name text not null check (name ~ '^[a-z0-9][a-z0-9_-]{0,62}$'),
  description text not null check (char_length(description) between 1 and 300),
  body_md text not null check (char_length(body_md) <= 50000),
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index skills_name_uniq on public.skills (org_id, coalesce(bot_id, '00000000-0000-0000-0000-000000000000'::uuid), name);

-- ---------------------------------------------------------------------------
-- Model keys, usage, quotas, audit
-- ---------------------------------------------------------------------------
create table public.model_credentials (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  provider text not null check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible')),
  label text not null check (char_length(label) between 1 and 80),
  base_url text,
  vault_secret_id uuid,
  key_hint text,
  created_by uuid references auth.users (id) on delete set null,
  last_tested_at timestamptz,
  last_test_ok boolean,
  created_at timestamptz not null default now()
);
create index model_credentials_org_idx on public.model_credentials (org_id);

create table public.usage_ledger (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete set null,
  run_id uuid references public.runs (id) on delete set null,
  kind text not null check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars')),
  quantity numeric(18, 3) not null,
  cost_usd numeric(12, 6) not null default 0,
  model text,
  created_at timestamptz not null default now()
);
create index usage_ledger_org_time_idx on public.usage_ledger (org_id, created_at);
create index usage_ledger_bot_time_idx on public.usage_ledger (bot_id, created_at);

create table public.quotas (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  period text not null default 'month' check (period in ('day', 'month')),
  max_cost_usd numeric(12, 2),
  max_computer_hours numeric(10, 2),
  max_concurrent_computers integer,
  created_at timestamptz not null default now(),
  unique (org_id, period)
);

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  actor_type text not null check (actor_type in ('user', 'bot', 'system')),
  actor_id uuid,
  action text not null,
  target_type text,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_log_org_time_idx on public.audit_log (org_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.bots enable row level security;
alter table public.conversations enable row level security;
alter table public.runs enable row level security;
alter table public.messages enable row level security;
alter table public.attachments enable row level security;
alter table public.run_events enable row level security;
alter table public.memories enable row level security;
alter table public.skills enable row level security;
alter table public.model_credentials enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.quotas enable row level security;
alter table public.audit_log enable row level security;

-- bots
-- Inline (not can_access_bot) so INSERT ... RETURNING can see the new row in the same statement.
create policy bots_select on public.bots for select to authenticated
  using (public.is_member(org_id) and (visibility = 'team' or created_by = (select auth.uid())));
create policy bots_insert on public.bots for insert to authenticated
  with check (public.is_member(org_id) and created_by = (select auth.uid()));
create policy bots_update on public.bots for update to authenticated
  using (public.can_manage_bot(id)) with check (public.is_member(org_id));
create policy bots_delete on public.bots for delete to authenticated using (public.can_manage_bot(id));

-- conversations
create policy conversations_select on public.conversations for select to authenticated using (public.can_access_bot(bot_id));
create policy conversations_insert on public.conversations for insert to authenticated
  with check (public.can_access_bot(bot_id) and exists (select 1 from public.bots b where b.id = bot_id and b.org_id = conversations.org_id));
create policy conversations_update on public.conversations for update to authenticated
  using (public.can_access_bot(bot_id)) with check (public.can_access_bot(bot_id));
create policy conversations_delete on public.conversations for delete to authenticated using (public.can_access_bot(bot_id));

-- runs: read by bot access; created by the API under the user's session; changed only by the worker
create policy runs_select on public.runs for select to authenticated using (public.can_access_bot(bot_id));
create policy runs_insert on public.runs for insert to authenticated
  with check (public.can_access_bot(bot_id) and created_by = (select auth.uid()) and status = 'queued'
              and exists (select 1 from public.bots b where b.id = bot_id and b.org_id = runs.org_id));

-- messages: users add their own user messages; the worker writes assistant messages
create policy messages_select on public.messages for select to authenticated
  using (exists (select 1 from public.conversations c where c.id = conversation_id and public.can_access_bot(c.bot_id)));
create policy messages_insert on public.messages for insert to authenticated
  with check (role = 'user' and author_user_id = (select auth.uid())
              and exists (select 1 from public.conversations c where c.id = conversation_id and c.org_id = messages.org_id and public.can_access_bot(c.bot_id)));

create policy attachments_select on public.attachments for select to authenticated
  using (exists (select 1 from public.messages m join public.conversations c on c.id = m.conversation_id
                 where m.id = message_id and public.can_access_bot(c.bot_id)));

-- run_events: select only (append through append_run_event by the worker)
create policy run_events_select on public.run_events for select to authenticated using (public.can_access_bot(bot_id));

-- memories: full user control (view, edit, pin, delete)
create policy memories_select on public.memories for select to authenticated using (public.can_access_bot(bot_id));
create policy memories_insert on public.memories for insert to authenticated
  with check (public.can_access_bot(bot_id) and exists (select 1 from public.bots b where b.id = bot_id and b.org_id = memories.org_id));
create policy memories_update on public.memories for update to authenticated
  using (public.can_access_bot(bot_id)) with check (public.can_access_bot(bot_id));
create policy memories_delete on public.memories for delete to authenticated using (public.can_access_bot(bot_id));

-- skills: org-wide skills by admins, bot skills by whoever manages the bot
create policy skills_select on public.skills for select to authenticated
  using (public.is_member(org_id) and (bot_id is null or public.can_access_bot(bot_id)));
create policy skills_write on public.skills for all to authenticated
  using ((bot_id is null and public.has_role(org_id, 'admin')) or (bot_id is not null and public.can_manage_bot(bot_id)))
  with check (
    ((bot_id is null and public.has_role(org_id, 'admin')) or (bot_id is not null and public.can_manage_bot(bot_id)))
    and (bot_id is null or exists (select 1 from public.bots b where b.id = bot_id and b.org_id = skills.org_id)));

-- model_credentials: metadata readable by members; keys live only in Vault; writes go through the API
create policy model_credentials_select on public.model_credentials for select to authenticated using (public.is_member(org_id));
create policy model_credentials_delete on public.model_credentials for delete to authenticated using (public.has_role(org_id, 'admin'));

-- usage and quotas
create policy usage_ledger_select on public.usage_ledger for select to authenticated using (public.is_member(org_id));
create policy quotas_select on public.quotas for select to authenticated using (public.is_member(org_id));
create policy quotas_write on public.quotas for all to authenticated
  using (public.has_role(org_id, 'admin')) with check (public.has_role(org_id, 'admin'));

-- audit log: admins read; written only by the server
create policy audit_log_select on public.audit_log for select to authenticated using (public.has_role(org_id, 'admin'));

-- vault_secret_id is a pointer only: authenticated users have no access to the vault schema.

grant execute on function public.can_access_bot(uuid), public.can_manage_bot(uuid), public.can_access_run(uuid),
  public.request_run_cancel(uuid), public.realtime_topic_allowed(text) to authenticated;
