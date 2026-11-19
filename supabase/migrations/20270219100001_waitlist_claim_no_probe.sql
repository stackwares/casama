-- D-427 waitlist: an invite claim no longer says who has an account (docs/WAITLIST-PLAN.md §5.3).
-- Before, an address with an account (or already let in) was answered "admitted" even with a code
-- that had no invites left, where a stranger got "waitlisted": redeeming any locked or used-up code
-- (every member's own code is locked until first use) told whether an email had an account. Now
-- they get the stranger's answer for that code, and still use up and change nothing. The account
-- check also matches every spelling of the same inbox (email_key), so "a.b+x@gmail.com" can't
-- spend an invite on an address that already has an account.

create or replace function public.waitlist_claim(
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
  v_came_via text;
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

  if v_kind = 'one_time' then
    v_ok := v_issuer.one_time_used_at is null;
  elsif v_kind = 'campaign' then
    v_ok := coalesce(public.invite_campaign_open(v_camp.code), false);
  else
    v_ok := public.invites_unlocked(v_inviter)
      and public.invites_used(v_inviter) < greatest(coalesce(p_per_person, 0), 0) + coalesce(v_bonus, 0);
  end if;

  -- Someone already let in, or who already has an account (any spelling of the same inbox), uses
  -- up nothing and changes nothing. They get the answer a stranger would get for this code, so the
  -- answer never says who has an account or who is on the list. The one exception is the address
  -- this very code let in (a second tap on the same link), which only someone holding it can ask.
  select w.status, w.admitted_via into v_status, v_came_via
  from public.waitlist_entries w where w.email_key = v_key for update;
  if v_status in ('admitted', 'joined')
     or exists (select 1 from auth.users u
                where lower(u.email::text) = v_email or public.email_key(u.email::text) = v_key)
     or exists (select 1 from public.email_identities i
                join auth.users u on u.id = i.user_id where i.email_key = v_key) then
    return query select case when v_ok or v_came_via is not distinct from v_via
                             then 'admitted' else 'waitlisted' end, v_kind, v_label,
      v_inviter, false;
    return;
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
