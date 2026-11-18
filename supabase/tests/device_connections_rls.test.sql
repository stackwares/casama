begin;
create extension if not exists pgtap with schema extensions;
select plan(7);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000e1', 'eve-own@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000e2', 'eve-out@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
select public.create_organization('Eve Org', 'eve-org');
select lives_ok($$ insert into public.device_sources (user_id, device_key, platform, kinds) values ('00000000-0000-0000-0000-0000000000e1', 'eve-phone-01', 'ios', '{"calendar":{}}') $$, 'people register their own devices');
select throws_ok($$ insert into public.device_sources (user_id, device_key, platform) values ('00000000-0000-0000-0000-0000000000e2', 'not-mine-01', 'ios') $$, '42501', null, 'not for someone else');
select throws_ok($$ insert into public.device_grants (user_id, bot_id, kind) select '00000000-0000-0000-0000-0000000000e1', gen_random_uuid(), 'calendar' $$, '42501', null, 'grants go through the API (which checks bot access)');
reset role;
insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
  select user_id, id, 'calendar', now(), now(), 'd1', '{"events":[]}' from public.device_sources where device_key = 'eve-phone-01';
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
select is((select count(*)::int from public.device_readings), 1, 'owners see their readings');
select throws_ok($$ insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
  select user_id, id, 'calendar', now(), now(), 'd2', '{}' from public.device_sources $$, '42501', null, 'readings are uploaded through the API');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000e2');
select is((select count(*)::int from public.device_readings), 0, 'nobody else sees them, not even workspace admins');
select is((select count(*)::int from public.device_sources), 0, 'or the devices');
reset role;
select * from finish();
rollback;
