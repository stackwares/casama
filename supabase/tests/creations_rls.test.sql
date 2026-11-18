-- D-274: the Library follows the visibility of where each thing was made.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000d0d1', 'own-lib@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000d0d2', 'mem-lib@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000d0d3', 'out-lib@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000d0d1');
select public.create_organization('Lib Org', 'lib-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'lib-org'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000d0d2', 'member');
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'Maker', '00000000-0000-0000-0000-00000000d0d1');
select set_config('test.bot', (select id::text from public.bots where org_id = current_setting('test.org')::uuid), true);
-- A private page for the owner, a workspace page, and a picture in a chat.
insert into public.pages (org_id, bot_id, created_by, title, html, visibility)
values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000d0d1', 'Private plan', '<p>x</p>', 'private'),
       (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000d0d1', 'Team board', '<p>y</p>', 'workspace');
insert into public.conversations (org_id, bot_id, created_by) values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000d0d1');
insert into public.chat_media (org_id, bot_id, conversation_id, name, content_type, bytes, size)
select current_setting('test.org')::uuid, current_setting('test.bot')::uuid, id, 'sunset.png', 'image/png', '\x89504e47'::bytea, 4
from public.conversations where org_id = current_setting('test.org')::uuid;

select is((select count(*)::int from public.creations where org_id = current_setting('test.org')::uuid), 3, 'pages and media appear in the Library');
select is((select title from public.creations where kind = 'image' and org_id = current_setting('test.org')::uuid), 'sunset', 'a picture is titled from its file name');
select is((select storage_bytes from public.organizations where id = current_setting('test.org')::uuid) > 0, true, 'storage is counted');

select pg_temp.login('00000000-0000-0000-0000-00000000d0d1');
select is((select count(*)::int from public.creations), 3, 'the owner sees all three');
select pg_temp.login('00000000-0000-0000-0000-00000000d0d2');
select is((select count(*)::int from public.creations where title = 'Team board'), 1, 'a member sees the workspace page');
select is((select count(*)::int from public.creations where title = 'Private plan'), 0, 'a member does not see the owner''s private page');
select is((select count(*)::int from public.creations where title = 'sunset'), 1, 'a member sees media from a shared chat');
update public.creations set title = 'Renamed' where title = 'Team board';
select is((select count(*)::int from public.creations where title = 'Renamed'), 0, 'a plain member cannot rename someone else''s creation');
select pg_temp.login('00000000-0000-0000-0000-00000000d0d3');
select is((select count(*)::int from public.creations), 0, 'outsiders see nothing');
reset role;
select * from finish();
rollback;
