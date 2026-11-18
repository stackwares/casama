-- D-323 (Casama for Chrome, Phase 3): a browser-only device has no computer; browser recordings
-- belong to a device and stay private to the person who made them; workspace switches default on.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c3e1', 'chrome3-a@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000c3e2', 'chrome3-b@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000c3e1');
select public.create_organization('Chrome Three', 'chrome-three');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'chrome-three'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c3e2', 'member');
insert into public.bots (id, org_id, name, created_by) values
  ('00000000-0000-0000-0000-00000000c3b0', current_setting('test.org')::uuid, 'Browser bot', '00000000-0000-0000-0000-00000000c3e1');

select lives_ok(format($$ insert into public.local_devices (id, org_id, user_id, name, platform, token_hash, capabilities)
  values ('00000000-0000-0000-0000-00000000c3d1', %L, '00000000-0000-0000-0000-00000000c3e1', 'Chrome on Mac', 'chrome', 'h-chrome3', '{"browser": true}') $$, current_setting('test.org')),
  'a browser-only device needs no computer');
select throws_ok(format($$ insert into public.local_devices (org_id, user_id, name, platform, token_hash, allowed_kinds)
  values (%L, '00000000-0000-0000-0000-00000000c3e1', 'x', 'chrome', 'h-chrome3b', '{shopping}') $$, current_setting('test.org')),
  '23514', null, 'only the off-by-default kinds can be switched back on');
select throws_ok(format($$ insert into public.teach_sessions (org_id, bot_id, user_id) values (%L, '00000000-0000-0000-0000-00000000c3b0', '00000000-0000-0000-0000-00000000c3e1') $$, current_setting('test.org')),
  '23514', null, 'a recording belongs to a computer or a browser');
insert into public.teach_sessions (id, org_id, bot_id, device_id, user_id) values
  ('00000000-0000-0000-0000-00000000c3a1', current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c3b0', '00000000-0000-0000-0000-00000000c3d1', '00000000-0000-0000-0000-00000000c3e1');
select lives_ok($$ insert into public.teach_steps (session_id, seq, org_id, kind, url, target)
  select '00000000-0000-0000-0000-00000000c3a1', 1, org_id, 'open', 'https://wiki.example/new', null from public.teach_sessions where id = '00000000-0000-0000-0000-00000000c3a1' $$,
  'a browser recording opens pages by address');
insert into public.teach_steps (session_id, seq, org_id, kind, target)
  select '00000000-0000-0000-0000-00000000c3a1', 2, org_id, 'click', '{"role":"button","name":"New page"}' from public.teach_sessions where id = '00000000-0000-0000-0000-00000000c3a1';

select pg_temp.login('00000000-0000-0000-0000-00000000c3e2');
select is((select count(*)::int from public.teach_steps where session_id = '00000000-0000-0000-0000-00000000c3a1'), 0,
  'someone else in the workspace sees none of the recording');
select is((select count(*)::int from public.local_devices where id = '00000000-0000-0000-0000-00000000c3d1'), 0,
  'nor the browser');
select pg_temp.login('00000000-0000-0000-0000-00000000c3e1');
select is((select target->>'name' from public.teach_steps where session_id = '00000000-0000-0000-0000-00000000c3a1' and seq = 2), 'New page',
  'the recorder reads their steps by label');
reset role;
select ok((select chrome_extension and chrome_act from public.organizations where id = current_setting('test.org')::uuid),
  'the extension and Act are on for a new workspace');
select * from finish();
rollback;
