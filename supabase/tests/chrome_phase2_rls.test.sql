-- D-323 (Casama for Chrome, Phase 2): page commands and highlights are private to the person;
-- highlights stay inside workspaces they belong to.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c5e1', 'chrome2-a@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000c5e2', 'chrome2-b@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000c5e1');
select public.create_organization('Chrome Two', 'chrome-two');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'chrome-two'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c5e2', 'member');

select pg_temp.login('00000000-0000-0000-0000-00000000c5e1');
select lives_ok($$ insert into public.page_commands (name, prompt) values ('Team summary', 'Summarize this for my team') $$,
  'a person saves a page command');
select is((select user_id from public.page_commands where name = 'Team summary'),
  '00000000-0000-0000-0000-00000000c5e1'::uuid, 'it is theirs');
select throws_ok($$ insert into public.page_commands (user_id, name, prompt) values ('00000000-0000-0000-0000-00000000c5e2', 'x', 'y') $$,
  '42501', null, 'but not for someone else');
select lives_ok(format($$ insert into public.highlights (org_id, url, url_key, text) values (%L, 'https://news.example/a#p2', 'https://news.example/a', 'eleven dry weeks') $$, current_setting('test.org')),
  'a member highlights text in their workspace');

select pg_temp.login('00000000-0000-0000-0000-00000000c5e2');
select is((select count(*)::int from public.page_commands), 0, 'another person sees no page commands');
select is((select count(*)::int from public.highlights), 0, 'nor highlights, even in the same workspace');
update public.highlights set note = 'changed';
reset role;
select is((select note from public.highlights where text = 'eleven dry weeks'), '', 'and cannot change them');
insert into auth.users (id, email, aud, role) values ('00000000-0000-0000-0000-00000000c5e3', 'chrome2-c@example.com', 'authenticated', 'authenticated');
select pg_temp.login('00000000-0000-0000-0000-00000000c5e3');
select throws_ok(format($$ insert into public.highlights (org_id, url, url_key, text) values (%L, 'https://x.example', 'https://x.example', 't') $$, current_setting('test.org')),
  '42501', null, 'someone outside the workspace cannot add highlights to it');
reset role;
-- Watchers made by pointing at a page: the person who made one can stop it, on a bot they use
-- but don't manage; not someone else's.
insert into public.bots (id, org_id, name, created_by) values
  ('00000000-0000-0000-0000-00000000c5b0', current_setting('test.org')::uuid, 'Shared', '00000000-0000-0000-0000-00000000c5e1');
insert into public.watchers (id, org_id, bot_id, created_by, name, kind, target) values
  ('00000000-0000-0000-0000-00000000c5f1', current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c5b0', '00000000-0000-0000-0000-00000000c5e2', 'Kettle price', 'page_change', '{"url":"https://shop.example/kettle","anchor":"Price","chars":40,"browser":false}'),
  ('00000000-0000-0000-0000-00000000c5f2', current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c5b0', '00000000-0000-0000-0000-00000000c5e1', 'Owner watch', 'page_change', '{"url":"https://shop.example/x"}');
select pg_temp.login('00000000-0000-0000-0000-00000000c5e2');
update public.watchers set status = 'paused' where id = '00000000-0000-0000-0000-00000000c5f1';
delete from public.watchers where id = '00000000-0000-0000-0000-00000000c5f2';
reset role;
select is((select status from public.watchers where id = '00000000-0000-0000-0000-00000000c5f1'), 'paused',
  'a member pauses a watcher they made');
select is((select count(*)::int from public.watchers where id = '00000000-0000-0000-0000-00000000c5f2'), 1,
  'but cannot stop one someone else made');
select pg_temp.login('00000000-0000-0000-0000-00000000c5e2');
delete from public.watchers where id = '00000000-0000-0000-0000-00000000c5f1';
reset role;
select is((select count(*)::int from public.watchers where id = '00000000-0000-0000-0000-00000000c5f1'), 0,
  'and deletes their own');

select ok((select count(*) from pg_policies where tablename in ('page_commands', 'highlights') and policyname like '%worker%') >= 2,
  'the worker can reach both tables');
select * from finish();
rollback;
