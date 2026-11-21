-- invite_gate_holds (20270316200001, D-474) turned on row level security without the worker
-- policy every RLS table gets (worker_role_rls.test.sql). Added here rather than in that file,
-- since it may already be applied on a dev database.
select public.allow_worker('public.invite_gate_holds');
