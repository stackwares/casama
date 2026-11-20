-- Bot widgets (docs/BOT-WIDGET-PLAN.md §7): bots write canvases through the worker; a person
-- reads and clears their own, changes only pause and Hide on a locked phone, and inserts nothing.
-- Pictures are the server's alone. Leaving a workspace takes the person's canvases there.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000005a1', 'canvas-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000005a2', 'canvas-a2@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000005b1', 'Canvases', 'canvases-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a1', 'owner'),
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a2', 'member');
insert into public.bots (id, org_id, created_by, name) values
  ('10000000-0000-0000-0000-0000000005d1', '10000000-0000-0000-0000-0000000005b1',
   '10000000-0000-0000-0000-0000000005a1', 'Verse');
-- As the worker writes them.
insert into public.widget_canvases (id, org_id, user_id, bot_id, name, content, status) values
  ('10000000-0000-0000-0000-0000000005c1', '10000000-0000-0000-0000-0000000005b1',
   '10000000-0000-0000-0000-0000000005a1', '10000000-0000-0000-0000-0000000005d1', 'Daily verse',
   '{"look":{}}', 'shown'),
  ('10000000-0000-0000-0000-0000000005c2', '10000000-0000-0000-0000-0000000005b1',
   '10000000-0000-0000-0000-0000000005a2', '10000000-0000-0000-0000-0000000005d1', 'Main',
   '{"look":{}}', 'shown');
insert into public.widget_canvas_pictures (canvas_id, hash, tone, size, bytes) values
  ('10000000-0000-0000-0000-0000000005c1', '0123456789abcdef', 'dark', 3, '\x010203');

select throws_ok($$ insert into public.widget_canvases (org_id, user_id, bot_id, name, content, status)
  values ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a1',
          '10000000-0000-0000-0000-0000000005d1', 'Bad', '{}', 'shown-ish') $$,
  '23514', null, 'status is one of waiting, shown, paused');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000005a1');
select is((select count(*)::int from public.widget_canvases), 1, 'a person sees only their own canvases');
select throws_ok($$ insert into public.widget_canvases (org_id, user_id, bot_id, name, content)
  values ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a1',
          '10000000-0000-0000-0000-0000000005d1', 'Mine', '{}') $$,
  '42501', null, 'bots write canvases, people don''t insert them');
select lives_ok($$ update public.widget_canvases set status = 'paused', hide_when_locked = true
  where id = '10000000-0000-0000-0000-0000000005c1' $$, 'a person pauses and hides their canvas');
select throws_ok($$ update public.widget_canvases set content = '{"x":1}'
  where id = '10000000-0000-0000-0000-0000000005c1' $$, '42501', null, 'but can''t change what it shows');
select throws_ok($$ select count(*) from public.widget_canvas_pictures $$, '42501', null,
  'pictures are the server''s');
update public.widget_canvases set status = 'paused' where id = '10000000-0000-0000-0000-0000000005c2';
delete from public.widget_canvases where id = '10000000-0000-0000-0000-0000000005c2';
reset role;

select is((select status from public.widget_canvases where id = '10000000-0000-0000-0000-0000000005c1'), 'paused',
  'their own canvas changed');
select is((select status from public.widget_canvases where id = '10000000-0000-0000-0000-0000000005c2'), 'shown',
  'someone else''s is untouched');

select pg_temp.login('10000000-0000-0000-0000-0000000005a1');
delete from public.widget_canvases where id = '10000000-0000-0000-0000-0000000005c1';
reset role;
select is((select count(*)::int from public.widget_canvases where id = '10000000-0000-0000-0000-0000000005c1'), 0,
  'a person clears their own canvas');
select is((select count(*)::int from public.widget_canvas_pictures), 0, 'its pictures go with it');

select lives_ok($$ insert into public.device_grants (user_id, bot_id, kind) values
  ('10000000-0000-0000-0000-0000000005a2', '10000000-0000-0000-0000-0000000005d1', 'widgets') $$,
  'widgets is a grant kind');

delete from public.memberships where org_id = '10000000-0000-0000-0000-0000000005b1'
  and user_id = '10000000-0000-0000-0000-0000000005a2';
select is((select count(*)::int from public.widget_canvases where user_id = '10000000-0000-0000-0000-0000000005a2'), 0,
  'leaving the workspace takes the person''s canvases');

select ok(exists (select 1 from pg_policies where tablename = 'widget_canvases' and policyname = 'casama_worker_all'),
  'the worker writes canvases');

select * from finish();
rollback;
