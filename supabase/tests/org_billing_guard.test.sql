-- Billing audit 2026-11-17: workspace admins can't rewrite billing columns or delete a workspace
-- through /rest/v1; ordinary settings still work, and the server's own writes still go through.
begin;
create extension if not exists pgtap with schema extensions;
select plan(11);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000b6a1', 'guard-owner@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000b6a1');
select public.create_organization('Guard Org', 'guard-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'guard-org'), true);

select pg_temp.login('00000000-0000-0000-0000-00000000b6a1');
select lives_ok($$ update public.organizations set name = 'Renamed', color = '#112233' where id = current_setting('test.org')::uuid $$, 'admins still change ordinary settings');
select throws_ok($$ update public.organizations set created_by = null where id = current_setting('test.org')::uuid $$, '42501', null, 'not who created it (workspace cap, free credits, trial)');
select throws_ok($$ update public.organizations set plan = 'max' where id = current_setting('test.org')::uuid $$, '42501', null, 'not the plan');
select throws_ok($$ update public.organizations set suspended_at = null, suspended_reason = 'x' where id = current_setting('test.org')::uuid $$, '42501', null, 'not a suspension');
select throws_ok($$ update public.organizations set storage_bytes = 12345 where id = current_setting('test.org')::uuid $$, '42501', null, 'not the storage counter');
select throws_ok($$ update public.organizations set region = 'eu' where id = current_setting('test.org')::uuid $$, '42501', null, 'not the region');
select throws_ok($$ delete from public.organizations where id = current_setting('test.org')::uuid $$, '42501', null, 'owners can''t delete a workspace directly');
reset role;

select is((select name from public.organizations where id = current_setting('test.org')::uuid), 'Renamed', 'the rename stuck');
select is((select created_by from public.organizations where id = current_setting('test.org')::uuid), '00000000-0000-0000-0000-00000000b6a1'::uuid, 'creator unchanged');
select lives_ok($$ update public.organizations set suspended_at = now(), storage_bytes = 5 where id = current_setting('test.org')::uuid $$, 'the server still writes them');
select is((select count(*)::int from public.organizations where id = current_setting('test.org')::uuid), 1, 'the workspace is still there');

select * from finish();
rollback;
