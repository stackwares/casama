begin;
create extension if not exists pgtap with schema extensions;
select plan(3);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000f1', 'find@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000f2', 'find-outsider@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select public.create_organization('Find Org', 'find-org');
insert into public.bots (org_id, name, created_by, visibility)
  select id, 'Finder', '00000000-0000-0000-0000-0000000000f1', 'team' from public.organizations where slug = 'find-org';
reset role;
insert into public.conversations (org_id, bot_id, title, created_by)
  select org_id, id, 'Budget review', '00000000-0000-0000-0000-0000000000f1' from public.bots where name = 'Finder';
insert into public.messages (org_id, conversation_id, role, content)
  select org_id, id, 'user', '[{"type":"text","text":"the zeppelin budget is final"}]'::jsonb from public.conversations where title = 'Budget review';
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select is((select count(*)::int from public.search_workspace((select id from public.organizations where slug = 'find-org'), 'zeppelin') where kind = 'message'), 1, 'members find their messages');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000f2');
select is((select count(*)::int from public.search_workspace((select org_id from public.bots where name = 'Finder'), 'zeppelin')), 0, 'outsiders find nothing');
reset role;
select is(public.message_plain_text('[{"type":"tool_call","name":"x"},{"type":"text","text":"hi"}]'::jsonb), 'hi', 'only text parts are indexed');
select * from finish();
rollback;
