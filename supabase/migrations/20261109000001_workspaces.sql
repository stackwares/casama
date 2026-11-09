-- Phase 0: workspaces (organizations, memberships, profiles, invites)
-- Every table has RLS enabled in this same migration.

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9](?:[a-z0-9-]{0,46}[a-z0-9])?$'),
  plan text not null default 'selfhost',
  region text not null default 'local',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create type public.org_role as enum ('owner', 'admin', 'member');

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.org_role not null default 'member',
  created_at timestamptz not null default now(),
  unique (org_id, user_id)
);
create index memberships_user_id_idx on public.memberships (user_id);

create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 120),
  avatar_url text,
  locale text not null default 'en',
  timezone text not null default 'UTC',
  created_at timestamptz not null default now()
);

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  email extensions.citext not null,
  role public.org_role not null default 'member' check (role <> 'owner'),
  token_hash text not null unique,
  invited_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_at timestamptz,
  accepted_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index invites_org_id_idx on public.invites (org_id);

-- ---------------------------------------------------------------------------
-- Helper functions (back every RLS policy)
-- ---------------------------------------------------------------------------

create or replace function public.is_member(p_org_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
    where m.org_id = p_org_id and m.user_id = (select auth.uid())
  );
$$;

-- has_role(org, 'admin') is true for admins and owners; 'member' is true for any member.
create or replace function public.has_role(p_org_id uuid, p_role public.org_role)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
    where m.org_id = p_org_id
      and m.user_id = (select auth.uid())
      and case p_role
            when 'owner' then m.role = 'owner'
            when 'admin' then m.role in ('owner', 'admin')
            else true
          end
  );
$$;

-- ---------------------------------------------------------------------------
-- Commands that must be atomic (called by the API under the user's session)
-- ---------------------------------------------------------------------------

create or replace function public.create_organization(p_name text, p_slug text)
returns public.organizations
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_org public.organizations;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  insert into public.organizations (name, slug, created_by)
  values (p_name, p_slug, v_uid)
  returning * into v_org;
  insert into public.memberships (org_id, user_id, role) values (v_org.id, v_uid, 'owner');
  return v_org;
end;
$$;

-- Accept an invite by the sha256 hex of its token. The invite email must match the caller's email.
create or replace function public.accept_invite(p_token_hash text)
returns public.memberships
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_invite public.invites;
  v_membership public.memberships;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  select * into v_invite from public.invites
  where token_hash = p_token_hash
  for update;
  if not found or v_invite.accepted_at is not null or v_invite.expires_at < now() then
    raise exception 'invite_invalid' using errcode = 'P0002';
  end if;
  if lower(v_invite.email::text) <> v_email then
    raise exception 'invite_email_mismatch' using errcode = '42501';
  end if;
  insert into public.memberships (org_id, user_id, role)
  values (v_invite.org_id, v_uid, v_invite.role)
  on conflict (org_id, user_id) do update set role = excluded.role
    where public.memberships.role = 'member' and excluded.role = 'admin'
  returning * into v_membership;
  if v_membership.id is null then
    select * into v_membership from public.memberships
    where org_id = v_invite.org_id and user_id = v_uid;
  end if;
  update public.invites set accepted_at = now(), accepted_by = v_uid where id = v_invite.id;
  return v_membership;
end;
$$;

-- Keep at least one owner per organization.
create or replace function public.memberships_keep_owner()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    if not exists (
      select 1 from public.memberships
      where org_id = old.org_id and role = 'owner' and id <> old.id
    ) and exists (select 1 from public.organizations where id = old.org_id) then
      raise exception 'last_owner' using errcode = '23514';
    end if;
  end if;
  return coalesce(new, old);
end;
$$;
create trigger memberships_keep_owner
before update or delete on public.memberships
for each row execute function public.memberships_keep_owner();

-- Create a profile for every new auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (user_id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.profiles enable row level security;
alter table public.invites enable row level security;

-- organizations: created only through create_organization()
create policy organizations_select on public.organizations
  for select to authenticated using (public.is_member(id));
create policy organizations_update on public.organizations
  for update to authenticated using (public.has_role(id, 'admin')) with check (public.has_role(id, 'admin'));
create policy organizations_delete on public.organizations
  for delete to authenticated using (public.has_role(id, 'owner'));

-- memberships: joined only through create_organization() or accept_invite()
create policy memberships_select on public.memberships
  for select to authenticated using (public.is_member(org_id));
create policy memberships_update on public.memberships
  for update to authenticated
  using (public.has_role(org_id, 'admin'))
  with check (public.has_role(org_id, 'admin') and (role <> 'owner' or public.has_role(org_id, 'owner')));
create policy memberships_delete on public.memberships
  for delete to authenticated
  using (user_id = (select auth.uid()) or public.has_role(org_id, 'admin'));

-- profiles: your own, plus people who share an organization with you
create policy profiles_select on public.profiles
  for select to authenticated using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.memberships theirs
      where theirs.user_id = profiles.user_id and public.is_member(theirs.org_id)
    )
  );
create policy profiles_insert on public.profiles
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy profiles_update on public.profiles
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- invites: admins only
create policy invites_select on public.invites
  for select to authenticated using (public.has_role(org_id, 'admin'));
create policy invites_insert on public.invites
  for insert to authenticated with check (public.has_role(org_id, 'admin') and invited_by = (select auth.uid()));
create policy invites_delete on public.invites
  for delete to authenticated using (public.has_role(org_id, 'admin'));

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke all on function public.create_organization(text, text) from public, anon;
revoke all on function public.accept_invite(text) from public, anon;
grant execute on function public.create_organization(text, text) to authenticated;
grant execute on function public.accept_invite(text) to authenticated;
grant execute on function public.is_member(uuid) to authenticated;
grant execute on function public.has_role(uuid, public.org_role) to authenticated;
