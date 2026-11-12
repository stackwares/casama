-- Chat media (D-205). Images and videos a bot generates are kept here, so they show under the
-- reply even when the bot has no computer (or it is asleep or gone). The bot's computer still
-- gets its own copy in media/ when there is one. Served by the API at /v1/media/{id} to members
-- of the workspace, with byte ranges for video players.
create table public.chat_media (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid,
  run_id uuid,
  conversation_id uuid,
  name text,
  content_type text not null,
  bytes bytea not null,
  size int not null check (size between 1 and 52428800),
  width int,
  height int,
  duration_s real,
  created_at timestamptz not null default now()
);
create index chat_media_run_id_idx on public.chat_media (run_id);
create index chat_media_org_id_idx on public.chat_media (org_id);
alter table public.chat_media enable row level security;
-- No policies: the API serves it and the worker (where tools run) writes it.
select public.allow_worker('public.chat_media');
