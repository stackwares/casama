-- D-448: approving an admin bot action (D-435) takes a fresh sign-in, however the decision
-- arrives. The API checks it first; this is the same rule for a direct call to decide_approval with
-- the person's token (PostgREST), which would otherwise skip the API.

-- A real sign-in within the last minute in this request's token (Supabase's signed `amr`), and the
-- second step when the account has an authenticator. Mirrors apps/server/src/api/admin-security.ts.
create or replace function public.fresh_admin_sign_in()
returns boolean
language sql stable
set search_path = ''
as $$
  with c as (
    select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb as j
  )
  select exists (
      select 1
      from c, jsonb_array_elements(
        case when jsonb_typeof(c.j -> 'amr') = 'array' then c.j -> 'amr' else '[]'::jsonb end
      ) e
      where jsonb_typeof(e) = 'object'
        and e ->> 'method' in ('password', 'otp', 'totp', 'oauth', 'sso/saml', 'magiclink', 'passkey')
        and jsonb_typeof(e -> 'timestamp') = 'number'
        and (e ->> 'timestamp')::numeric > 0
        and (e ->> 'timestamp')::numeric <= extract(epoch from now())
        and extract(epoch from now()) - (e ->> 'timestamp')::numeric <= 60
    )
    and (
      (select c.j ->> 'aal' from c) = 'aal2'
      or not exists (
        select 1 from auth.mfa_factors f
        where f.user_id = (select auth.uid()) and f.status = 'verified'
      )
    );
$$;

revoke all on function public.fresh_admin_sign_in() from public, anon, authenticated;

create or replace function public.decide_approval(p_approval_id uuid, p_decision text, p_always_allow boolean default false)
returns public.approvals
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v public.approvals;
begin
  if p_decision not in ('approved', 'denied') then
    raise exception 'bad_decision' using errcode = '22023';
  end if;
  select * into v from public.approvals where id = p_approval_id for update;
  if not found or not public.can_access_bot(v.bot_id) then
    raise exception 'approval_not_found' using errcode = 'P0002';
  end if;
  if v.status <> 'pending' then
    raise exception 'approval_already_decided' using errcode = '55000';
  end if;
  if v.expires_at < now() then
    update public.approvals set status = 'expired' where id = v.id returning * into v;
    return v;
  end if;
  -- Admin bot actions: approving needs a fresh sign-in (declining never does).
  if p_decision = 'approved' and v.tool_name like 'admin.%' and not public.fresh_admin_sign_in() then
    raise exception 'admin_confirmation_required' using errcode = '28000';
  end if;
  update public.approvals
     set status = p_decision, always_allow = (p_decision = 'approved' and p_always_allow),
         decided_by = (select auth.uid()), decided_at = now()
   where id = v.id returning * into v;
  if v.always_allow then
    insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule, created_by)
    select v.org_id, v.bot_id, 'tool', v.tool_name, 'allow', (select auth.uid())
    where not exists (select 1 from public.action_rules r where r.bot_id = v.bot_id and r.match_kind = 'tool'
                      and r.match_value = v.tool_name and r.target is null);
  end if;
  return v;
end;
$$;
