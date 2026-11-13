-- The worker (casama_worker role) reads and writes these like every other public table: billing
-- settings (D-244), credit lots (D-246) and server capacity (D-252). The worker-role RLS test
-- (supabase/tests/worker_role_rls.test.sql) requires the policy on every table with RLS.
select public.allow_worker('public.billing_settings');
select public.allow_worker('public.credit_lots');
select public.allow_worker('public.capacity_samples');
select public.allow_worker('public.capacity_events');
select public.allow_worker('public.capacity_alerts');
