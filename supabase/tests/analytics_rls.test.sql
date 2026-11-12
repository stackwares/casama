-- Analytics tables and functions (D-208): milestones are first-party activation data nobody reads
-- from the app; the worker's sign-up functions are callable by the worker only.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000c1', 'ana@example.com', 'authenticated', 'authenticated');
insert into public.analytics_milestones (user_id, milestone) values
  ('00000000-0000-0000-0000-0000000000c1', 'first_value');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select is((select count(*)::int from public.analytics_milestones), 0, 'a person cannot read milestones, even their own');
select throws_ok($$
  insert into public.analytics_milestones (user_id, milestone) values ('00000000-0000-0000-0000-0000000000c1', 'first_bot_created')
$$, '42501', null, 'a person cannot write milestones');
select throws_ok($$ select * from public.worker_new_signups(10) $$, '42501', null, 'a person cannot list new sign-ups');
select throws_ok($$ select public.worker_mark_signups_sent(array['00000000-0000-0000-0000-0000000000c1']::uuid[]) $$,
  '42501', null, 'a person cannot mark sign-ups as reported');
reset role;
select ok((select not analytics_opt_out from public.profiles where user_id = '00000000-0000-0000-0000-0000000000c1'),
  'analytics is on until a person turns it off');
select col_default_is('public', 'organizations', 'analytics_opt_out', 'false', 'workspaces default to analytics on');
select * from finish();
rollback;
