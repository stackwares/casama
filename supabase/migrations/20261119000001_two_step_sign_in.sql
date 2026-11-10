-- Two-step sign-in (SPEC: Phase 8 launch items; D-093).
-- A workspace can require it: then owner and admin powers need a session that passed the second
-- step (Supabase Auth's `aal2`). Members are unaffected. Enforced in has_role, so every RLS
-- policy and every API check that asks "is this person an admin here?" follows it.

alter table public.organizations add column require_mfa boolean not null default false;

create or replace function public.has_role(p_org_id uuid, p_role public.org_role)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
    join public.organizations o on o.id = m.org_id
    where m.org_id = p_org_id
      and m.user_id = (select auth.uid())
      and case p_role
            when 'owner' then m.role = 'owner'
            when 'admin' then m.role in ('owner', 'admin')
            else true
          end
      and (
        p_role = 'member'
        or not o.require_mfa
        or coalesce((select nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'aal'), 'aal1') = 'aal2'
      )
  );
$$;

-- Whether the caller is an owner or admin held back only by a missing second step (for clear errors).
create or replace function public.mfa_blocks_admin(p_org_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
    join public.organizations o on o.id = m.org_id
    where m.org_id = p_org_id and m.user_id = (select auth.uid())
      and m.role in ('owner', 'admin') and o.require_mfa
      and coalesce((select nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'aal'), 'aal1') <> 'aal2'
  );
$$;
grant execute on function public.mfa_blocks_admin(uuid) to authenticated;
