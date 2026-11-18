-- Puts back plan limits that later migrations lost, and gives existing workspaces the keys added
-- to plans without a backfill.
--
-- 1. 20270131000001_pricing_d249.sql replaced plans.limits wholesale instead of merging, so the
--    D-247 check-in limits from 20270130000001_proactive.sql (max_proactive_bots, min_scan_hours,
--    event_scans) were dropped from every plan, and its entitlement recompute dropped them from every
--    workspace. With no key the server applies no limit: any number of bots check in, scans as often
--    as asked, and app events start scans on Free.
-- 2. 20270201000501_creation_files.sql added storage_gb to plans but not to entitlements, and the
--    storage cap reads entitlements, so workspaces made before it have no Library cap.
--
-- Plan values come from D-247 and the migrations that added each key. A key a plan already has
-- (say, edited from the Admin screen) is kept: the defaults go on the left of ||.

update public.plans set limits =
  '{"max_proactive_bots": 1, "min_scan_hours": 12, "event_scans": 0, "storage_gb": 1, "remote_servers": 1, "link_live_view": 0}'::jsonb
  || limits
where code = 'free';

update public.plans set limits =
  '{"max_proactive_bots": 2, "min_scan_hours": 3, "event_scans": 1, "storage_gb": 10, "remote_servers": 1, "link_live_view": 1}'::jsonb
  || limits
where code in ('plus', 'plus_yearly');

update public.plans set limits =
  '{"max_proactive_bots": 5, "min_scan_hours": 1, "event_scans": 1, "storage_gb": 50, "remote_servers": 3, "link_live_view": 1}'::jsonb
  || limits
where code in ('pro', 'pro_yearly');

update public.plans set limits =
  '{"max_proactive_bots": 20, "min_scan_hours": 1, "event_scans": 1, "storage_gb": 200, "remote_servers": 10, "link_live_view": 1}'::jsonb
  || limits
where code in ('max', 'max_yearly');

-- Every workspace's limits again from the one formula (plan, extra people, trial, then the owner's
-- overrides on top), the way the server and the Admin screen compute them. Self-hosted keeps its own.
update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';
