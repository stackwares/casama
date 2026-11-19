-- Waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md).
--
-- While the gate is on, Auth's before-user-created hook lets a new account through only for an
-- email address that has been let in. Everything that lets someone in does the same thing: it
-- marks that address `admitted` here. The gate itself is a setting (instance_settings key
-- "signup_gate"); with no row there, sign-up is open, so this migration changes nothing by itself.
--
-- Only the API reads these tables (no policy for anon or authenticated), and the functions that
-- admit or claim are executable by the API's role alone: D-211's audit found a redeem function
-- that anyone signed in could call through PostgREST.

-- --------------------------------------------------------------------------- entries
-- One row per inbox (email_key is the normalised-email hash of D-333: no "+tag", no Gmail dots).
--   waiting   on the list. `queued_at` set: chosen for the next "You're in" emails.
--   admitted  may make an account (the hook checks this).
--   joined    made one (`user_id`).
-- `priority` sorts batches: 10 for someone whose invite code had run out.
create table public.waitlist_entries (
  id uuid primary key default gen_random_uuid(),
  email extensions.citext not null,
  email_key text not null unique,
  status text not null default 'waiting' check (status in ('waiting', 'admitted', 'joined')),
  source text check (char_length(source) <= 64),
  ref text check (char_length(ref) <= 64),
  self_hosting boolean not null default false,
  note text check (char_length(note) <= 280),
  newsletter_opt_in boolean not null default false,
  newsletter_consent_at timestamptz,
  newsletter_wording text check (char_length(newsletter_wording) <= 64),
  priority integer not null default 0,
  queued_at timestamptz,
  queued_by uuid,
  admitted_at timestamptz,
  -- batch, auto, admin, campaign:<code>, invite:<inviter id>
  admitted_via text check (char_length(admitted_via) <= 80),
  invite_code text check (char_length(invite_code) <= 40),
  inviter_id uuid references auth.users (id) on delete set null,
  notified_at timestamptz,
  notify_attempts integer not null default 0,
  notify_error text,
  user_id uuid references auth.users (id) on delete set null,
  joined_at timestamptz,
  -- A keyed hash of the caller's address, for abuse checks; cleared after 30 days.
  ip_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index waitlist_entries_pick_idx on public.waitlist_entries (priority desc, created_at)
  where status = 'waiting' and queued_at is null;
create index waitlist_entries_queued_idx on public.waitlist_entries (queued_at)
  where status = 'waiting' and queued_at is not null;
create index waitlist_entries_admitted_idx on public.waitlist_entries (admitted_at)
  where status = 'admitted';
create index waitlist_entries_inviter_idx on public.waitlist_entries (inviter_id)
  where inviter_id is not null;
create index waitlist_entries_notified_idx on public.waitlist_entries (notified_at)
  where notified_at is not null;
alter table public.waitlist_entries enable row level security;
revoke all on public.waitlist_entries from anon, authenticated;
select public.allow_worker('public.waitlist_entries');

-- When the account is deleted, the row keeps only what lets that inbox sign up again (its hash, as
-- email_identities does, D-333) and how it got in. The address, the line the person wrote and the
-- network hash go. The foreign key's "set null" arrives here as an update.
create or replace function public.waitlist_forget_account() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.email := '';
  new.note := null;
  new.ip_hash := null;
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function public.waitlist_forget_account() from public, anon, authenticated;
create trigger waitlist_entries_forget_account before update of user_id on public.waitlist_entries
  for each row when (old.user_id is not null and new.user_id is null)
  execute function public.waitlist_forget_account();

-- --------------------------------------------------------------------------- campaign codes
-- A shared code with a total (for example one in a launch post). 9 or more characters, or a
-- hyphen, so it can never look like a personal code (6 characters) or a workspace code (8).
create table public.invite_campaigns (
  code text primary key check (
    code ~ '^[A-Z0-9][A-Z0-9-]{2,30}[A-Z0-9]$'
    and (char_length(code) >= 9 or position('-' in code) > 0)
  ),
  label text not null check (char_length(label) between 1 and 80),
  max_uses integer not null check (max_uses >= 0),
  used integer not null default 0 check (used >= 0),
  per_day integer check (per_day > 0),
  starts_at timestamptz,
  expires_at timestamptz,
  disabled_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.invite_campaigns enable row level security;
revoke all on public.invite_campaigns from anon, authenticated;
select public.allow_worker('public.invite_campaigns');

-- --------------------------------------------------------------------------- personal invites
-- A member's invite code is their referral code (D-211). Extra invites for one person, on top of
-- the setting's number.
alter table public.referral_codes add column if not exists invite_bonus integer not null default 0
  check (invite_bonus >= 0);

-- --------------------------------------------------------------------------- what the hook asks
-- Whether this address has been let in.
create or replace function public.signup_admitted(p_email text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.waitlist_entries w
    where w.email_key = public.email_key(p_email) and w.status in ('admitted', 'joined'))
$$;

-- Whether a workspace invite for this address still stands and the workspace has a seat for it:
-- the plan's seats, minus members, minus invites sent before this one. Invites are not checked
-- against seats when they are made, so without this any workspace could let in whoever it liked.
create or replace function public.signup_invited_with_seat(p_email text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.invites i
    left join lateral (
      select e.limits -> 'seats' as seats from public.entitlements e
      where e.org_id = i.org_id order by e.created_at desc limit 1
    ) lim on true
    where lower(i.email::text) = lower(btrim(coalesce(p_email, '')))
      and i.accepted_at is null and i.expires_at > now()
      and (
        lim.seats is null or jsonb_typeof(lim.seats) <> 'number'
        or (lim.seats #>> '{}')::numeric >
           (select count(*) from public.memberships m where m.org_id = i.org_id)
           + (select count(*) from public.invites o
              where o.org_id = i.org_id and o.accepted_at is null and o.expires_at > now()
                and (o.created_at, o.id) < (i.created_at, i.id))
      ))
$$;

-- --------------------------------------------------------------------------- invites left
-- How many invites a member has used, and whether theirs are unlocked (a first finished chat).
create or replace function public.invites_used(p_user uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select count(*)::integer from public.waitlist_entries w
  where w.inviter_id = p_user and w.admitted_via = 'invite:' || p_user::text
$$;

create or replace function public.invites_unlocked(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.analytics_milestones m
                 where m.user_id = p_user and m.milestone = 'first_value')
$$;

-- Whether a campaign code can let one more person in right now.
create or replace function public.invite_campaign_open(p_code text) returns boolean
language sql stable security definer set search_path = '' as $$
  select c.disabled_at is null
    and (c.starts_at is null or c.starts_at <= now())
    and (c.expires_at is null or c.expires_at > now())
    and c.used < c.max_uses
    and (c.per_day is null or (
      select count(*) from public.waitlist_entries w
      where w.admitted_via = 'campaign:' || c.code
        and w.admitted_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc'
    ) < c.per_day)
  from public.invite_campaigns c where c.code = p_code
$$;

-- What an invite page shows: the kind, the campaign's label or the inviter's first name, and
-- whether an invite is left. No row: the code doesn't exist.
create or replace function public.invite_code_preview(p_code text, p_per_person integer)
returns table (kind text, label text, inviter_name text, available boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_inviter uuid;
  v_bonus integer;
begin
  if exists (select 1 from public.invite_campaigns c where c.code = v_code) then
    return query
      select 'campaign'::text, c.label, null::text, coalesce(public.invite_campaign_open(c.code), false)
      from public.invite_campaigns c where c.code = v_code;
    return;
  end if;
  select rc.user_id, rc.invite_bonus into v_inviter, v_bonus
  from public.referral_codes rc join auth.users u on u.id = rc.user_id
  where rc.code = v_code and (u.banned_until is null or u.banned_until < now());
  if v_inviter is null then return; end if;
  return query select 'personal'::text, null::text, public.referral_inviter_name(v_inviter),
    public.invites_unlocked(v_inviter)
      and public.invites_used(v_inviter) < greatest(coalesce(p_per_person, 0), 0) + coalesce(v_bonus, 0);
end;
$$;

-- --------------------------------------------------------------------------- claiming a code
-- Claims an invite code for an address. `outcome`:
--   admitted    the address may now sign up (or already could: someone already let in, or with
--               an account, uses up nothing);
--   waitlisted  the code is real but has no invite left (used up, over today's number, expired,
--               or the member's invites aren't unlocked yet): the address goes on the list with
--               the code as its tag and a higher priority.
-- Raises invite_not_found (P0002) for a code that doesn't exist, bad_email (22023) for an address
-- without a local part and a domain. The count and the admission happen in one transaction, with
-- the campaign row (or the inviter) locked, so the last place can't be given twice.
create or replace function public.waitlist_claim(
  p_email text, p_code text, p_per_person integer,
  p_newsletter boolean default false, p_wording text default null,
  p_source text default null, p_ip_hash text default null)
returns table (outcome text, kind text, label text, inviter_id uuid)
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_key text := public.email_key(p_email);
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_camp public.invite_campaigns%rowtype;
  v_inviter uuid;
  v_bonus integer;
  v_kind text;
  v_label text;
  v_via text;
  v_ok boolean := false;
  v_status text;
  v_news boolean := coalesce(p_newsletter, false);
begin
  if v_key is null then raise exception 'bad_email' using errcode = '22023'; end if;

  select * into v_camp from public.invite_campaigns c where c.code = v_code for update;
  if found then
    v_kind := 'campaign';
    v_label := v_camp.label;
    v_via := 'campaign:' || v_camp.code;
  else
    select rc.user_id, rc.invite_bonus into v_inviter, v_bonus
    from public.referral_codes rc join auth.users u on u.id = rc.user_id
    where rc.code = v_code and (u.banned_until is null or u.banned_until < now());
    if v_inviter is null then raise exception 'invite_not_found' using errcode = 'P0002'; end if;
    v_kind := 'personal';
    v_via := 'invite:' || v_inviter::text;
    -- One inviter at a time, so two claims can't both take the last invite.
    perform pg_advisory_xact_lock(hashtext('invite:' || v_inviter::text));
  end if;

  -- Someone already let in, or who already has an account, uses up nothing.
  select w.status into v_status from public.waitlist_entries w where w.email_key = v_key for update;
  if v_status in ('admitted', 'joined')
     or exists (select 1 from auth.users u where lower(u.email::text) = v_email)
     or exists (select 1 from public.email_identities i
                join auth.users u on u.id = i.user_id where i.email_key = v_key) then
    return query select 'admitted'::text, v_kind, v_label, v_inviter;
    return;
  end if;

  if v_kind = 'campaign' then
    v_ok := coalesce(public.invite_campaign_open(v_camp.code), false);
  else
    v_ok := public.invites_unlocked(v_inviter)
      and public.invites_used(v_inviter) < greatest(coalesce(p_per_person, 0), 0) + coalesce(v_bonus, 0);
  end if;

  insert into public.waitlist_entries as w (
    email, email_key, status, source, ip_hash, invite_code, inviter_id, priority,
    newsletter_opt_in, newsletter_consent_at, newsletter_wording, admitted_at, admitted_via)
  values (
    v_email, v_key, case when v_ok then 'admitted' else 'waiting' end, p_source, p_ip_hash,
    v_code, v_inviter, case when v_ok then 0 else 10 end,
    v_news, case when v_news then now() end, case when v_news then p_wording end,
    case when v_ok then now() end, case when v_ok then v_via end)
  on conflict (email_key) do update set
    status = case when v_ok then 'admitted' else w.status end,
    admitted_at = case when v_ok then now() else w.admitted_at end,
    admitted_via = case when v_ok then v_via else w.admitted_via end,
    -- Let in on the page, so no "You're in" email is owed.
    queued_at = case when v_ok then null else w.queued_at end,
    priority = case when v_ok then w.priority else greatest(w.priority, 10) end,
    invite_code = v_code,
    inviter_id = coalesce(v_inviter, w.inviter_id),
    newsletter_opt_in = w.newsletter_opt_in or v_news,
    newsletter_consent_at = case when v_news and not w.newsletter_opt_in then now()
                                 else w.newsletter_consent_at end,
    newsletter_wording = case when v_news and not w.newsletter_opt_in then p_wording
                              else w.newsletter_wording end,
    updated_at = now();

  if v_ok and v_kind = 'campaign' then
    update public.invite_campaigns c set used = c.used + 1 where c.code = v_camp.code;
  end if;

  return query select case when v_ok then 'admitted' else 'waitlisted' end, v_kind, v_label, v_inviter;
end;
$$;

-- --------------------------------------------------------------------------- after sign-up
-- Worker: ties people who were let in to the account they made (matched on the inbox), and
-- attaches the friend's referral when they came through a member's invite (`p_referrals`), so
-- D-211's rewards follow with no second tap: claiming the invite was the friend's choice.
-- Returns what was tied, for the monthly-email choice.
create or replace function public.worker_waitlist_link(p_referrals boolean, p_limit integer default 100)
returns table (entry_id uuid, user_id uuid, newsletter boolean, referral_attached boolean)
language plpgsql volatile security definer set search_path = '' as $$
declare
  r record;
  v_code text;
  v_attached boolean;
begin
  for r in
    select w.id, u.id as uid, u.created_at as signed_up, w.inviter_id as inviter, w.newsletter_opt_in
    from public.waitlist_entries w
    join auth.users u on public.email_key(u.email) = w.email_key
    where w.status = 'admitted' and w.user_id is null
      and u.created_at > now() - interval '14 days'
    order by u.created_at
    limit greatest(1, least(p_limit, 1000))
    for update of w skip locked
  loop
    v_attached := false;
    if p_referrals and r.inviter is not null and r.inviter <> r.uid
       and not exists (select 1 from public.referrals x where x.invitee_id = r.uid)
       and not exists (select 1 from public.referrals x
                       where x.invitee_id = r.inviter and x.inviter_id = r.uid) then
      select rc.code into v_code from public.referral_codes rc where rc.user_id = r.inviter;
      if v_code is not null then
        insert into public.referrals (invitee_id, inviter_id, code) values (r.uid, r.inviter, v_code)
        on conflict (invitee_id) do nothing;
        v_attached := found;
      end if;
    end if;
    update public.waitlist_entries w
      set status = 'joined', user_id = r.uid, joined_at = r.signed_up, updated_at = now()
      where w.id = r.id;
    return query select r.id, r.uid, r.newsletter_opt_in, v_attached;
  end loop;
end;
$$;

-- --------------------------------------------------------------------------- who may call what
revoke all on function public.signup_admitted(text) from public, anon, authenticated;
revoke all on function public.signup_invited_with_seat(text) from public, anon, authenticated;
revoke all on function public.invites_used(uuid) from public, anon, authenticated;
revoke all on function public.invites_unlocked(uuid) from public, anon, authenticated;
revoke all on function public.invite_campaign_open(text) from public, anon, authenticated;
revoke all on function public.invite_code_preview(text, integer) from public, anon, authenticated;
revoke all on function public.waitlist_claim(text, text, integer, boolean, text, text, text)
  from public, anon, authenticated;
revoke all on function public.worker_waitlist_link(boolean, integer) from public, anon, authenticated;
grant execute on function public.worker_waitlist_link(boolean, integer) to casama_worker;
