-- Push-to-start tokens (D-324, Phase 6): a person registers and sees only their own.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000002a1', 'start-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000002a2', 'start-a2@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000002a1');
select lives_ok($$ insert into public.live_start_tokens (user_id, platform, token, fcm_token)
  values ('10000000-0000-0000-0000-0000000002a1', 'ios', 'start-token-0001', 'fcm-token-0001') $$,
  'a person registers a start token for themselves');
select throws_ok($$ insert into public.live_start_tokens (user_id, platform, token)
  values ('10000000-0000-0000-0000-0000000002a2', 'android', 'start-token-0002') $$,
  '42501', null, 'but not for someone else');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000002a2');
select is((select count(*)::int from public.live_start_tokens), 0, 'nobody else sees it');
select lives_ok($$ insert into public.live_start_tokens (user_id, platform, token)
  values ('10000000-0000-0000-0000-0000000002a2', 'android', 'start-token-0001') $$,
  'the same token can belong to another account (a shared phone)');
reset role;

select is((select count(*)::int from public.live_start_tokens), 2, 'the worker sees every token');
select is((select bool_and(enabled) from public.live_start_tokens), true, 'a token is on until the phone turns it off');

select * from finish();
rollback;
