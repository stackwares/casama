-- About you (D-169): one profile per person that every bot they use reads.
-- What to call them and their pronouns sit on profiles, which teammates already see. "About me",
-- "How I like replies" and the facts bots learn about the person are private to them: bots read
-- them through the worker, and only in personal spaces unless the person turns them on for a team
-- space.

-- --------------------------------------------------------------------------- profiles
alter table public.profiles add column preferred_name text check (preferred_name is null or char_length(preferred_name) <= 60);
alter table public.profiles add column pronouns text check (pronouns is null or char_length(pronouns) <= 40);

-- --------------------------------------------------------------------------- private profile
create table public.user_about (
  user_id uuid primary key references auth.users (id) on delete cascade,
  about text not null default '' check (char_length(about) <= 1500),
  reply_style text not null default '' check (char_length(reply_style) <= 600),
  -- Whether bots may save what they learn about the person in chat.
  learn boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.user_about enable row level security;
create policy user_about_own on public.user_about for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
select public.allow_worker('public.user_about');

-- --------------------------------------------------------------------------- learned facts
create table public.user_facts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null default 'fact' check (kind in ('fact', 'preference')),
  content text not null check (char_length(content) between 1 and 500),
  pinned boolean not null default false,
  -- Where it was learned (kept for "why does it know this"; never used to scope it).
  source_org_id uuid references public.organizations (id) on delete set null,
  source_bot_id uuid references public.bots (id) on delete set null,
  source_run_id uuid references public.runs (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index user_facts_user_idx on public.user_facts (user_id, updated_at desc);
alter table public.user_facts enable row level security;
create policy user_facts_own on public.user_facts for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
select public.allow_worker('public.user_facts');

-- At most 200 facts per person: the oldest unpinned ones go first.
create or replace function public.user_facts_cap()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.user_facts f
  where f.user_id = new.user_id and not f.pinned and f.id in (
    select x.id from public.user_facts x where x.user_id = new.user_id and not x.pinned
    order by x.updated_at desc offset 200);
  return null;
end;
$$;
create trigger user_facts_cap after insert on public.user_facts
  for each row execute function public.user_facts_cap();

-- --------------------------------------------------------------------------- per space
-- "Use what I've shared about me" in one workspace. With no row: on in a personal space (the person
-- is its only member), off anywhere else.
create table public.profile_spaces (
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  share_about boolean not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, org_id)
);
alter table public.profile_spaces enable row level security;
create policy profile_spaces_own on public.profile_spaces for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_member(org_id));
select public.allow_worker('public.profile_spaces');

-- Whether runs for this person in this workspace may use "About me" and learned facts.
create or replace function public.profile_shared_in(p_user uuid, p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select ps.share_about from public.profile_spaces ps where ps.user_id = p_user and ps.org_id = p_org),
    exists (select 1 from public.memberships m where m.org_id = p_org and m.user_id = p_user)
      and not exists (select 1 from public.memberships m where m.org_id = p_org and m.user_id <> p_user)
  );
$$;
revoke execute on function public.profile_shared_in(uuid, uuid) from public, anon;
grant execute on function public.profile_shared_in(uuid, uuid) to authenticated, casama_worker;
