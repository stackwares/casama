-- Pages (SPEC: Post-v1 roadmap → Pages; D-092, D-119): a bot's self-contained HTML document with a
-- separate JSON data block, served from its own origin. Never embedded in the app.
create table public.pages (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  -- Who it was made for: a private page is theirs (and its bot's managers').
  created_by uuid references auth.users (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  title text not null check (char_length(title) between 1 and 200),
  html text not null check (octet_length(html) <= 2000000),
  data jsonb not null default '{}'::jsonb check (octet_length(data::text) <= 1000000),
  visibility text not null default 'private' check (visibility in ('private', 'workspace', 'public')),
  public_token_hash text unique,
  expires_at timestamptz,
  refresh_routine_id uuid references public.routines (id) on delete set null,
  version integer not null default 1,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index pages_org_idx on public.pages (org_id, updated_at desc);

-- The last 20 versions of each page.
create table public.page_versions (
  page_id uuid not null references public.pages (id) on delete cascade,
  version integer not null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  html text not null,
  data jsonb not null,
  created_at timestamptz not null default now(),
  primary key (page_id, version)
);

create function public.page_versions_trim() returns trigger language plpgsql as $$
begin
  delete from public.page_versions where page_id = new.page_id and version <= new.version - 20;
  return new;
end $$;
create trigger page_versions_trim after insert on public.page_versions for each row execute function public.page_versions_trim();

-- Single-use view links (60 s) and the short page-scoped sessions they turn into on the pages origin.
create table public.page_view_tokens (
  token_hash text primary key,
  page_id uuid not null references public.pages (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('link', 'session')),
  format text not null default 'html' check (format in ('html', 'pdf')),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index page_view_tokens_expiry_idx on public.page_view_tokens (expires_at);

create function public.can_view_page(p_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.pages p
    where p.id = p_id and case when p.visibility = 'private'
      then p.created_by = auth.uid() or public.can_manage_bot(p.bot_id)
      else public.can_access_bot(p.bot_id) end)
$$;

alter table public.pages enable row level security;
alter table public.page_versions enable row level security;
alter table public.page_view_tokens enable row level security;
create policy pages_select on public.pages for select to authenticated using (
  case when visibility = 'private' then created_by = (select auth.uid()) or public.can_manage_bot(bot_id)
  else public.can_access_bot(bot_id) end);
create policy pages_update on public.pages for update to authenticated
  using (created_by = (select auth.uid()) or public.can_manage_bot(bot_id))
  with check (created_by = (select auth.uid()) or public.can_manage_bot(bot_id));
create policy pages_delete on public.pages for delete to authenticated
  using (created_by = (select auth.uid()) or public.can_manage_bot(bot_id));
create policy page_versions_select on public.page_versions for select to authenticated using (public.can_view_page(page_id));
-- page_view_tokens: server only (no policies).
select public.allow_worker('public.pages');
select public.allow_worker('public.page_versions');
select public.allow_worker('public.page_view_tokens');
