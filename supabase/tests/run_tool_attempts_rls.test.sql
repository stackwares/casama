-- D-268: the worker's record of started tool calls is server-only.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000b0d1', 'own-attempts@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000b0d1');
select public.create_organization('Attempts Org', 'attempts-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'attempts-org'), true);
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'A', '00000000-0000-0000-0000-00000000b0d1');
insert into public.runs (org_id, bot_id, created_by, trigger)
  select current_setting('test.org')::uuid, id, '00000000-0000-0000-0000-00000000b0d1', 'chat' from public.bots where org_id = current_setting('test.org')::uuid;
insert into public.run_tool_attempts (run_id, call_id) select id, 'call-1' from public.runs where org_id = current_setting('test.org')::uuid;
select is((select count(*)::int from public.run_tool_attempts), 1, 'the server sees the row');
select pg_temp.login('00000000-0000-0000-0000-00000000b0d1');
select is((select count(*)::int from public.run_tool_attempts), 0, 'the workspace owner sees nothing');
select throws_ok(
  $$insert into public.run_tool_attempts (run_id, call_id) select id, 'call-2' from public.runs limit 1$$,
  '42501', null, 'people cannot insert');
reset role;
select * from finish();
rollback;
