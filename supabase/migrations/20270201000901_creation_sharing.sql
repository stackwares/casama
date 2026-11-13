-- The Library, Phase 5 (D-281): any creation can be private (its person and the bot's managers,
-- or its chat's people), workspace (every member), or public (anyone with its link, on the pages
-- origin). Pages keep their own visibility (D-119). Public links can be reported and taken down.
alter table public.creations add column if not exists visibility text not null default 'private'
  check (visibility in ('private', 'workspace', 'public'));
alter table public.creations add column if not exists public_token_hash text unique;
alter table public.creations add column if not exists share_expires_at timestamptz;
alter table public.creations add column if not exists taken_down_at timestamptz;

create table public.creation_reports (
  id uuid primary key default gen_random_uuid(),
  creation_id uuid not null references public.creations (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 1000),
  -- A hash of the reporter's address, to count distinct reporters without keeping the address.
  reporter text,
  created_at timestamptz not null default now()
);
create index creation_reports_creation_idx on public.creation_reports (creation_id);
-- Server only (instance admins read them through the API).
alter table public.creation_reports enable row level security;
select public.allow_worker('public.creation_reports');

create or replace function public.can_view_creation(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.creations c
    where c.id = p_id and case
      when c.page_id is not null then public.can_view_page(c.page_id)
      when c.visibility in ('workspace', 'public') then public.is_member(c.org_id)
      when c.conversation_id is not null then public.can_access_conversation(c.conversation_id)
      when c.made_for is not null then c.made_for = auth.uid()
        or (c.bot_id is not null and public.can_manage_bot(c.bot_id))
      when c.bot_id is not null then public.can_access_bot(c.bot_id)
      else public.is_member(c.org_id) end)
$$;
