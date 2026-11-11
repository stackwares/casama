-- Joining a workspace (D-167): a standing invite link per workspace, short invite codes, links that
-- ask an admin first, joining by a verified work email domain, and a public preview of an invite.

-- --------------------------------------------------------------------------- invite links
alter table public.invite_links add column kind text not null default 'link' check (kind in ('link', 'code'));
-- People who use the link ask to join; an admin approves.
alter table public.invite_links add column requires_approval boolean not null default false;
-- The workspace's standing link: one live one at a time, copyable again (its token is kept, sealed).
alter table public.invite_links add column is_default boolean not null default false;
alter table public.invite_links add column share_token text;
-- Codes are short, so they never live long.
alter table public.invite_links add constraint invite_links_code_expires check (kind <> 'code' or expires_at is not null);
alter table public.invite_links add constraint invite_links_default_is_link check (not is_default or kind = 'link');
create unique index invite_links_one_default on public.invite_links (org_id) where is_default and revoked_at is null;

-- Email invites can be resent (a new token) by admins.
create policy invites_update on public.invites
  for update to authenticated using (public.has_role(org_id, 'admin')) with check (public.has_role(org_id, 'admin'));

-- --------------------------------------------------------------------------- join requests
create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  link_id uuid references public.invite_links (id) on delete set null,
  role public.org_role not null default 'member' check (role in ('admin', 'member')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'declined')),
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index join_requests_one_pending on public.join_requests (org_id, user_id) where status = 'pending';
create index join_requests_org_idx on public.join_requests (org_id, created_at desc);
alter table public.join_requests enable row level security;
-- Admins see their workspace's requests; people see their own. Changes go through the functions.
create policy join_requests_select on public.join_requests for select to authenticated
  using (public.has_role(org_id, 'admin') or user_id = (select auth.uid()));
select public.allow_worker('public.join_requests');

-- --------------------------------------------------------------------------- email domains
-- Webmail and other shared domains can't be claimed: everyone there would see the workspace.
create or replace function public.is_shared_email_domain(p_domain text)
returns boolean language sql immutable set search_path = ''
as $$
  select lower(p_domain) = any (array[
    'gmail.com', 'googlemail.com', 'outlook.com', 'hotmail.com', 'live.com', 'msn.com', 'yahoo.com',
    'ymail.com', 'icloud.com', 'me.com', 'mac.com', 'aol.com', 'proton.me', 'protonmail.com', 'pm.me',
    'gmx.com', 'gmx.net', 'gmx.de', 'web.de', 'mail.com', 'zoho.com', 'yandex.com', 'yandex.ru',
    'qq.com', '163.com', '126.com', 'naver.com', 'hey.com', 'fastmail.com', 'tutanota.com', 'tuta.io',
    'example.com', 'example.org', 'example.net'
  ]);
$$;

-- The signed-in person's email domain, only once the address is verified.
create or replace function public.my_email_domain()
returns text language sql stable security definer set search_path = ''
as $$
  select lower(split_part(u.email::text, '@', 2)) from auth.users u
  where u.id = auth.uid() and u.email_confirmed_at is not null and position('@' in u.email::text) > 0;
$$;
revoke all on function public.my_email_domain() from public, anon;
grant execute on function public.my_email_domain() to authenticated;

create table public.org_join_domains (
  org_id uuid not null references public.organizations (id) on delete cascade,
  domain extensions.citext not null check (domain::text ~ '^[a-z0-9.-]+\.[a-z]{2,}$'),
  role public.org_role not null default 'member' check (role = 'member'),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (org_id, domain)
);
create index org_join_domains_domain_idx on public.org_join_domains (domain);
alter table public.org_join_domains enable row level security;
create policy org_join_domains_select on public.org_join_domains for select to authenticated
  using (public.has_role(org_id, 'admin'));
-- An admin can only open the workspace to their own verified domain, never a shared one.
create policy org_join_domains_insert on public.org_join_domains for insert to authenticated
  with check (public.has_role(org_id, 'admin') and created_by = (select auth.uid())
              and lower(domain::text) = public.my_email_domain()
              and not public.is_shared_email_domain(domain::text));
create policy org_join_domains_delete on public.org_join_domains for delete to authenticated
  using (public.has_role(org_id, 'admin'));
select public.allow_worker('public.org_join_domains');

-- --------------------------------------------------------------------------- functions
-- What an invite opens, for the screen before joining. Anyone with the token may look; it shows
-- only the workspace's name and look, its size, the role and who made the invite.
create or replace function public.invite_preview(p_token_hash text)
returns table (
  kind text, org_id uuid, org_name text, org_icon text, org_color text, member_count integer,
  role public.org_role, inviter_name text, requires_approval boolean, email text
)
language sql stable security definer set search_path = ''
as $$
  select l.kind, o.id, o.name, o.icon, o.color,
         (select count(*)::int from public.memberships m where m.org_id = o.id),
         l.role, coalesce(nullif(p.display_name, ''), split_part(u.email::text, '@', 1)),
         l.requires_approval, null::text
  from public.invite_links l
  join public.organizations o on o.id = l.org_id
  left join public.profiles p on p.user_id = l.created_by
  left join auth.users u on u.id = l.created_by
  where l.token_hash = p_token_hash and l.revoked_at is null
    and (l.expires_at is null or l.expires_at > now())
    and (l.max_uses is null or l.uses < l.max_uses)
  union all
  select 'email', o.id, o.name, o.icon, o.color,
         (select count(*)::int from public.memberships m where m.org_id = o.id),
         i.role, coalesce(nullif(p.display_name, ''), split_part(u.email::text, '@', 1)),
         false, i.email::text
  from public.invites i
  join public.organizations o on o.id = i.org_id
  left join public.profiles p on p.user_id = i.invited_by
  left join auth.users u on u.id = i.invited_by
  where i.token_hash = p_token_hash and i.accepted_at is null and i.expires_at > now();
$$;
revoke all on function public.invite_preview(text) from public;
grant execute on function public.invite_preview(text) to anon, authenticated;

-- Using a link or code: joins, or files a request when the link asks an admin first.
-- status: joined (new member), member (already in), requested (waiting for an admin).
drop function public.accept_invite_link(text);
create or replace function public.use_invite_link(p_token_hash text)
returns table (org_id uuid, status text, link_id uuid, created_by uuid)
language plpgsql volatile security definer set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_link public.invite_links;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  select * into v_link from public.invite_links l where l.token_hash = p_token_hash for update;
  if not found or v_link.revoked_at is not null or (v_link.expires_at is not null and v_link.expires_at < now())
     or (v_link.max_uses is not null and v_link.uses >= v_link.max_uses) then
    raise exception 'invite_invalid' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.memberships m where m.org_id = v_link.org_id and m.user_id = v_uid) then
    return query select v_link.org_id, 'member'::text, v_link.id, v_link.created_by;
    return;
  end if;
  if v_link.requires_approval then
    insert into public.join_requests (org_id, user_id, link_id, role)
    values (v_link.org_id, v_uid, v_link.id, v_link.role)
    on conflict (org_id, user_id) where status = 'pending' do nothing;
    return query select v_link.org_id, 'requested'::text, v_link.id, v_link.created_by;
    return;
  end if;
  insert into public.memberships (org_id, user_id, role) values (v_link.org_id, v_uid, v_link.role);
  update public.invite_links set uses = uses + 1 where id = v_link.id;
  return query select v_link.org_id, 'joined'::text, v_link.id, v_link.created_by;
end;
$$;
revoke all on function public.use_invite_link(text) from public, anon;
grant execute on function public.use_invite_link(text) to authenticated;

-- Admins approve or decline a request; approving makes the person a member with the link's role.
create or replace function public.decide_join_request(p_request_id uuid, p_approve boolean)
returns public.join_requests
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_req public.join_requests;
begin
  select * into v_req from public.join_requests where id = p_request_id for update;
  if not found or not public.has_role(v_req.org_id, 'admin') then
    raise exception 'request_not_found' using errcode = 'P0002';
  end if;
  if v_req.status <> 'pending' then
    return v_req;
  end if;
  if p_approve then
    insert into public.memberships (org_id, user_id, role) values (v_req.org_id, v_req.user_id, v_req.role)
    on conflict (org_id, user_id) do nothing;
    if v_req.link_id is not null then
      update public.invite_links set uses = uses + 1 where id = v_req.link_id;
    end if;
  end if;
  update public.join_requests
  set status = case when p_approve then 'approved' else 'declined' end, decided_by = auth.uid(), decided_at = now()
  where id = v_req.id
  returning * into v_req;
  return v_req;
end;
$$;
revoke all on function public.decide_join_request(uuid, boolean) from public, anon;
grant execute on function public.decide_join_request(uuid, boolean) to authenticated;

-- Workspaces the signed-in person may join through their verified email domain.
create or replace function public.joinable_workspaces()
returns table (org_id uuid, org_name text, org_icon text, org_color text, member_count integer, domain text)
language sql stable security definer set search_path = ''
as $$
  select o.id, o.name, o.icon, o.color,
         (select count(*)::int from public.memberships m where m.org_id = o.id), d.domain::text
  from public.org_join_domains d
  join public.organizations o on o.id = d.org_id
  where d.domain = public.my_email_domain()::extensions.citext
    and o.suspended_at is null
    and not exists (select 1 from public.memberships m where m.org_id = o.id and m.user_id = auth.uid())
  order by o.name;
$$;
revoke all on function public.joinable_workspaces() from public, anon;
grant execute on function public.joinable_workspaces() to authenticated;

create or replace function public.join_by_domain(p_org_id uuid)
returns public.memberships
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_domain text := public.my_email_domain();
  v_membership public.memberships;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if v_domain is null or not exists (
    select 1 from public.org_join_domains d where d.org_id = p_org_id and d.domain = v_domain::extensions.citext
  ) then
    raise exception 'domain_not_allowed' using errcode = 'P0002';
  end if;
  insert into public.memberships (org_id, user_id, role) values (p_org_id, v_uid, 'member')
  on conflict (org_id, user_id) do nothing;
  select * into v_membership from public.memberships where org_id = p_org_id and user_id = v_uid;
  return v_membership;
end;
$$;
revoke all on function public.join_by_domain(uuid) from public, anon;
grant execute on function public.join_by_domain(uuid) to authenticated;
