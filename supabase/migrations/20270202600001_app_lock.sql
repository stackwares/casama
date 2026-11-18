-- D-375: a workspace can require the app lock on its members' devices. The app reads the flag from
-- the workspace list and won't open the workspace's data until the lock is on. Only owners and
-- admins change it (organizations_update needs the admin role); the API checks that too.
alter table public.organizations add column if not exists require_app_lock boolean not null default false;
