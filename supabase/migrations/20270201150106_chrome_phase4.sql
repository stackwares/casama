-- D-323 (Casama for Chrome, Phase 4): the browser as a device.
--
-- E2: "browser_tab", the tab in front, read when a bot the person allowed asks (live only: never
-- stored, retention 0). E6: "browser_history", pages from the browser's history and bookmarks
-- matching a search, on request (live only too). Both are kinds of a device source with platform
-- "web" (the extension), granted per bot like phone data (D-149). The server never stores them
-- (it forces retention 0); the readings check gains them only so both checks keep one list.
alter table public.device_readings drop constraint device_readings_kind_check;
alter table public.device_readings add constraint device_readings_kind_check
  check (kind in ('calendar', 'reminders', 'contacts', 'places', 'photos', 'health', 'notifications', 'activity',
                  'browser_tab', 'browser_history'));
alter table public.device_grants drop constraint device_grants_kind_check;
alter table public.device_grants add constraint device_grants_kind_check
  check (kind in ('calendar', 'reminders', 'contacts', 'places', 'photos', 'health', 'notifications', 'activity',
                  'browser_tab', 'browser_history'));

-- E3: a person's own device (the desktop app on Windows or Linux) asks their browser for its tab:
-- such a request belongs to no run.
comment on column public.device_requests.run_id is 'The run that asked; null when one of the person''s own devices asked (D-323 E3)';
