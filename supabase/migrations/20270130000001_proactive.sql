-- Proactive bots (D-247). Check-ins become the way a bot reaches out first:
--  * a scan can be asked for off schedule: right after setup (once, with a summary push), when an
--    app is connected, or when a connected app reports something new (Composio triggers);
--  * suggestions carry the line the push shows ("Want me to…?") and can wait for a set time;
--  * Android apps that draw suggestion pushes themselves (with Do it / Not now buttons) say so;
--  * plans limit how many bots may check in, how often, and whether app events start scans.

alter table public.bot_checkins
  add column scan_requested_at timestamptz,
  add column scan_reason text check (scan_reason in ('setup', 'connection', 'event')),
  -- When the "You're all set" summary went out (the setup scan runs once per bot).
  add column welcomed_at timestamptz;

alter table public.suggestions
  add column push_text text check (char_length(push_text) <= 240),
  -- Held until this time (for example an hour before a show); null pushes right away.
  add column notify_at timestamptz,
  add column notified_at timestamptz;
create index suggestions_notify_due_idx on public.suggestions (notify_at)
  where status = 'pending' and notified_at is null and notify_at is not null;

alter table public.devices
  add column data_pushes boolean not null default false;

-- Plan limits, added to the existing rows (the Admin plan editor shows them with the rest).
update public.plans set limits = limits || '{"max_proactive_bots": 1, "min_scan_hours": 12, "event_scans": 0}'::jsonb
where code = 'free';
update public.plans set limits = limits || '{"max_proactive_bots": 2, "min_scan_hours": 3, "event_scans": 1}'::jsonb
where code in ('plus', 'plus_yearly');
update public.plans set limits = limits || '{"max_proactive_bots": 5, "min_scan_hours": 1, "event_scans": 1}'::jsonb
where code in ('pro', 'pro_yearly');
update public.plans set limits = limits || '{"max_proactive_bots": 20, "min_scan_hours": 1, "event_scans": 1}'::jsonb
where code in ('max', 'max_yearly');
-- Workspaces already on a plan get the new keys now (their own values, if any, win).
update public.entitlements e
set limits = jsonb_strip_nulls(jsonb_build_object(
      'max_proactive_bots', p.limits -> 'max_proactive_bots',
      'min_scan_hours', p.limits -> 'min_scan_hours',
      'event_scans', p.limits -> 'event_scans')) || e.limits
from public.plans p
where p.code = e.plan_code and p.limits ? 'max_proactive_bots';

-- Asks for a check-in scan soon. Setup scans happen once per bot; the strongest reason wins when
-- several requests meet (setup, then connection, then event). Returns whether a scan is coming.
create or replace function public.request_checkin_scan(p_bot uuid, p_reason text, p_delay interval default interval '2 minutes')
returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_ok boolean;
begin
  update public.bot_checkins set
    scan_requested_at = coalesce(scan_requested_at, now()),
    scan_reason = case
      when scan_reason = 'setup' or p_reason = 'setup' then 'setup'
      when scan_reason = 'connection' or p_reason = 'connection' then 'connection'
      else 'event' end
  where bot_id = p_bot and enabled and (p_reason <> 'setup' or welcomed_at is null)
  returning true into v_ok;
  if not coalesce(v_ok, false) then return false; end if;
  update public.routines
  set next_run_at = least(coalesce(next_run_at, now() + p_delay), now() + p_delay)
  where bot_id = p_bot and kind = 'scan' and enabled;
  return true;
end;
$$;
revoke execute on function public.request_checkin_scan(uuid, text, interval) from public, anon, authenticated;
grant execute on function public.request_checkin_scan(uuid, text, interval) to casama_worker;

-- A new connection (an integration turning ok, or a managed Composio connection gaining an app)
-- asks the bots that check in and can use it for a scan, so they look at it within minutes.
create or replace function public.scan_on_new_connection()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_bot uuid;
begin
  if new.status <> 'ok' then return new; end if;
  if tg_op = 'UPDATE' and old.status = 'ok'
     and coalesce(jsonb_array_length(case when jsonb_typeof(new.config -> 'toolkits') = 'array' then new.config -> 'toolkits' end), 0)
      <= coalesce(jsonb_array_length(case when jsonb_typeof(old.config -> 'toolkits') = 'array' then old.config -> 'toolkits' end), 0)
  then
    return new;
  end if;
  for v_bot in
    select ck.bot_id from public.bot_checkins ck
    where ck.org_id = new.org_id and ck.enabled
      and (exists (select 1 from public.bot_integrations bi where bi.bot_id = ck.bot_id and bi.integration_id = new.id)
           or not exists (select 1 from public.bot_integrations bi where bi.integration_id = new.id))
  loop
    perform public.request_checkin_scan(v_bot, 'connection', interval '3 minutes');
  end loop;
  return new;
end;
$$;
create trigger integrations_scan_on_connect
  after insert or update of status, config on public.integrations
  for each row execute function public.scan_on_new_connection();

-- When a person last used Casama (D-247), so check-ins slow down for people who stopped coming
-- back: the newest of a session refresh (the app refreshes while open), a device check-in and a
-- notification read. The worker can't read auth.* itself.
create or replace function public.user_last_active(p_user uuid)
returns timestamptz
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_session timestamptz;
begin
  if to_regclass('auth.sessions') is not null then
    execute 'select max(coalesce(refreshed_at, updated_at, created_at)) from auth.sessions where user_id = $1'
      into v_session using p_user;
  end if;
  return greatest(
    v_session,
    (select max(d.last_seen_at) from public.devices d where d.user_id = p_user),
    (select max(n.read_at) from public.notifications n where n.user_id = p_user and n.read_at is not null)
  );
exception when undefined_column then
  return greatest(
    (select max(d.last_seen_at) from public.devices d where d.user_id = p_user),
    (select max(n.read_at) from public.notifications n where n.user_id = p_user and n.read_at is not null)
  );
end;
$$;
revoke execute on function public.user_last_active(uuid) from public, anon, authenticated;
grant execute on function public.user_last_active(uuid) to casama_worker;
