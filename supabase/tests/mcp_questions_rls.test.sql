begin;
create extension if not exists pgtap with schema extensions;
select plan(5);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000f1', 'asks@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000f2', 'asks-outsider@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select public.create_organization('Asks Org', 'asks-org');
insert into public.bots (org_id, name, created_by, visibility)
  select id, 'Asker', '00000000-0000-0000-0000-0000000000f1', 'team' from public.organizations where slug = 'asks-org';
reset role;
insert into public.runs (org_id, bot_id, trigger, created_by)
  select org_id, id, 'chat', '00000000-0000-0000-0000-0000000000f1' from public.bots where name = 'Asker';
insert into public.mcp_questions (org_id, bot_id, run_id, connection, message, answer)
  select r.org_id, r.bot_id, r.id, 'T3 Code', 'Which project?', '{"project": "secret"}'::jsonb from public.runs r
  join public.bots b on b.id = r.bot_id where b.name = 'Asker';
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select is((select count(id)::int from public.mcp_questions), 1, 'members see their bot''s questions');
select throws_ok($$ select answer from public.mcp_questions $$, '42501', null, 'but not the answers');
select throws_ok($$ update public.mcp_questions set status = 'accepted' $$, '42501', null, 'and answer only through the API');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000f2');
select is((select count(id)::int from public.mcp_questions), 0, 'outsiders see none');
reset role;
select throws_ok($$ insert into public.mcp_questions (org_id, bot_id, run_id, connection, message, status)
  select org_id, bot_id, run_id, 'x', 'y', 'maybe' from public.mcp_questions limit 1 $$, '23514', null, 'statuses are checked');
select * from finish();
rollback;
