begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000b1', 'tia@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000b2', 'out@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000b1');
select public.create_organization('Board Org', 'board-org');
insert into public.tasks (org_id, title, created_by_user_id)
  select id, 'Ship it', '00000000-0000-0000-0000-0000000000b1' from public.organizations where slug = 'board-org';
select lives_ok($$
  insert into public.task_comments (org_id, task_id, author_type, author_user_id, body_md)
  select t.org_id, t.id, 'user', '00000000-0000-0000-0000-0000000000b1', 'On it' from public.tasks t where t.title = 'Ship it'
$$, 'a member comments as themselves');
select throws_ok($$
  insert into public.task_comments (org_id, task_id, author_type, body_md)
  select t.org_id, t.id, 'bot', 'pretending' from public.tasks t where t.title = 'Ship it'
$$, '42501', null, 'members cannot write bot comments');
reset role;
select set_config('test.task', (select id::text from public.tasks where title = 'Ship it'), true);
select set_config('test.org', (select org_id::text from public.tasks where title = 'Ship it'), true);
select pg_temp.login('00000000-0000-0000-0000-0000000000b2');
select is((select count(*)::int from public.task_comments), 0, 'outsiders see no comments');
select throws_ok($$
  insert into public.task_comments (org_id, task_id, author_type, author_user_id, body_md)
  values (current_setting('test.org')::uuid, current_setting('test.task')::uuid, 'user', '00000000-0000-0000-0000-0000000000b2', 'x')
$$, '42501', null, 'outsiders cannot comment on another workspace''s ticket');
reset role;
select * from finish();
rollback;
