-- Spaces (SPEC: Post-v1 roadmap → Spaces; D-099). A space is an organization; these add its look
-- and shareable invite links.
alter table public.organizations add column icon text check (icon is null or char_length(icon) <= 40);
alter table public.organizations add column color text check (color is null or color ~ '^#[0-9a-fA-F]{6}$');

create table public.invite_links (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  role public.org_role not null default 'member' check (role in ('admin', 'member')),
  token_hash text not null unique,
  -- a short prefix of the token, so admins can tell links apart
  token_hint text not null,
  expires_at timestamptz,
  max_uses integer check (max_uses is null or max_uses between 1 and 10000),
  uses integer not null default 0,
  created_by uuid references auth.users (id) on delete set null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index invite_links_org_idx on public.invite_links (org_id, created_at desc);
alter table public.invite_links enable row level security;
create policy invite_links_select on public.invite_links for select to authenticated
  using (public.has_role(org_id, 'admin'));
create policy invite_links_insert on public.invite_links for insert to authenticated
  with check (public.has_role(org_id, 'admin') and created_by = (select auth.uid()));
create policy invite_links_update on public.invite_links for update to authenticated
  using (public.has_role(org_id, 'admin')) with check (public.has_role(org_id, 'admin'));
select public.allow_worker('public.invite_links');

-- Joining with a link: signed in, link valid (not revoked, not expired, uses left).
create or replace function public.accept_invite_link(p_token_hash text)
returns public.memberships
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_link public.invite_links;
  v_membership public.memberships;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  select * into v_link from public.invite_links where token_hash = p_token_hash for update;
  if not found or v_link.revoked_at is not null or (v_link.expires_at is not null and v_link.expires_at < now())
     or (v_link.max_uses is not null and v_link.uses >= v_link.max_uses) then
    raise exception 'invite_invalid' using errcode = 'P0002';
  end if;
  select * into v_membership from public.memberships where org_id = v_link.org_id and user_id = v_uid;
  if v_membership.id is not null then
    return v_membership;
  end if;
  insert into public.memberships (org_id, user_id, role) values (v_link.org_id, v_uid, v_link.role)
  returning * into v_membership;
  update public.invite_links set uses = uses + 1 where id = v_link.id;
  return v_membership;
end;
$$;
revoke all on function public.accept_invite_link(text) from public, anon;
grant execute on function public.accept_invite_link(text) to authenticated;
