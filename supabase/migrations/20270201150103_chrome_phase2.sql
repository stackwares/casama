-- D-323 (Casama for Chrome, Phase 2): page commands (A13), highlights (B7), and conversations that
-- remember the page they started from (A20).

-- A13: saved prompts a person runs with "/" in the panel. Per person, synced to the account.
create table if not exists public.page_commands (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  prompt text not null check (char_length(prompt) between 1 and 4000),
  position int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, name)
);
create index if not exists page_commands_user on public.page_commands (user_id, position);
alter table public.page_commands enable row level security;
drop policy if exists page_commands_own on public.page_commands;
create policy page_commands_own on public.page_commands for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
select public.allow_worker('public.page_commands');

-- B7: text a person highlighted on a page. Shown again on their next visit, and readable by the
-- bots that act for them in that workspace (highlights.search). Private to the person.
create table if not exists public.highlights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  url text not null check (char_length(url) <= 2000),
  -- The address without its fragment and tracking parameters, to find a page's highlights.
  url_key text not null check (char_length(url_key) <= 2000),
  title text not null default '' check (char_length(title) <= 300),
  text text not null check (char_length(text) between 1 and 5000),
  -- A little of what comes before and after, to find the text again on the page.
  prefix text not null default '' check (char_length(prefix) <= 64),
  suffix text not null default '' check (char_length(suffix) <= 64),
  note text not null default '' check (char_length(note) <= 2000),
  created_at timestamptz not null default now()
);
create index if not exists highlights_user_url on public.highlights (user_id, url_key);
create index if not exists highlights_org_user on public.highlights (org_id, user_id, created_at desc);
alter table public.highlights enable row level security;
drop policy if exists highlights_own on public.highlights;
create policy highlights_own on public.highlights for all to authenticated
  using (user_id = auth.uid() and public.is_member(org_id))
  with check (user_id = auth.uid() and public.is_member(org_id));
select public.allow_worker('public.highlights');

-- A20: the page a conversation started from, to list past chats about a page.
alter table public.conversations add column if not exists source_url text
  check (source_url is null or char_length(source_url) <= 2000);
create index if not exists conversations_source_url on public.conversations (created_by, source_url)
  where source_url is not null;

-- Watchers a person made by pointing at a page (POST /v1/watchers): they can pause or stop their
-- own, even on a bot they don't manage, as long as they still use that bot.
drop policy if exists watchers_update_own on public.watchers;
create policy watchers_update_own on public.watchers for update to authenticated
  using (created_by = auth.uid() and public.can_access_bot(bot_id))
  with check (created_by = auth.uid() and public.can_access_bot(bot_id));
drop policy if exists watchers_delete_own on public.watchers;
create policy watchers_delete_own on public.watchers for delete to authenticated
  using (created_by = auth.uid() and public.can_access_bot(bot_id));
