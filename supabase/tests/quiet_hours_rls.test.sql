begin;
create extension if not exists pgtap with schema extensions;
select plan(3);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'q1@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000a2', 'q2@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000a1');
select public.create_organization('Quiet Org', 'quiet-org');
insert into public.bots (org_id, name, created_by, visibility)
  select id, 'Owl', '00000000-0000-0000-0000-0000000000a1', 'team' from public.organizations where slug = 'quiet-org';
select lives_ok($$ insert into public.user_bot_settings (user_id, bot_id, quiet)
  select '00000000-0000-0000-0000-0000000000a1', id, 'always' from public.bots where name = 'Owl' $$, 'people set their own per-bot quiet hours');
select throws_ok($$ insert into public.user_bot_settings (user_id, bot_id, quiet)
  select '00000000-0000-0000-0000-0000000000a2', id, 'always' from public.bots where name = 'Owl' $$, '42501', null, 'but not for someone else');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000a2');
select is((select count(*)::int from public.user_bot_settings), 0, 'and can''t see others'' settings');
reset role;
select * from finish();
rollback;
