-- Invite friends (D-211): anyone can sign up (no gate); each person has one personal invite code and
-- link, a new person can enter a friend's code for a few days after signing up, and the friend who
-- invited them earns free credits once the new person is real: a verified address and a first finished
-- run. The new person gets a welcome bonus at the same moment. Inviter rewards are capped per inviter.
-- The server decides the amounts, the cap and the window.

-- --------------------------------------------------------------------------- codes
-- One code per person, made on first use: 6 characters of Crockford base32 (no I, L, O or U), so it
-- can't be mistaken for a workspace code (8 characters, D-167).
create table public.referral_codes (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code text not null unique check (code ~ '^[0-9A-HJKMNP-TV-Z]{6}$'),
  created_at timestamptz not null default now()
);
alter table public.referral_codes enable row level security;
create policy referral_codes_select on public.referral_codes for select to authenticated
  using (user_id = (select auth.uid()));
select public.allow_worker('public.referral_codes');

-- --------------------------------------------------------------------------- referrals
-- One row per invited person. `status`: pending (waiting for the new person's first run), rewarded,
-- capped (the inviter had reached the cap) or none (rewards were off, or the inviter is gone). The
-- new person's welcome bonus is recorded beside it (`welcome_usd`, null when none was given).
create table public.referrals (
  invitee_id uuid primary key references auth.users (id) on delete cascade,
  inviter_id uuid references auth.users (id) on delete set null,
  code text not null,
  status text not null default 'pending' check (status in ('pending', 'rewarded', 'capped', 'none')),
  reward_usd numeric(12, 2),
  reward_org_id uuid references public.organizations (id) on delete set null,
  welcome_usd numeric(12, 2),
  welcome_org_id uuid references public.organizations (id) on delete set null,
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create index referrals_inviter_idx on public.referrals (inviter_id, created_at desc);
create index referrals_pending_idx on public.referrals (created_at) where status = 'pending';
alter table public.referrals enable row level security;
-- People see the referral that brought them and the ones they made. Changes go through the functions.
create policy referrals_select on public.referrals for select to authenticated
  using (invitee_id = (select auth.uid()) or inviter_id = (select auth.uid()));
select public.allow_worker('public.referrals');

-- --------------------------------------------------------------------------- the inviter's name
-- Deleted accounts are banned at once (D-072), so a live ban means the account is gone or blocked.
-- What a code's page and the app show: the inviter's first name, never the email fallback name.
create or replace function public.referral_inviter_name(p_user uuid)
returns text language sql stable security definer set search_path = ''
as $$
  select nullif(split_part(btrim(p.display_name), ' ', 1), '')
  from public.profiles p join auth.users u on u.id = p.user_id
  where p.user_id = p_user and (u.banned_until is null or u.banned_until < now())
    and p.display_name is distinct from split_part(coalesce(u.email::text, ''), '@', 1)
$$;
revoke all on function public.referral_inviter_name(uuid) from public, anon, authenticated;

-- A code's preview, for the casama.ai/i/<code> page and the app before anyone signs in.
create or replace function public.referral_preview(p_code text)
returns table (inviter_name text)
language sql stable security definer set search_path = ''
as $$
  select public.referral_inviter_name(rc.user_id)
  from public.referral_codes rc
  join auth.users u on u.id = rc.user_id
  where rc.code = upper(p_code) and (u.banned_until is null or u.banned_until < now())
$$;
revoke all on function public.referral_preview(text) from public;
grant execute on function public.referral_preview(text) to anon, authenticated;

-- --------------------------------------------------------------------------- redeeming
-- The signed-in person enters a friend's code. Errors carry a stable message the API maps:
-- referral_not_found, referral_own_code, referral_already, referral_window_closed, referral_mutual.
create or replace function public.redeem_referral(p_code text, p_window_days integer)
returns table (inviter_id uuid, inviter_name text)
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_inviter uuid;
  v_signed_up timestamptz;
begin
  if v_me is null then raise exception 'not signed in' using errcode = '42501'; end if;
  select rc.user_id into v_inviter
  from public.referral_codes rc join auth.users u on u.id = rc.user_id
  where rc.code = upper(p_code) and (u.banned_until is null or u.banned_until < now());
  if v_inviter is null then raise exception 'referral_not_found' using errcode = 'P0002'; end if;
  if v_inviter = v_me then raise exception 'referral_own_code' using errcode = '22023'; end if;
  if exists (select 1 from public.referrals r where r.invitee_id = v_me) then
    raise exception 'referral_already' using errcode = '23505';
  end if;
  -- Two people can't each claim to have invited the other.
  if exists (select 1 from public.referrals r where r.invitee_id = v_inviter and r.inviter_id = v_me) then
    raise exception 'referral_mutual' using errcode = '22023';
  end if;
  select u.created_at into v_signed_up from auth.users u where u.id = v_me;
  if v_signed_up < now() - make_interval(days => greatest(p_window_days, 0)) then
    raise exception 'referral_window_closed' using errcode = '22023';
  end if;
  insert into public.referrals (invitee_id, inviter_id, code) values (v_me, v_inviter, upper(p_code));
  return query select v_inviter, public.referral_inviter_name(v_inviter);
end;
$$;
revoke all on function public.redeem_referral(text, integer) from public, anon;
grant execute on function public.redeem_referral(text, integer) to authenticated;

-- --------------------------------------------------------------------------- rewarding
-- Worker: pending referrals whose new person is real now (a verified email, and a first finished run,
-- the `first_value` milestone) are decided, all through credit_apply (once per referral):
-- - the inviter, under the cap, gets `p_amount` in the oldest workspace they own; an inviter who owns
--   no workspace yet stays pending (and so does the welcome bonus, until the next sweep finds one);
-- - the new person gets `p_welcome` in the oldest workspace they own (none owned: no bonus).
-- Returns what was decided, for notifications and analytics.
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
      if v_count >= p_cap then
        v_status := 'capped';
      else
        select m.org_id into v_org from public.memberships m join public.organizations o on o.id = m.org_id
        where m.user_id = r.inviter_id and m.role = 'owner' order by o.created_at limit 1;
        if v_org is null then continue; end if;
        v_status := 'rewarded';
        perform public.credit_apply(v_org, p_amount, 'grant', 'referral:' || r.invitee_id::text,
          'Invite reward: a friend joined');
        v_count := v_count + 1;
      end if;
    end if;
    v_welcome_org := null;
    v_welcome := null;
    if coalesce(p_welcome, 0) > 0 then
      select m.org_id into v_welcome_org from public.memberships m join public.organizations o on o.id = m.org_id
      where m.user_id = r.invitee_id and m.role = 'owner' order by o.created_at limit 1;
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
