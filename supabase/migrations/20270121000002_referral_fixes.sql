-- Invite friends fixes (D-211, audit 2026-11-12).
-- 1. A referral whose inviter owned no workspace stayed pending and was picked up again every
--    minute, ahead of newer ones; with enough of them, the 100-row sweep would never reach the rest,
--    and the new person's welcome bonus waited too. Credits now go to the oldest workspace the
--    person owns, else the oldest one they belong to; with no workspace at all the referral is
--    decided anyway (no credits for that side), so nothing stays stuck.
-- 2. Two redeems by the same person at the same moment hit the primary key and surfaced as a 500.
--    They now answer referral_already like any second redeem.
-- 3. redeem_referral took the redeem window from its caller and was executable by `authenticated`,
--    so anyone signed in could call it through PostgREST (/rest/v1/rpc) with a window of years and
--    redeem a code on an old account. referral_preview was executable by `anon`, which skipped the
--    API's guessing limit. Both are now API-only: redeem_referral_for(user, code, days) is called by
--    the API with the signed-in person's id and the server's window, and neither is granted to
--    anon or authenticated.

-- The workspace that receives someone's credits: oldest owned, else oldest membership.
create or replace function public.referral_credit_org(p_user uuid)
returns uuid language sql stable security definer set search_path = ''
as $$
  select m.org_id from public.memberships m join public.organizations o on o.id = m.org_id
  where m.user_id = p_user
  order by (m.role = 'owner') desc, o.created_at
  limit 1
$$;
revoke all on function public.referral_credit_org(uuid) from public, anon, authenticated;

create or replace function public.worker_reward_referrals(
  p_amount numeric, p_welcome numeric, p_cap integer, p_limit integer default 100)
returns table (invitee_id uuid, inviter_id uuid, status text, reward_usd numeric, org_id uuid,
               rewarded_count integer, welcome_usd numeric, welcome_org_id uuid)
language plpgsql volatile security definer set search_path = ''
as $$
declare
  r record;
  v_org uuid;
  v_welcome_org uuid;
  v_welcome numeric;
  v_count integer;
  v_status text;
begin
  for r in
    select ref.invitee_id, ref.inviter_id
    from public.referrals ref
    join auth.users u on u.id = ref.invitee_id
    where ref.status = 'pending'
      and u.email_confirmed_at is not null
      and (u.banned_until is null or u.banned_until < now())
      and exists (select 1 from public.analytics_milestones m
                  where m.user_id = ref.invitee_id and m.milestone = 'first_value')
    order by ref.created_at
    limit greatest(1, least(p_limit, 1000))
    for update of ref skip locked
  loop
    v_org := null;
    v_count := 0;
    if r.inviter_id is null or coalesce(p_amount, 0) <= 0 then
      v_status := 'none';
    else
      -- One inviter at a time, so two sweeps can't both pass the cap.
      perform pg_advisory_xact_lock(hashtext('referral:' || r.inviter_id::text));
      select count(*)::integer into v_count from public.referrals x
      where x.inviter_id = r.inviter_id and x.status = 'rewarded';
      v_org := public.referral_credit_org(r.inviter_id);
      if v_count >= p_cap then
        v_status := 'capped';
        v_org := null;
      elsif v_org is null then
        v_status := 'none';
      else
        v_status := 'rewarded';
        perform public.credit_apply(v_org, p_amount, 'grant', 'referral:' || r.invitee_id::text,
          'Invite reward: a friend joined');
        v_count := v_count + 1;
      end if;
    end if;
    v_welcome_org := null;
    v_welcome := null;
    if coalesce(p_welcome, 0) > 0 then
      v_welcome_org := public.referral_credit_org(r.invitee_id);
      if v_welcome_org is not null then
        v_welcome := p_welcome;
        perform public.credit_apply(v_welcome_org, p_welcome, 'grant',
          'referral-welcome:' || r.invitee_id::text, 'Welcome bonus: joined with a friend''s invite');
      end if;
    end if;
    update public.referrals x set status = v_status, decided_at = now(),
      reward_usd = case when v_status = 'rewarded' then p_amount end, reward_org_id = v_org,
      welcome_usd = v_welcome, welcome_org_id = v_welcome_org
    where x.invitee_id = r.invitee_id;
    return query select r.invitee_id, r.inviter_id, v_status,
      case when v_status = 'rewarded' then p_amount end, v_org, v_count, v_welcome, v_welcome_org;
  end loop;
end;
$$;
revoke all on function public.worker_reward_referrals(numeric, numeric, integer, integer) from public, anon, authenticated;
grant execute on function public.worker_reward_referrals(numeric, numeric, integer, integer) to casama_worker;

drop function if exists public.redeem_referral(text, integer);

create or replace function public.redeem_referral_for(p_user uuid, p_code text, p_window_days integer)
returns table (inviter_id uuid, inviter_name text)
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_inviter uuid;
  v_signed_up timestamptz;
begin
  if p_user is null then raise exception 'not signed in' using errcode = '42501'; end if;
  select rc.user_id into v_inviter
  from public.referral_codes rc join auth.users u on u.id = rc.user_id
  where rc.code = upper(p_code) and (u.banned_until is null or u.banned_until < now());
  if v_inviter is null then raise exception 'referral_not_found' using errcode = 'P0002'; end if;
  if v_inviter = p_user then raise exception 'referral_own_code' using errcode = '22023'; end if;
  if exists (select 1 from public.referrals r where r.invitee_id = p_user) then
    raise exception 'referral_already' using errcode = '23505';
  end if;
  -- Two people can't each claim to have invited the other.
  if exists (select 1 from public.referrals r where r.invitee_id = v_inviter and r.inviter_id = p_user) then
    raise exception 'referral_mutual' using errcode = '22023';
  end if;
  select u.created_at into v_signed_up from auth.users u where u.id = p_user;
  if v_signed_up is null then raise exception 'not signed in' using errcode = '42501'; end if;
  if v_signed_up < now() - make_interval(days => greatest(p_window_days, 0)) then
    raise exception 'referral_window_closed' using errcode = '22023';
  end if;
  begin
    insert into public.referrals (invitee_id, inviter_id, code) values (p_user, v_inviter, upper(p_code));
  exception when unique_violation then
    -- The same person redeeming twice at once: the other request won.
    raise exception 'referral_already' using errcode = '23505';
  end;
  return query select v_inviter, public.referral_inviter_name(v_inviter);
end;
$$;
revoke all on function public.redeem_referral_for(uuid, text, integer) from public, anon, authenticated;

revoke execute on function public.referral_preview(text) from anon, authenticated;
