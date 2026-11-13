-- Money leaks from docs/MONETIZATION-AUDIT-2026-11-13.md (D-248).
--
-- The referral welcome bonus is capped per inviter: their friends earn it for at most twice the
-- reward cap (40 with the defaults), instead of without limit.

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
    -- No reward without an inviter, or for one whose account is deleted or banned (D-072 bans first).
    if r.inviter_id is null or coalesce(p_amount, 0) <= 0
       or exists (select 1 from auth.users iu where iu.id = r.inviter_id and iu.banned_until >= now()) then
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
    -- The friend's welcome bonus, for at most twice the reward cap of one inviter's friends, so
    -- an inviter can't mint unlimited $2 accounts (D-248). Friends past the reward cap still get it
    -- up to that point (D-211).
    if coalesce(p_welcome, 0) > 0
       and (r.inviter_id is null or (
         select count(*) from public.referrals x
         where x.inviter_id = r.inviter_id and x.welcome_usd is not null) < p_cap * 2) then
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
