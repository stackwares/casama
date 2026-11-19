-- Waitlist and invite gate, Phases 2 and 3 (docs/WAITLIST-PLAN.md §7.3, §6.4, §11).
--
-- 1. One-time codes: every "You're in" email carries a code that lets ONE more address in (someone
--    who will sign in with another address, such as Apple's Hide My Email). Shape: 8 Crockford
--    base32 characters shown as XXXX-XXXX, so it can't be mistaken for a member's 6-character code
--    or an 8-character workspace code (those never carry a hyphen, and the invite routes never take
--    workspace codes). A campaign code may have the same shape (SHOW-HN26): a claim looks the value
--    up as a handed-out one-time code first and falls back to campaigns, and a random 8-character
--    code matching a campaign's name is a one-in-10^12 chance.
-- 2. The daily automatic batch: one row per day it ran (or chose not to), claimed by insert, so two
--    workers can't both run a day.
-- 3. How a person got in, for the signed_up and first_value analytics events.

-- --------------------------------------------------------------------------- one-time codes
-- Stored as a SHA-256 hash, never the code: it is a bearer credential that is shown once, in the
-- email, and nobody (the worker, Admin, a backup) needs to read it back. A hash costs nothing here
-- because the claim only ever looks a code up by its value.
alter table public.waitlist_entries
  add column if not exists one_time_code_hash text unique
    check (one_time_code_hash ~ '^[0-9a-f]{64}$'),
  add column if not exists one_time_used_at timestamptz,
  -- The inbox it let in (its email_key hash), not the address.
  add column if not exists one_time_used_for text;

-- --------------------------------------------------------------------------- claiming, now with
-- one-time codes and whether this call let someone in (for the waitlist_admitted event).
drop function if exists public.waitlist_claim(text, text, integer, boolean, text, text, text);
create function public.waitlist_claim(
  p_email text, p_code text, p_per_person integer,
  p_newsletter boolean default false, p_wording text default null,
  p_source text default null, p_ip_hash text default null)
returns table (outcome text, kind text, label text, inviter_id uuid, admitted_now boolean)
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_key text := public.email_key(p_email);
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_camp public.invite_campaigns%rowtype;
  v_issuer public.waitlist_entries%rowtype;
  v_inviter uuid;
  v_bonus integer;
  v_kind text;
  v_label text;
  v_via text;
  v_tag text;
  v_ok boolean := false;
  v_status text;
  v_news boolean := coalesce(p_newsletter, false);
begin
  if v_key is null then raise exception 'bad_email' using errcode = '22023'; end if;

  -- A "You're in" email's one-time code, when one with this value was handed out.
  if v_code ~ '^[0-9A-Z]{4}-[0-9A-Z]{4}$' then
    select * into v_issuer from public.waitlist_entries w
    where w.one_time_code_hash = encode(sha256(convert_to(replace(v_code, '-', ''), 'UTF8')), 'hex')
      and w.status in ('admitted', 'joined')
    for update;
    if found then
      v_kind := 'one_time';
      v_via := 'one_time:' || v_issuer.id::text;
      -- Never the code itself on the entry it lets in.
      v_tag := 'ONE-TIME';
    end if;
  end if;

  if v_kind is null then
    select * into v_camp from public.invite_campaigns c where c.code = v_code for update;
    if found then
      v_kind := 'campaign';
      v_label := v_camp.label;
      v_via := 'campaign:' || v_camp.code;
      v_tag := v_camp.code;
    else
      select rc.user_id, rc.invite_bonus into v_inviter, v_bonus
      from public.referral_codes rc join auth.users u on u.id = rc.user_id
      where rc.code = v_code and (u.banned_until is null or u.banned_until < now());
      if v_inviter is null then raise exception 'invite_not_found' using errcode = 'P0002'; end if;
      v_kind := 'personal';
      v_via := 'invite:' || v_inviter::text;
      v_tag := v_code;
      -- One inviter at a time, so two claims can't both take the last invite.
      perform pg_advisory_xact_lock(hashtext('invite:' || v_inviter::text));
    end if;
  end if;

  -- Someone already let in, or who already has an account, uses up nothing.
  select w.status into v_status from public.waitlist_entries w where w.email_key = v_key for update;
  if v_status in ('admitted', 'joined')
     or exists (select 1 from auth.users u where lower(u.email::text) = v_email)
     or exists (select 1 from public.email_identities i
                join auth.users u on u.id = i.user_id where i.email_key = v_key) then
    return query select 'admitted'::text, v_kind, v_label, v_inviter, false;
    return;
  end if;

  if v_kind = 'one_time' then
    v_ok := v_issuer.one_time_used_at is null;
  elsif v_kind = 'campaign' then
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
    v_tag, v_inviter, case when v_ok then 0 else 10 end,
    v_news, case when v_news then now() end, case when v_news then p_wording end,
    case when v_ok then now() end, case when v_ok then v_via end)
  on conflict (email_key) do update set
    status = case when v_ok then 'admitted' else w.status end,
    admitted_at = case when v_ok then now() else w.admitted_at end,
    admitted_via = case when v_ok then v_via else w.admitted_via end,
    -- Let in on the page, so no "You're in" email is owed.
    queued_at = case when v_ok then null else w.queued_at end,
    priority = case when v_ok then w.priority else greatest(w.priority, 10) end,
    invite_code = v_tag,
    inviter_id = coalesce(v_inviter, w.inviter_id),
    newsletter_opt_in = w.newsletter_opt_in or v_news,
    newsletter_consent_at = case when v_news and not w.newsletter_opt_in then now()
                                 else w.newsletter_consent_at end,
    newsletter_wording = case when v_news and not w.newsletter_opt_in then p_wording
                              else w.newsletter_wording end,
    updated_at = now();

  if v_ok and v_kind = 'campaign' then
    update public.invite_campaigns c set used = c.used + 1 where c.code = v_camp.code;
  elsif v_ok and v_kind = 'one_time' then
    update public.waitlist_entries w set one_time_used_at = now(), one_time_used_for = v_key,
      updated_at = now()
    where w.id = v_issuer.id;
  end if;

  return query select case when v_ok then 'admitted' else 'waitlisted' end, v_kind, v_label, v_inviter, v_ok;
end;
$$;
revoke all on function public.waitlist_claim(text, text, integer, boolean, text, text, text)
  from public, anon, authenticated;

-- What an invite page shows, now also for one-time codes (no label, no inviter).
create or replace function public.invite_code_preview(p_code text, p_per_person integer)
returns table (kind text, label text, inviter_name text, available boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_inviter uuid;
  v_bonus integer;
begin
  if v_code ~ '^[0-9A-Z]{4}-[0-9A-Z]{4}$' then
    return query
      select 'one_time'::text, null::text, null::text, w.one_time_used_at is null
      from public.waitlist_entries w
      where w.one_time_code_hash = encode(sha256(convert_to(replace(v_code, '-', ''), 'UTF8')), 'hex')
        and w.status in ('admitted', 'joined');
    if found then return; end if;
  end if;
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
revoke all on function public.invite_code_preview(text, integer) from public, anon, authenticated;

-- --------------------------------------------------------------------------- the daily batch
-- One row per UTC day the automatic batch ran: how many it chose, or why it skipped the day
-- (capacity, model_spend, no_mail, nobody_waiting, error). Inserting the row claims the day.
create table public.waitlist_batches (
  day date primary key,
  ran_at timestamptz not null default now(),
  admitted integer not null default 0 check (admitted >= 0),
  skipped_reason text check (char_length(skipped_reason) <= 40),
  detail text check (char_length(detail) <= 500)
);
alter table public.waitlist_batches enable row level security;
revoke all on public.waitlist_batches from anon, authenticated;
select public.allow_worker('public.waitlist_batches');

-- --------------------------------------------------------------------------- for analytics
-- How each of these people got in, as one of: batch (the daily automatic batch), hand (an owner
-- chose them or added them), code (an invite, campaign or one-time code), none (no entry: the gate
-- was open, a workspace invite, or a self-hosted server). Matched on the inbox, so it works before
-- the worker has tied the account to its entry. Never returns an address.
create or replace function public.worker_admitted_via(p_users uuid[])
returns table (user_id uuid, admitted_via text)
language sql stable security definer set search_path = '' as $$
  select u.id,
    case
      when w.admitted_via is null then 'none'
      when w.admitted_via = 'auto' then 'batch'
      when w.admitted_via in ('batch', 'admin') then 'hand'
      when w.admitted_via like 'campaign:%' or w.admitted_via like 'invite:%'
        or w.admitted_via like 'one_time:%' then 'code'
      else 'none'
    end
  from auth.users u
  left join lateral (
    select e.admitted_via from public.waitlist_entries e
    where e.user_id = u.id or e.email_key = public.email_key(u.email)
    order by coalesce(e.user_id = u.id, false) desc limit 1
  ) w on true
  where u.id = any(p_users)
$$;
revoke all on function public.worker_admitted_via(uuid[]) from public, anon, authenticated;
grant execute on function public.worker_admitted_via(uuid[]) to casama_worker;
