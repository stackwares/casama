begin;
create extension if not exists pgtap;
select plan(17);

-- Every Cloud plan carries the D-247 check-in limits and the later keys (20270201100301).
select is(
  (select count(*)::int from public.plans
    where code in ('free', 'plus', 'plus_yearly', 'pro', 'pro_yearly', 'max', 'max_yearly')
      and limits ?& array['max_proactive_bots', 'min_scan_hours', 'event_scans', 'storage_gb', 'remote_servers', 'link_live_view']),
  7, 'every Cloud plan has the check-in, storage and Link keys');
select is(
  (select jsonb_object_agg(code, limits -> 'max_proactive_bots') from public.plans where code <> 'selfhost' and interval <> 'week'),
  '{"free": 1, "plus": 2, "plus_yearly": 2, "pro": 5, "pro_yearly": 5, "max": 20, "max_yearly": 20}'::jsonb,
  'max_proactive_bots per plan (D-247)');
select is(
  (select jsonb_object_agg(code, limits -> 'min_scan_hours') from public.plans where code <> 'selfhost' and interval <> 'week'),
  '{"free": 24, "plus": 3, "plus_yearly": 3, "pro": 1, "pro_yearly": 1, "max": 1, "max_yearly": 1}'::jsonb,
  'min_scan_hours per plan (D-247; Free once a day since D-355)');
select is(
  (select jsonb_object_agg(code, limits -> 'event_scans') from public.plans where code <> 'selfhost' and interval <> 'week'),
  '{"free": 0, "plus": 1, "plus_yearly": 1, "pro": 1, "pro_yearly": 1, "max": 1, "max_yearly": 1}'::jsonb,
  'event_scans per plan (D-247)');
select is(
  (select jsonb_object_agg(code, limits -> 'storage_gb') from public.plans where code <> 'selfhost' and interval <> 'week'),
  '{"free": 1, "plus": 10, "plus_yearly": 10, "pro": 50, "pro_yearly": 50, "max": 200, "max_yearly": 200}'::jsonb,
  'storage_gb per plan');
-- The D-249 values the merge must not touch.
select is((select limits -> 'max_running_computers' from public.plans where code = 'max'), '2'::jsonb,
  'D-249 limits survive the merge');
select ok(not (select limits ? 'max_bots' from public.plans where code = 'pro'),
  'no max_bots on Pro stays unlimited (D-249)');
select is((select limits from public.plans where code = 'selfhost'), '{"unlimited": true}'::jsonb,
  'self-hosted plan keeps no limits');

-- Workspaces: one on Free, one on Pro with owner overrides, both stripped back to what prod had
-- before the fix (no storage_gb or check-in keys), then recomputed the way the migration does.
insert into public.organizations (id, name, slug, plan) values
  ('c7000000-0000-0000-0000-000000000001', 'Limits free', 'limits-free', 'free'),
  ('c7000000-0000-0000-0000-000000000002', 'Limits pro', 'limits-pro', 'pro');
select ok(
  (select limits ?& array['storage_gb', 'max_proactive_bots'] from public.entitlements
    where org_id = 'c7000000-0000-0000-0000-000000000001'),
  'a new workspace gets storage_gb and check-in limits');

update public.entitlements set plan_code = 'pro',
  overrides = '{"storage_gb": 500, "max_proactive_bots": 0}'::jsonb
 where org_id = 'c7000000-0000-0000-0000-000000000002';
update public.entitlements
   set limits = limits - array['storage_gb', 'max_proactive_bots', 'min_scan_hours', 'event_scans']
 where org_id in ('c7000000-0000-0000-0000-000000000001', 'c7000000-0000-0000-0000-000000000002');

update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';

select is((select limits -> 'storage_gb' from public.entitlements where org_id = 'c7000000-0000-0000-0000-000000000001'),
  '1'::jsonb, 'existing Free workspace gets its storage cap back');
select is((select limits -> 'min_scan_hours' from public.entitlements where org_id = 'c7000000-0000-0000-0000-000000000001'),
  '24'::jsonb, 'existing Free workspace gets its scan floor back');
select is((select limits -> 'storage_gb' from public.entitlements where org_id = 'c7000000-0000-0000-0000-000000000002'),
  '500'::jsonb, 'owner override on storage_gb wins');
select is((select limits -> 'max_proactive_bots' from public.entitlements where org_id = 'c7000000-0000-0000-0000-000000000002'),
  '0'::jsonb, 'owner override on max_proactive_bots wins');
select is((select limits -> 'event_scans' from public.entitlements where org_id = 'c7000000-0000-0000-0000-000000000002'),
  '1'::jsonb, 'keys without an override come from the plan');

-- D-432: weekly plans copy their tier's limits, without the Pro trial or extra people.
select is(
  (select jsonb_object_agg(w.code, w.limits = (m.limits - 'trial_days' - 'trial_credits_usd' - 'trial_computer_hours' - 'extra_seat_usd'))
     from public.plans w join public.plans m on m.code = replace(w.code, '_weekly', '')
    where w.interval = 'week'),
  '{"plus_weekly": true, "pro_weekly": true, "max_weekly": true}'::jsonb,
  'weekly plans have their tier''s limits');
select ok(not exists (select 1 from public.plans where interval = 'week' and limits ?| array['trial_days', 'extra_seat_usd']),
  'no trial or extra people on weekly plans');
select throws_ok($$update public.plans set interval = 'fortnight' where code = 'plus_weekly'$$,
  '23514', null, 'only none, week, month and year are intervals');

select * from finish();
rollback;
