-- Billing audit 2026-11-17 (D-333): one person, one set of free things.
--
-- Free credits, the web trial and referral rewards were decided per account, and accounts are
-- cheap: Gmail ignores dots and every provider delivers "+tag" addresses to the same inbox, so one
-- inbox could confirm any number of accounts. Deleting an account and signing up again also
-- started fresh.
--
-- email_identities keys those decisions on a normalised email instead: lower case, the "+tag"
-- removed, and for Gmail the dots removed and googlemail.com read as gmail.com. Only a SHA-256 of
-- that normalised address is stored, and a row outlives the account (its user_id goes null), so a
-- new account on the same inbox doesn't start fresh.
--
--   user_id           the account that gets this inbox's free credits (the first to claim them;
--                     another account takes over only once that one is deleted);
--   trial_ref         the subscription ('<source>:<external id>') that used this person's one
--                     trial: any subscription counts, as before;
--   referral_invitee  the account whose invite was decided for this inbox: an inbox earns its
--                     inviter a reward, and itself a welcome bonus, once.
--
-- subscriptions.trial_blocked marks a web trial that started although the person's trial was
-- already used (two checkouts at once in two workspaces): it gives nothing until it is paid.

create or replace function public.email_key(p_email text) returns text
language sql immutable parallel safe set search_path = '' as $$
  select case when e.local is null or e.local = '' or e.domain is null or e.domain = '' then null
    else encode(sha256(convert_to(
      case when e.domain in ('gmail.com', 'googlemail.com')
        then replace(e.local, '.', '') || '@gmail.com'
        else e.local || '@' || e.domain end, 'UTF8')), 'hex') end
  from (select split_part(substring(x.e from '^(.*)@'), '+', 1) as local,
               substring(x.e from '@([^@]*)$') as domain
        from (select lower(btrim(coalesce(p_email, ''))) as e) x) e
$$;

create table if not exists public.email_identities (
  email_key text primary key,
  user_id uuid references auth.users (id) on delete set null,
  trial_ref text,
  referral_invitee uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.email_identities enable row level security;
revoke all on public.email_identities from anon, authenticated;
select public.allow_worker('public.email_identities');

alter table public.subscriptions add column if not exists trial_blocked boolean not null default false;

-- The key of an account's email, or null when it has none.
create or replace function public.user_email_key(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  select public.email_key(u.email) from auth.users u where u.id = p_user
$$;

-- Whether this account gets its inbox's free credits: it claims them when nobody (alive) has.
-- An account without an email isn't limited by this.
create or replace function public.claim_free_credits(p_user uuid) returns boolean
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_key text := public.user_email_key(p_user);
  v_holder uuid;
begin
  if v_key is null then return true; end if;
  insert into public.email_identities as i (email_key, user_id) values (v_key, p_user)
  on conflict (email_key) do update
    set user_id = coalesce(i.user_id, excluded.user_id),
        updated_at = case when i.user_id is null then now() else i.updated_at end
  returning i.user_id into v_holder;
  return v_holder = p_user;
end;
$$;

-- Records that this person has a subscription; true when it is the one that holds their trial.
create or replace function public.claim_trial(p_user uuid, p_ref text) returns boolean
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_key text := public.user_email_key(p_user);
  v_ref text;
begin
  if v_key is null then return true; end if;
  insert into public.email_identities as i (email_key, trial_ref) values (v_key, p_ref)
  on conflict (email_key) do update
    set trial_ref = coalesce(i.trial_ref, excluded.trial_ref),
        updated_at = case when i.trial_ref is null then now() else i.updated_at end
  returning i.trial_ref into v_ref;
  return v_ref = p_ref;
end;
$$;

-- Whether this person (by inbox) has had a subscription, in any account, ever.
create or replace function public.trial_used(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.email_identities i
                 where i.email_key = public.user_email_key(p_user) and i.trial_ref is not null)
$$;

revoke execute on function public.email_key(text) from public, anon, authenticated;
revoke execute on function public.user_email_key(uuid) from public, anon, authenticated;
revoke execute on function public.claim_free_credits(uuid) from public, anon, authenticated;
revoke execute on function public.claim_trial(uuid, text) from public, anon, authenticated;
revoke execute on function public.trial_used(uuid) from public, anon, authenticated;
grant execute on function public.email_key(text), public.user_email_key(uuid),
  public.claim_free_credits(uuid), public.claim_trial(uuid, text), public.trial_used(uuid)
  to casama_worker;

-- Existing accounts: the oldest one on each inbox keeps its free credits.
insert into public.email_identities (email_key, user_id)
select distinct on (k.key) k.key, k.id
from (select public.email_key(u.email) as key, u.id, u.created_at from auth.users u) k
where k.key is not null
order by k.key, k.created_at, k.id
on conflict (email_key) do nothing;

-- Inboxes whose invite was already decided.
insert into public.email_identities as i (email_key, referral_invitee)
select distinct on (k.key) k.key, k.invitee_id
from (
  select public.email_key(u.email) as key, r.invitee_id, r.decided_at
  from public.referrals r join auth.users u on u.id = r.invitee_id
  where r.status <> 'pending'
) k
where k.key is not null
order by k.key, k.decided_at nulls last
on conflict (email_key) do update
  set referral_invitee = coalesce(i.referral_invitee, excluded.referral_invitee);

-- Everyone who already subscribed has used their trial.
insert into public.email_identities (email_key, trial_ref)
select distinct on (k.key) k.key, k.ref
from (
  select public.email_key(u.email) as key, s.source || ':' || s.external_id as ref, s.created_at
  from public.subscriptions s
  join public.organizations o on o.id = s.org_id
  join auth.users u on u.id = o.created_by
) k
where k.key is not null
order by k.key, k.created_at
on conflict (email_key) do update
  set trial_ref = coalesce(public.email_identities.trial_ref, excluded.trial_ref);

-- Referral rewards as in 20270131000101, plus: an invitee on the inviter's own inbox earns
-- nothing, and each inbox is decided once, so "+tag" accounts can't each earn a reward and a
-- welcome bonus.
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
  v_key text;
  v_first uuid;
  v_fresh boolean;
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
    -- One decision per inbox (billing audit 2026-11-17), and none on the inviter's own inbox.
    v_key := public.user_email_key(r.invitee_id);
    v_fresh := true;
    if v_key is not null then
      insert into public.email_identities as i (email_key, referral_invitee)
      values (v_key, r.invitee_id)
      on conflict (email_key) do update
        set referral_invitee = coalesce(i.referral_invitee, excluded.referral_invitee)
      returning i.referral_invitee into v_first;
      v_fresh := v_first = r.invitee_id
        and (r.inviter_id is null or v_key is distinct from public.user_email_key(r.inviter_id));
    end if;
    -- No reward without an inviter, or for one whose account is deleted or banned (D-072 bans first).
    if not v_fresh or r.inviter_id is null or coalesce(p_amount, 0) <= 0
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
    if v_fresh and coalesce(p_welcome, 0) > 0
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
