-- The Library (docs/LIBRARY-PLAN.md, Phase 1; D-274): one row per thing a bot made, pointing at
-- the bytes where they already live (pages, chat_media). Files kept off a computer come in Phase 3.

create table public.creations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete set null,
  -- The person it was made for: the conversation's starter, or whoever started the run.
  made_for uuid references auth.users (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  message_id uuid,
  run_id uuid references public.runs (id) on delete set null,
  kind text not null check (kind in ('page', 'image', 'video', 'audio', 'document', 'file')),
  -- The bot's word for it (Site, Game, Report…), at most 24 characters.
  label text check (char_length(label) between 1 and 24),
  title text not null check (char_length(title) between 1 and 200),
  page_id uuid unique references public.pages (id) on delete cascade,
  media_id uuid unique references public.chat_media (id) on delete cascade,
  blob_key text,
  computer_id uuid,
  origin_path text,
  mime text,
  size bigint not null default 0 check (size >= 0),
  width int,
  height int,
  duration_s real,
  cover_key text,
  cover_w int,
  cover_h int,
  version int not null default 1,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index creations_org_created_idx on public.creations (org_id, created_at desc);
create index creations_org_kind_idx on public.creations (org_id, kind, created_at desc);
create index creations_bot_idx on public.creations (bot_id, created_at desc);
create index creations_conversation_idx on public.creations (conversation_id);
create index creations_run_idx on public.creations (run_id);
create index creations_deleted_idx on public.creations (deleted_at) where deleted_at is not null;
create extension if not exists pg_trgm with schema extensions;
create index creations_title_trgm_idx on public.creations using gin (title extensions.gin_trgm_ops);

-- Per-person pins and "recently opened".
create table public.creation_marks (
  user_id uuid not null references auth.users (id) on delete cascade,
  creation_id uuid not null references public.creations (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  pinned_at timestamptz,
  last_opened_at timestamptz,
  primary key (user_id, creation_id)
);
create index creation_marks_creation_idx on public.creation_marks (creation_id);

-- Bytes the Library holds per workspace (counted in Phase 1; capped in Phase 3).
alter table public.organizations add column if not exists storage_bytes bigint not null default 0;

-- Who may see a creation: a page follows its own visibility; anything else follows the chat it
-- was made in (private conversations stay private, D-091), then the person it was made for.
create function public.can_view_creation(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.creations c
    where c.id = p_id and case
      when c.page_id is not null then public.can_view_page(c.page_id)
      when c.conversation_id is not null then public.can_access_conversation(c.conversation_id)
      -- No chat (a routine's, or one whose chat was deleted): the person it was made for and the
      -- bot's managers, so deleting a private chat never widens who sees what it made.
      when c.made_for is not null then c.made_for = auth.uid()
        or (c.bot_id is not null and public.can_manage_bot(c.bot_id))
      when c.bot_id is not null then public.can_access_bot(c.bot_id)
      else public.is_member(c.org_id) end)
$$;
grant execute on function public.can_view_creation(uuid) to authenticated, casama_worker;

create function public.can_change_creation(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.creations c
    where c.id = p_id and (c.made_for = auth.uid()
      or (c.bot_id is not null and public.can_manage_bot(c.bot_id))
      or public.has_role(c.org_id, 'admin')))
$$;
grant execute on function public.can_change_creation(uuid) to authenticated, casama_worker;

alter table public.creations enable row level security;
alter table public.creation_marks enable row level security;
create policy creations_select on public.creations for select to authenticated
  using (public.can_view_creation(id));
create policy creations_update on public.creations for update to authenticated
  using (public.can_change_creation(id)) with check (public.can_change_creation(id));
create policy creation_marks_own on public.creation_marks for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.can_view_creation(creation_id));
select public.allow_worker('public.creations');
select public.allow_worker('public.creation_marks');

-- The kind a file type belongs to.
create function public.creation_kind(p_mime text) returns text language sql immutable set search_path = '' as $$
  select case
    when p_mime like 'image/%' then 'image'
    when p_mime like 'video/%' then 'video'
    when p_mime like 'audio/%' then 'audio'
    when p_mime in ('application/pdf', 'text/markdown', 'text/plain', 'text/csv')
      or p_mime like 'application/vnd.openxmlformats-officedocument.%'
      or p_mime like 'application/vnd.oasis.opendocument.%' then 'document'
    else 'file' end
$$;

-- Pages: every publish, new version and title change mirrors into the Library; deleting the page
-- deletes its creation (the foreign key).
create function public.creations_from_page() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.creations (org_id, bot_id, made_for, conversation_id, kind, title, page_id,
                                mime, size, version, created_at, updated_at)
  values (new.org_id, new.bot_id, new.created_by, new.conversation_id, 'page', new.title, new.id,
          'text/html', octet_length(new.html) + octet_length(new.data::text), new.version,
          new.created_at, new.updated_at)
  on conflict (page_id) do update set
    title = excluded.title, size = excluded.size, version = excluded.version,
    updated_at = excluded.updated_at;
  return new;
end $$;
create trigger pages_to_creations after insert or update of title, html, data, version on public.pages
  for each row execute function public.creations_from_page();

-- Generated pictures and videos (D-205).
create function public.creations_from_media() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_for uuid;
begin
  select coalesce(cv.created_by, r.created_by) into v_for
  from (select 1) one
  left join public.conversations cv on cv.id = new.conversation_id
  left join public.runs r on r.id = new.run_id;
  insert into public.creations (org_id, bot_id, made_for, conversation_id, run_id, kind, title,
                                media_id, mime, size, width, height, duration_s, created_at)
  values (new.org_id, (select id from public.bots where id = new.bot_id), v_for,
          (select id from public.conversations where id = new.conversation_id),
          (select id from public.runs where id = new.run_id),
          public.creation_kind(new.content_type),
          left(coalesce(nullif(regexp_replace(coalesce(new.name, ''), '\.[A-Za-z0-9]+$', ''), ''),
               case public.creation_kind(new.content_type) when 'video' then 'Video'
                    when 'audio' then 'Sound' else 'Picture' end), 200),
          new.id, new.content_type, new.size, new.width, new.height, new.duration_s, new.created_at)
  on conflict (media_id) do nothing;
  return new;
end $$;
create trigger chat_media_to_creations after insert on public.chat_media
  for each row execute function public.creations_from_media();

-- Storage counted per workspace, from the Library's own rows.
create function public.creations_count_storage() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.organizations set storage_bytes = greatest(0, storage_bytes - old.size) where id = old.org_id;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    update public.organizations set storage_bytes = storage_bytes + new.size where id = new.org_id;
  end if;
  return null;
end $$;
create trigger creations_storage after insert or delete or update of size on public.creations
  for each row execute function public.creations_count_storage();

-- Backfill what already exists (production had 2 accounts on 2026-11-13).
insert into public.creations (org_id, bot_id, made_for, conversation_id, kind, title, page_id, mime, size, version, created_at, updated_at)
select p.org_id, p.bot_id, p.created_by, p.conversation_id, 'page', p.title, p.id, 'text/html',
       octet_length(p.html) + octet_length(p.data::text), p.version, p.created_at, p.updated_at
from public.pages p
on conflict (page_id) do nothing;
insert into public.creations (org_id, bot_id, made_for, conversation_id, run_id, kind, title, media_id, mime, size, width, height, duration_s, created_at)
select m.org_id, b.id, coalesce(cv.created_by, r.created_by), cv.id, r.id, public.creation_kind(m.content_type),
       left(coalesce(nullif(regexp_replace(coalesce(m.name, ''), '\.[A-Za-z0-9]+$', ''), ''),
            case public.creation_kind(m.content_type) when 'video' then 'Video' when 'audio' then 'Sound' else 'Picture' end), 200),
       m.id, m.content_type, m.size, m.width, m.height, m.duration_s, m.created_at
from public.chat_media m
left join public.bots b on b.id = m.bot_id
left join public.conversations cv on cv.id = m.conversation_id
left join public.runs r on r.id = m.run_id
on conflict (media_id) do nothing;
-- Counted once for the rows the backfill inserted (the trigger already counted each insert).
