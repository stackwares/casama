begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
     and not exists (select 1 from pg_policies p where p.schemaname = 'public'
                     and p.tablename = c.relname and p.policyname = 'kasama_worker_all')),
  0,
  'every table with RLS has the worker policy (new tables call public.allow_worker)');

select ok(not (select rolsuper or rolbypassrls from pg_roles where rolname = 'kasama_worker'),
  'the worker role is neither superuser nor RLS-bypassing');

set local role kasama_worker;
select lives_ok($$ select count(*) from public.runs $$, 'the worker reads public tables');
select lives_ok($$ select public.worker_owner_email_verified(gen_random_uuid()) $$, 'the worker checks owner email verification');
select throws_ok($$ select email from auth.users limit 1 $$, '42501', null, 'but never reads auth.users');
select throws_ok($$ create table public.worker_should_not_create (id int) $$, '42501', null, 'and cannot change the schema');
reset role;

select * from finish();
rollback;
