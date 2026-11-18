-- Widget keys (D-405): the API makes them; a person sees, changes and deletes only their own, never
-- a key's hash; the worker reads every push token.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000004a1', 'widget-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000004a2', 'widget-a2@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000004b1', 'Widgets', 'widgets-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000004b1', '10000000-0000-0000-0000-0000000004a1', 'owner'),
  ('10000000-0000-0000-0000-0000000004b1', '10000000-0000-0000-0000-0000000004a2', 'member');
-- As the API makes them.
insert into public.widget_keys (id, user_id, org_id, platform, key_hash, push_token, push_kind, push_sandbox) values
  ('10000000-0000-0000-0000-0000000004c1', '10000000-0000-0000-0000-0000000004a1',
   '10000000-0000-0000-0000-0000000004b1', 'ios', repeat('a', 64), 'apple-widget-token-1', 'apns_widgets', false),
  ('10000000-0000-0000-0000-0000000004c2', '10000000-0000-0000-0000-0000000004a2',
   '10000000-0000-0000-0000-0000000004b1', 'android', repeat('b', 64), null, null, null);

select throws_ok($$ insert into public.widget_keys (user_id, org_id, platform, key_hash, push_token)
  values ('10000000-0000-0000-0000-0000000004a1', '10000000-0000-0000-0000-0000000004b1', 'ios', repeat('c', 64), 'apple-widget-token-2') $$,
  '23514', null, 'a push token needs its kind');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000004a1');
select is((select count(*)::int from public.widget_keys), 1, 'a person sees only their own keys');
select is((select platform from public.widget_keys), 'ios', 'and reads what they are');
select throws_ok($$ select key_hash from public.widget_keys $$, '42501', null,
  'but never a key''s hash');
select throws_ok($$ insert into public.widget_keys (user_id, org_id, platform, key_hash)
  values ('10000000-0000-0000-0000-0000000004a1', '10000000-0000-0000-0000-0000000004b1', 'ios', repeat('d', 64)) $$,
  '42501', null, 'keys are made by the API, not inserted directly');
select lives_ok($$ update public.widget_keys set private = true where id = '10000000-0000-0000-0000-0000000004c1' $$,
  'a person turns their key private');
select throws_ok($$ update public.widget_keys set push_token = 'x-token-123' where id = '10000000-0000-0000-0000-0000000004c1' $$,
  '42501', null, 'push tokens go through the API');
update public.widget_keys set private = true where id = '10000000-0000-0000-0000-0000000004c2';
delete from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c2';
reset role;

select is((select private from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c1'), true,
  'their own key changed');
select is((select private from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c2'), false,
  'someone else''s key is untouched');
select is((select count(*)::int from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c2'), 1,
  'and not deleted');

select pg_temp.login('10000000-0000-0000-0000-0000000004a1');
delete from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c1';
reset role;
select is((select count(*)::int from public.widget_keys where id = '10000000-0000-0000-0000-0000000004c1'), 0,
  'a person deletes their own key (sign-out)');

select ok(exists (select 1 from pg_policies where tablename = 'widget_keys' and policyname = 'casama_worker_all'),
  'the worker reads every push token');

select * from finish();
rollback;
