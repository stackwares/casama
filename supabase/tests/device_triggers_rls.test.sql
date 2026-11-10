begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000f1', 'fay-own@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000f2', 'fay-out@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
insert into public.device_places (user_id, name, latitude, longitude) values ('00000000-0000-0000-0000-0000000000f1', 'Home', 40.7, -74);
insert into public.device_event_log (user_id, event_id, type) values ('00000000-0000-0000-0000-0000000000f1', 'e1', 'arrive');
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select is((select count(*)::int from public.device_places), 1, 'people see their own places');
select throws_ok($$ insert into public.device_places (user_id, name, latitude, longitude) values ('00000000-0000-0000-0000-0000000000f1', 'Work', 1, 1) $$, '42501', null, 'places are saved through the API (which caps them at 20)');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000f2');
select is((select count(*)::int from public.device_places), 0, 'nobody else sees them');
select is((select count(*)::int from public.device_event_log), 0, 'or the event log');
reset role;
select * from finish();
rollback;
