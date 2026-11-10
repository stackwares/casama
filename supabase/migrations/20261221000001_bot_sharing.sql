-- Bot sharing (SPEC: Post-v1 roadmap → Bot sharing; D-131): who can chat with, edit or administer
-- a bot. The workspace default stays "everyone can chat" (visibility team); a private bot is
-- visible only to its creator and the people or roles listed.
create table public.bot_access (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  role public.org_role,
  access text not null check (access in ('chat', 'edit', 'admin')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  check ((user_id is null) <> (role is null))
);
create unique index bot_access_user_idx on public.bot_access (bot_id, user_id) where user_id is not null;
create unique index bot_access_role_idx on public.bot_access (bot_id, role) where role is not null;

/** The access a grant gives this person: the best of their own grant and their role's. */
create function public.bot_grant(p_bot_id uuid) returns text language sql stable security definer set search_path = '' as $$
  select a.access from public.bot_access a
  join public.memberships m on m.org_id = a.org_id and m.user_id = (select auth.uid())
  where a.bot_id = p_bot_id
    and (a.user_id = (select auth.uid())
      or (a.role is not null and case a.role when 'owner' then m.role = 'owner' when 'admin' then m.role in ('owner', 'admin') else true end))
  order by case a.access when 'admin' then 0 when 'edit' then 1 else 2 end limit 1
$$;

create or replace function public.can_access_bot(p_bot_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bots b
    join public.memberships m on m.org_id = b.org_id and m.user_id = (select auth.uid())
    where b.id = p_bot_id and (b.visibility = 'team' or b.created_by = (select auth.uid()) or public.bot_grant(b.id) is not null)
  );
$$;

create or replace function public.can_manage_bot(p_bot_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bots b
    where b.id = p_bot_id
      and public.can_access_bot(b.id)
      and (b.created_by = (select auth.uid())
        or (b.visibility = 'team' and public.has_role(b.org_id, 'admin'))
        or public.bot_grant(b.id) in ('edit', 'admin'))
  );
$$;

/** Who may change a bot's sharing: its creator, workspace admins, or an admin grant. */
create function public.can_admin_bot(p_bot_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bots b
    where b.id = p_bot_id and public.can_access_bot(b.id)
      and (b.created_by = (select auth.uid()) or public.has_role(b.org_id, 'admin') or public.bot_grant(b.id) = 'admin')
  );
$$;
grant execute on function public.bot_grant(uuid) to authenticated;
grant execute on function public.can_admin_bot(uuid) to authenticated;

alter table public.bot_access enable row level security;
create policy bot_access_select on public.bot_access for select to authenticated using (public.can_access_bot(bot_id));
select public.allow_worker('public.bot_access');

-- People on a private bot's list see it too.
drop policy bots_select on public.bots;
create policy bots_select on public.bots for select to authenticated
  using (public.is_member(org_id) and (visibility = 'team' or created_by = (select auth.uid()) or public.bot_grant(id) is not null));
