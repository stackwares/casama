-- Full access (D-394): one workspace switch that lets every bot act without asking first, like the
-- bypass switches in Claude and ChatGPT. Off by default; only owners and admins change it (the API
-- checks). Payments, password and two-step changes and the person's own "ask" and "hand off" rules
-- still apply.
alter table public.organizations add column if not exists full_access boolean not null default false;
