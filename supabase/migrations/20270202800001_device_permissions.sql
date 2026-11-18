-- System permissions on the person's own devices (D-376, docs/OS-PERMISSIONS-PLAN.md).
--
-- Each device reports its permissions as the system has them, checked without prompting:
-- { "<permission id>": "granted" | "limited" | "denied" | "not_asked" | "restricted" | "unknown" | "unavailable" }.
-- permission_snoozes holds "Not now" per bot and permission: { "<bot id>:<permission id>": "<until, ISO time>" }.
-- RLS stays as it is: the owner (and workspace admins for local_devices) already read these rows,
-- the API writes them, and the worker already has access to both tables.

alter table public.local_devices
  add column permissions jsonb not null default '{}'::jsonb,
  add column permissions_at timestamptz,
  add column permission_snoozes jsonb not null default '{}'::jsonb;

alter table public.device_sources
  add column permissions jsonb not null default '{}'::jsonb,
  add column permissions_at timestamptz,
  add column permission_snoozes jsonb not null default '{}'::jsonb;
