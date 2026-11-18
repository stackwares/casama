-- D-323 (Casama for Chrome, Phase 3): bots in the person's own browser.

-- C1: a browser-only local device. It has no computer of its own (a bot keeps its computer for
-- shell and files and uses this browser only for browser tools), so computer_id stays null.
alter table public.local_devices drop constraint if exists local_devices_platform_check;
alter table public.local_devices add constraint local_devices_platform_check
  check (platform in ('macos', 'windows', 'linux', 'chrome'));
-- C6: per-site answers for Act on this browser. "Always" sites go without asking; "never" sites are
-- refused; anything else asks the first time in the run.
alter table public.local_devices add column if not exists allowed_sites text[] not null default '{}'
  check (cardinality(allowed_sites) <= 500);
alter table public.local_devices add column if not exists blocked_sites text[] not null default '{}'
  check (cardinality(blocked_sites) <= 500);
-- Kinds of site that are off by default (banking, health, passwords, government) the person
-- switched back on for Act on this browser. They still ask every time.
alter table public.local_devices add column if not exists allowed_kinds text[] not null default '{}'
  check (allowed_kinds <@ array['banking', 'health', 'passwords', 'government']::text[]);

-- G9: workspace switches for the extension and for Act, and the workspace's own site lists.
alter table public.organizations add column if not exists chrome_extension boolean not null default true;
alter table public.organizations add column if not exists chrome_act boolean not null default true;
alter table public.organizations add column if not exists chrome_blocked_sites text[] not null default '{}'
  check (cardinality(chrome_blocked_sites) <= 500);

-- C11: teach by showing in the browser. A recording made in a browser tab belongs to that browser
-- (device_id) rather than a computer, and its steps name the element (role and label) instead of
-- screen coordinates. Pages are opened by address ("open").
alter table public.teach_sessions alter column computer_id drop not null;
alter table public.teach_sessions add column if not exists device_id uuid
  references public.local_devices (id) on delete cascade;
alter table public.teach_sessions drop constraint if exists teach_sessions_where;
alter table public.teach_sessions add constraint teach_sessions_where
  check (computer_id is not null or device_id is not null);
create unique index if not exists teach_sessions_device_recording_idx on public.teach_sessions (device_id)
  where status = 'recording';
alter table public.teach_steps drop constraint if exists teach_steps_kind_check;
alter table public.teach_steps add constraint teach_steps_kind_check
  check (kind in ('click', 'type', 'key', 'scroll', 'open'));
alter table public.teach_steps add column if not exists target jsonb
  check (target is null or (jsonb_typeof(target) = 'object' and octet_length(target::text) <= 600));

-- C13: where a routine's browser work happens. "computer": the bot's own computer (as before);
-- "mine": the person's browser, waiting for it to come online; "mine_or_computer": the person's
-- browser when it's online, else the bot's computer.
alter table public.routines add column if not exists browser text not null default 'computer'
  check (browser in ('computer', 'mine', 'mine_or_computer'));
