-- D-295: a project that grew out of someone's own chat follows that chat; what is made in a
-- project's chat, or by a run that works on it, is filed under it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000e0e1', 'own-proj@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000e0e2', 'mem-proj@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000e0e3', 'out-proj@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000e0e1');
select public.create_organization('Proj Org', 'proj-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'proj-org'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000e0e2', 'member');
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'Maker', '00000000-0000-0000-0000-00000000e0e1');
select set_config('test.bot', (select id::text from public.bots where org_id = current_setting('test.org')::uuid), true);

-- The owner's General, then a topic, both their own chats.
insert into public.conversations (org_id, bot_id, created_by, personal, title)
values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000e0e1', true, 'General');
insert into public.conversations (org_id, bot_id, created_by, personal, title)
values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000e0e1', true, 'Game');
select set_config('test.topic', (select id::text from public.conversations where title = 'Game' and org_id = current_setting('test.org')::uuid), true);

-- A workspace project, and a personal one whose chat is the topic.
insert into public.projects (org_id, slug, title, lead_bot_id, owner_user_id, status)
values (current_setting('test.org')::uuid, 'team', 'Team', current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000e0e1', 'active');
insert into public.projects (org_id, slug, title, lead_bot_id, owner_user_id, status, personal, conversation_id)
values (current_setting('test.org')::uuid, 'game', 'Game', current_setting('test.bot')::uuid, '00000000-0000-0000-0000-00000000e0e1', 'active', true, current_setting('test.topic')::uuid);
select set_config('test.game', (select id::text from public.projects where slug = 'game' and org_id = current_setting('test.org')::uuid), true);
update public.conversations set project_id = current_setting('test.game')::uuid where id = current_setting('test.topic')::uuid;

select is((select autonomous from public.projects where id = current_setting('test.game')::uuid), false, 'a new project does not work by itself');
select throws_ok(
  $$ update public.projects set autonomous = true where slug = 'game' $$,
  '23514', null, 'a project that works by itself needs a goal');
select is((select parent_conversation_id is not null and not is_main from public.conversations where id = current_setting('test.topic')::uuid), true,
  'a project''s chat stays a topic under General');

-- Filed by itself: from the chat, and from a run that works on the project.
insert into public.chat_media (org_id, bot_id, conversation_id, name, content_type, bytes, size)
values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, current_setting('test.topic')::uuid, 'ship.png', 'image/png', '\x89504e47'::bytea, 4);
select is((select project_id from public.creations where title = 'ship'), current_setting('test.game')::uuid, 'what is made in a project''s chat is filed under it');
insert into public.runs (org_id, bot_id, conversation_id, trigger) values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, current_setting('test.topic')::uuid, 'chat');
select is((select project_id from public.runs where conversation_id = current_setting('test.topic')::uuid), current_setting('test.game')::uuid, 'a run in a project''s chat is the project''s');
insert into public.runs (org_id, bot_id, trigger, project_id) values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'chat', current_setting('test.game')::uuid);
insert into public.chat_media (org_id, bot_id, run_id, name, content_type, bytes, size)
select current_setting('test.org')::uuid, current_setting('test.bot')::uuid, id, 'logo.png', 'image/png', '\x89504e47'::bytea, 4
from public.runs where conversation_id is null and org_id = current_setting('test.org')::uuid;
select is((select project_id from public.creations where title = 'logo'), current_setting('test.game')::uuid, 'what a run working on a project makes is filed under it');
-- Taken out by hand, it stays out when the same run touches it again.
update public.creations set project_id = null where title = 'logo';
update public.creations set run_id = run_id where title = 'logo';
select is((select project_id from public.creations where title = 'logo'), null, 'something taken out of a project stays out');

select pg_temp.login('00000000-0000-0000-0000-00000000e0e2');
select is((select count(*)::int from public.projects where slug = 'team'), 1, 'a member sees a workspace project');
select is((select count(*)::int from public.projects where slug = 'game'), 1, 'and a personal one whose chat they can open');
reset role;
update public.conversations set private = true where id = current_setting('test.topic')::uuid;
select pg_temp.login('00000000-0000-0000-0000-00000000e0e2');
select is((select count(*)::int from public.projects where slug = 'game'), 0, 'but not once that chat is private');
select is(public.can_view_project(current_setting('test.game')::uuid), false, 'can_view_project agrees');
select pg_temp.login('00000000-0000-0000-0000-00000000e0e1');
select is((select count(*)::int from public.projects where slug = 'game'), 1, 'its owner still sees it');
select pg_temp.login('00000000-0000-0000-0000-00000000e0e3');
select is((select count(*)::int from public.projects), 0, 'outsiders see no projects');
reset role;
select * from finish();
rollback;
