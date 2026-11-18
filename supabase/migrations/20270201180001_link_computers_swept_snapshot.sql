-- A Casama Link computer the cloud puts to sleep itself (the workspace ran out of credits or
-- computer hours) is archived to a snapshot the self-hosted server never hears about. The cloud
-- keeps it here, and the next wake-up through the proxy restores from it instead of the server's
-- older snapshot, so nothing done since is lost.
alter table public.link_computers add column if not exists swept_snapshot jsonb;
