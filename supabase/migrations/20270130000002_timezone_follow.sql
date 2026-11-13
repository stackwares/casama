-- Timezones that follow the person (D-250). The apps now save the device's IANA timezone to
-- profiles.timezone (it stayed at the 'UTC' default before, so briefs, quiet hours and routines
-- ran on UTC for everyone). When it changes, the person's routines move with it:
--  * the brief and scan routines of bots that check in for them;
--  * their other scheduled routines that were still on their previous timezone (an explicitly
--    chosen different zone stays).
-- The worker recomputes next_run_at for routines marked retime_pending, within a minute.

alter table public.routines add column retime_pending boolean not null default false;
create index routines_retime_idx on public.routines (id) where retime_pending;

create or replace function public.follow_profile_timezone()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.timezone is not distinct from old.timezone then return new; end if;
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    raise exception 'Unknown timezone %', new.timezone using errcode = '22023';
  end if;
  update public.routines r
  set timezone = new.timezone, retime_pending = true
  where r.schedule_cron is not null
    and (
      (r.kind in ('brief', 'scan')
        and exists (select 1 from public.bot_checkins ck where ck.bot_id = r.bot_id and ck.user_id = new.user_id))
      or (r.kind = 'task' and r.created_by = new.user_id and r.timezone = old.timezone)
    );
  return new;
end;
$$;
create trigger profiles_follow_timezone
  after update of timezone on public.profiles
  for each row execute function public.follow_profile_timezone();
