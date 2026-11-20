begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into public.vendor_limits (vendor, label, kind, unit)
values ('test-vendor', 'Test vendor', 'quota', 'requests');
insert into public.vendor_counts (vendor, day, count) values ('test-vendor', current_date, 1);
select throws_ok($$insert into public.vendor_counts (vendor, day, count) values ('test-vendor', current_date + 1, -1)$$,
  '23514', null, 'negative counts are rejected');
select throws_ok($$insert into public.vendor_limits (vendor, label, kind, unit, warn_at)
  values ('invalid', 'Invalid', 'quota', 'requests', 0)$$,
  '23514', null, 'invalid warning threshold is rejected');
select ok((select relrowsecurity from pg_class where oid = 'public.vendor_limits'::regclass), 'limits have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.vendor_checks'::regclass), 'checks have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.vendor_counts'::regclass), 'counts have RLS');
select ok(exists (select 1 from pg_policies where tablename = 'vendor_limits' and policyname = 'casama_worker_all'), 'worker can access limits');
select ok(exists (select 1 from pg_policies where tablename = 'vendor_checks' and policyname = 'casama_worker_all'), 'worker can access checks');
select ok(exists (select 1 from pg_policies where tablename = 'vendor_counts' and policyname = 'casama_worker_all'), 'worker can access counts');
set local role casama_worker;
select lives_ok($$insert into public.vendor_counts (vendor, day, count)
  values ('test-vendor', current_date, 2)
  on conflict (vendor, day) do update set count = vendor_counts.count + excluded.count$$,
  'worker can increment a daily count atomically');
select is((select count::int from public.vendor_counts where vendor = 'test-vendor'), 3,
  'an increment adds to the existing count');
select lives_ok($$insert into public.vendor_checks (vendor, used, limit_value, status, source)
  values ('test-vendor', 3, 100, 'ok', 'own_count')$$, 'worker can record a check');
reset role;
set local role authenticated;
select throws_ok($$select * from public.vendor_limits$$, '42501', null, 'users cannot read limits directly');
select throws_ok($$select * from public.vendor_checks$$, '42501', null, 'users cannot read checks directly');
select throws_ok($$select * from public.vendor_counts$$, '42501', null, 'users cannot read counts directly');
reset role;
select * from finish();
rollback;
