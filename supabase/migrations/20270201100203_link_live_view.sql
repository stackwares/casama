-- Casama Link (D-296).

-- The worker runs as its own least-privilege role (D-095) and sees a table with row-level security
-- only through this policy. It runs Casama Link's upkeep (parking idle tunnels, finishing
-- removals, forgetting old addresses and link codes), so without it that work would find no rows.
select public.allow_worker('public.link_servers');
select public.allow_worker('public.link_sign_in_requests');
select public.allow_worker('public.signin_codes');

-- Live view away from the computer goes through a relay Casama Cloud pays for by the gigabyte,
-- so it comes with paid plans. 1: the plan has it. Free: 0.
update public.plans set limits = limits || '{"link_live_view": 0}'::jsonb
where code = 'free';
update public.plans set limits = limits || '{"link_live_view": 1}'::jsonb
where code in ('plus', 'plus_yearly', 'pro', 'pro_yearly', 'max', 'max_yearly');
-- Workspaces already on a plan get the new key now (their own value, if any, wins).
update public.entitlements e
set limits = jsonb_build_object('link_live_view', p.limits -> 'link_live_view') || e.limits
from public.plans p
where p.code = e.plan_code and p.limits ? 'link_live_view';
