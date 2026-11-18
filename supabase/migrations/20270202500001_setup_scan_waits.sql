-- The setup scan (D-263) waits its few minutes for the apps people connect from the empty chat.
-- It used to keep the regular schedule's next run when that came sooner, so onboarding just
-- before a 3-hour mark looked around at the mark, before anything was connected. A setup request
-- now sets the time itself, unless a connection or app event already asked for a scan.
create or replace function public.request_checkin_scan(p_bot uuid, p_reason text, p_delay interval default interval '2 minutes')
returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_ok boolean;
  v_asked boolean;
begin
  select scan_requested_at is not null into v_asked from public.bot_checkins where bot_id = p_bot;
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
  set next_run_at = case
    when p_reason = 'setup' and not coalesce(v_asked, false) then now() + p_delay
    else least(coalesce(next_run_at, now() + p_delay), now() + p_delay) end
  where bot_id = p_bot and kind = 'scan' and enabled;
  return true;
end;
$$;
revoke execute on function public.request_checkin_scan(uuid, text, interval) from public, anon, authenticated;
grant execute on function public.request_checkin_scan(uuid, text, interval) to casama_worker;
