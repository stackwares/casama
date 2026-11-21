-- The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md): a third place a bot can browse,
-- next to its own computer and the person's Chrome (D-323).

-- A browser-only device inside the Casama app on a phone or tablet. Like "chrome" it has no
-- computer of its own. One value for both systems; `system` says which.
alter table public.local_devices drop constraint if exists local_devices_platform_check;
alter table public.local_devices add constraint local_devices_platform_check
  check (platform in ('macos', 'windows', 'linux', 'chrome', 'app'));
alter table public.local_devices add column if not exists system text
  check (system is null or system in ('ios', 'android'));
-- The app's chat-focus client id (chat_focus.client_id), so the server can tell that a chat is
-- open on this very phone before a bot may use its browser.
alter table public.local_devices add column if not exists client_id text
  check (client_id is null or char_length(client_id) between 8 and 64);
-- One phone browser per app install and workspace: pairing again replaces the old row's token.
create unique index if not exists local_devices_app_client_idx
  on public.local_devices (org_id, user_id, client_id) where platform = 'app';

-- The workspace switch, beside "Bots in Members' Browsers" (chrome_act). On by default; the
-- instance's stage (instance_settings key "app_browser") decides whether anyone has it at all.
alter table public.organizations add column if not exists app_browser boolean not null default true;
