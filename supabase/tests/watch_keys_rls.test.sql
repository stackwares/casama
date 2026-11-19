-- Watch keys (D-410): the API registers them; a person sees and removes only their own, never a
-- fingerprint; codes and settings are written only by the API; the worker reads push tokens.
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000005a1', 'watch-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000005a2', 'watch-a2@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000005b1', 'Watches', 'watches-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a1', 'owner'),
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a2', 'member');
-- As the API registers them.
insert into public.watch_keys (id, user_id, org_id, platform, key_hash, name, push_token, push_kind, push_sandbox) values
  ('10000000-0000-0000-0000-0000000005c1', '10000000-0000-0000-0000-0000000005a1',
   '10000000-0000-0000-0000-0000000005b1', 'watchos', repeat('a', 64), 'Ana''s Apple Watch', 'apple-watch-token-1', 'apns', false),
  ('10000000-0000-0000-0000-0000000005c2', '10000000-0000-0000-0000-0000000005a2',
   '10000000-0000-0000-0000-0000000005b1', 'wearos', repeat('b', 64), 'Ben''s Pixel Watch', null, null, null);
insert into public.watch_key_requests (code_hash, key_hash, platform, name) values
  (repeat('c', 64), repeat('d', 64), 'wearos', 'A watch');
insert into public.watch_prefs (user_id, allow) values
  ('10000000-0000-0000-0000-0000000005a1', 'low'),
  ('10000000-0000-0000-0000-0000000005a2', 'none');

select throws_ok($$ insert into public.watch_keys (user_id, org_id, platform, key_hash, name, push_token)
  values ('10000000-0000-0000-0000-0000000005a1', '10000000-0000-0000-0000-0000000005b1', 'watchos', repeat('e', 64), 'W', 'apple-watch-token-2') $$,
  '23514', null, 'a push token needs its kind');
select throws_ok($$ insert into public.watch_keys (user_id, org_id, platform, key_hash, name)
  values ('10000000-0000-0000-0000-0000000005a1', '10000000-0000-0000-0000-0000000005b1', 'watchos', 'not-a-fingerprint', 'W') $$,
  '23514', null, 'a fingerprint is 64 hex characters');
select throws_ok($$ insert into public.watch_keys (user_id, org_id, platform, key_hash, name)
  values ('10000000-0000-0000-0000-0000000005a1', '10000000-0000-0000-0000-0000000005b1', 'watchos', repeat('a', 64), 'W') $$,
  '23505', null, 'a fingerprint belongs to one key');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000005a1');
select is((select count(*)::int from public.watch_keys), 1, 'a person sees only their own watches');
select is((select name from public.watch_keys), 'Ana''s Apple Watch', 'and reads what they are');
select throws_ok($$ select key_hash from public.watch_keys $$, '42501', null,
  'but never a fingerprint');
select throws_ok($$ select push_token from public.watch_keys $$, '42501', null,
  'or a push token');
select throws_ok($$ insert into public.watch_keys (user_id, org_id, platform, key_hash, name)
  values ('10000000-0000-0000-0000-0000000005a1', '10000000-0000-0000-0000-0000000005b1', 'watchos', repeat('f', 64), 'W') $$,
  '42501', null, 'watches are registered by the API, not inserted directly');
select throws_ok($$ update public.watch_keys set name = 'Mine now' where id = '10000000-0000-0000-0000-0000000005c1' $$,
  '42501', null, 'nor changed directly');
select throws_ok($$ select count(*) from public.watch_key_requests $$, '42501', null,
  'nobody reads sign-in codes but the API');
select is((select allow from public.watch_prefs), 'low', 'a person reads their own watch settings');
select is((select count(*)::int from public.watch_prefs), 1, 'and nobody else''s');
select throws_ok($$ update public.watch_prefs set allow = 'medium' $$, '42501', null,
  'settings are changed through the API');
delete from public.watch_keys where id = '10000000-0000-0000-0000-0000000005c2';
reset role;

select is((select count(*)::int from public.watch_keys where id = '10000000-0000-0000-0000-0000000005c2'), 1,
  'someone else''s watch is not removed');

select pg_temp.login('10000000-0000-0000-0000-0000000005a1');
delete from public.watch_keys where id = '10000000-0000-0000-0000-0000000005c1';
reset role;
select is((select count(*)::int from public.watch_keys where id = '10000000-0000-0000-0000-0000000005c1'), 0,
  'a person removes their own watch');

select ok(exists (select 1 from pg_policies where tablename = 'watch_keys' and policyname = 'casama_worker_all'),
  'the worker reads every push token');
select ok(exists (select 1 from pg_policies where tablename = 'watch_key_requests' and policyname = 'casama_worker_all'),
  'and sweeps old codes');

select * from finish();
rollback;
