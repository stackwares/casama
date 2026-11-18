-- D-323 (Casama for Chrome, Phase 4): the browser as a device. Bots can be allowed the browser
-- kinds like phone data, grants stay the person's own, and routines remember who last changed them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c4e1', 'chrome4-a@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000c4e2', 'chrome4-b@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000c4e1');
select public.create_organization('Chrome Four', 'chrome-four');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'chrome-four'), true);
insert into public.bots (id, org_id, name, created_by) values
  ('00000000-0000-0000-0000-00000000c4b0', current_setting('test.org')::uuid, 'Tab bot', '00000000-0000-0000-0000-00000000c4e1');
insert into public.device_sources (id, user_id, device_key, name, platform, kinds) values
  ('00000000-0000-0000-0000-00000000c4d1', '00000000-0000-0000-0000-00000000c4e1', 'chrome-four-key', 'Chrome', 'web', '{"browser_tab": {"retention_days": 0}}');

select lives_ok($$ insert into public.device_grants (user_id, bot_id, kind) values
  ('00000000-0000-0000-0000-00000000c4e1', '00000000-0000-0000-0000-00000000c4b0', 'browser_tab'),
  ('00000000-0000-0000-0000-00000000c4e1', '00000000-0000-0000-0000-00000000c4b0', 'browser_history') $$,
  'a bot can be allowed the current tab and history search');
select throws_ok($$ insert into public.device_grants (user_id, bot_id, kind) values
  ('00000000-0000-0000-0000-00000000c4e1', '00000000-0000-0000-0000-00000000c4b0', 'browser_cookies') $$,
  '23514', null, 'only known kinds');
select lives_ok($$ insert into public.device_requests (user_id, source_id, kind, action) values
  ('00000000-0000-0000-0000-00000000c4e1', '00000000-0000-0000-0000-00000000c4d1', 'browser_tab', 'read') $$,
  'one of the person''s own devices can ask the browser without a run');

select pg_temp.login('00000000-0000-0000-0000-00000000c4e2');
select is((select count(*)::int from public.device_grants where user_id = '00000000-0000-0000-0000-00000000c4e1'), 0,
  'nobody else sees which bots may read the browser');
select is((select count(*)::int from public.device_requests where source_id = '00000000-0000-0000-0000-00000000c4d1'), 0,
  'nor its requests');
reset role;
select col_default_is('public', 'routines', 'edited_by_other', 'false', 'a new routine can use its creator''s browser');
select * from finish();
rollback;
