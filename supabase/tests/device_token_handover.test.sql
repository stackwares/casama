begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000e1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000e2', 'bo@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

-- Ana's phone registers.
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
insert into public.devices (user_id, platform, fcm_token) values ('00000000-0000-0000-0000-0000000000e1', 'ios', 'fcm-shared-phone');
insert into public.voip_tokens (user_id, token) values ('00000000-0000-0000-0000-0000000000e1', 'voip-shared-phone');
reset role;

-- Bo signs in on the same phone and registers the same tokens, the way the app does (upsert).
select pg_temp.login('00000000-0000-0000-0000-0000000000e2');
select lives_ok($$ insert into public.devices (user_id, platform, fcm_token, last_seen_at)
  values ('00000000-0000-0000-0000-0000000000e2', 'ios', 'fcm-shared-phone', now())
  on conflict (fcm_token) do update set user_id = excluded.user_id, last_seen_at = excluded.last_seen_at $$,
  'the next account on a phone takes its push token');
select lives_ok($$ insert into public.voip_tokens (user_id, token, last_seen_at)
  values ('00000000-0000-0000-0000-0000000000e2', 'voip-shared-phone', now())
  on conflict (token) do update set user_id = excluded.user_id, last_seen_at = excluded.last_seen_at $$,
  'and its VoIP token');
-- Registering again (every launch) still works.
select lives_ok($$ insert into public.voip_tokens (user_id, token, last_seen_at)
  values ('00000000-0000-0000-0000-0000000000e2', 'voip-shared-phone', now())
  on conflict (token) do update set user_id = excluded.user_id, last_seen_at = excluded.last_seen_at $$,
  'registering the same token again updates it');
-- Nobody plants a token on someone else, and a failed try removes nothing.
select throws_ok($$ insert into public.voip_tokens (user_id, token) values ('00000000-0000-0000-0000-0000000000e1', 'voip-shared-phone') $$,
  null, null, 'nobody registers a token for someone else');
reset role;

select is((select user_id from public.devices where fcm_token = 'fcm-shared-phone'),
  '00000000-0000-0000-0000-0000000000e2'::uuid, 'the push token is Bo''s now');
select is((select user_id from public.voip_tokens where token = 'voip-shared-phone'),
  '00000000-0000-0000-0000-0000000000e2'::uuid, 'and the VoIP token');
select is((select count(*) from public.devices where user_id = '00000000-0000-0000-0000-0000000000e1')::int, 0,
  'Ana no longer gets pushes on Bo''s phone');
select is((select count(*) from public.voip_tokens where user_id = '00000000-0000-0000-0000-0000000000e1')::int, 0,
  'or call rings');

-- D-474: a token registered with an install id moves only to the same install.
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
insert into public.devices (user_id, platform, fcm_token, install_id)
  values ('00000000-0000-0000-0000-0000000000e1', 'android', 'fcm-ana-own', 'install-ana-0001');
insert into public.voip_tokens (user_id, token, install_id)
  values ('00000000-0000-0000-0000-0000000000e1', 'voip-ana-own', 'install-ana-0001');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000e2');
select throws_ok($$ insert into public.devices (user_id, platform, fcm_token)
  values ('00000000-0000-0000-0000-0000000000e2', 'android', 'fcm-ana-own')
  on conflict (fcm_token) do update set user_id = excluded.user_id $$,
  null, null, 'someone who only knows a token can''t take it');
select throws_ok($$ insert into public.voip_tokens (user_id, token, install_id)
  values ('00000000-0000-0000-0000-0000000000e2', 'voip-ana-own', 'install-bo-00001')
  on conflict (token) do update set user_id = excluded.user_id $$,
  null, null, 'nor from another install');
select lives_ok($$ insert into public.devices (user_id, platform, fcm_token, install_id)
  values ('00000000-0000-0000-0000-0000000000e2', 'android', 'fcm-ana-own', 'install-ana-0001')
  on conflict (fcm_token) do update set user_id = excluded.user_id $$,
  'the same install signing in as someone else takes it');
reset role;
select is((select user_id from public.devices where fcm_token = 'fcm-ana-own'),
  '00000000-0000-0000-0000-0000000000e2'::uuid, 'the push token moved with the install');
select is((select user_id from public.voip_tokens where token = 'voip-ana-own'),
  '00000000-0000-0000-0000-0000000000e1'::uuid, 'the VoIP token stayed with its owner');

select * from finish();
rollback;
