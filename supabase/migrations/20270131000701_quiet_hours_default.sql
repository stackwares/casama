-- D-254: quiet hours are on by default, 22:00 to 07:00 in the person's timezone (which follows
-- their device, D-250). Before, nobody had quiet hours until they set them, so scheduled check-in
-- scans ran overnight and normal pushes could arrive at 3 a.m. Anyone can change or turn them off
-- in Settings; profiles that already chose keep their choice.
alter table public.profiles
  alter column quiet_hours set default '{"enabled": true, "start": "22:00", "end": "07:00"}'::jsonb;

update public.profiles
set quiet_hours = '{"enabled": true, "start": "22:00", "end": "07:00"}'::jsonb
where quiet_hours is null;
