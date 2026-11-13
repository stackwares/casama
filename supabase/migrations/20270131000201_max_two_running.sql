-- Max runs 2 hosted computers at once, not 3 (D-249 follow-up), until Casama moves to a bigger
-- server: two 4 GB Max computers fit in the ~9 GB the current server has for computers; three don't.
update public.plans
   set limits = limits || '{"max_running_computers": 2}'::jsonb
 where code in ('max', 'max_yearly');

update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code in ('max', 'max_yearly');
