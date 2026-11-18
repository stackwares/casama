-- Live calls (D-327): people read only their own calls; nobody writes them from the app; the
-- worker ends and bills them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000327a1', 'caller@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000327a2', 'teammate@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000327a3', 'outsider@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000327a1');
select public.create_organization('Calls', 'calls-327');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'calls-327'), true);
insert into public.memberships (org_id, user_id, role)
  values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000327a2', 'member');
insert into public.bots (id, org_id, name, created_by) values
  ('00000000-0000-0000-0000-0000000327b1', current_setting('test.org')::uuid, 'Ava', '00000000-0000-0000-0000-0000000327a1');
insert into public.conversations (id, org_id, bot_id, created_by) values
  ('00000000-0000-0000-0000-0000000327c1', current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000327b1', '00000000-0000-0000-0000-0000000327a1');
insert into public.live_calls (id, org_id, bot_id, conversation_id, user_id) values
  ('00000000-0000-0000-0000-0000000327d1', current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000327b1',
   '00000000-0000-0000-0000-0000000327c1', '00000000-0000-0000-0000-0000000327a1');
insert into public.live_call_turns (live_call_id, turn_id) values ('00000000-0000-0000-0000-0000000327d1', 't-1');

select pg_temp.login('00000000-0000-0000-0000-0000000327a1');
select is((select count(*)::int from public.live_calls), 1, 'the caller sees their call');
select is((select count(*)::int from public.live_call_turns), 0, 'but not the saved-turn ids');
select throws_ok($$
  insert into public.live_calls (org_id, bot_id, conversation_id, user_id)
  values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000327b1',
          '00000000-0000-0000-0000-0000000327c1', '00000000-0000-0000-0000-0000000327a1')
$$, '42501', null, 'the app cannot start a call record itself');
update public.live_calls set ended_at = now();
reset role;
select is((select count(*)::int from public.live_calls where ended_at is not null), 0, 'nor end one');

select pg_temp.login('00000000-0000-0000-0000-0000000327a2');
select is((select count(*)::int from public.live_calls), 0, 'a teammate does not see someone else''s call');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000327a3');
select is((select count(*)::int from public.live_calls), 0, 'an outsider sees nothing');
reset role;

set local role casama_worker;
select lives_ok($$
  update public.live_calls set ended_at = now(), end_reason = 'silent'
  where id = '00000000-0000-0000-0000-0000000327d1'
$$, 'the worker ends silent calls');
select is((select end_reason from public.live_calls where id = '00000000-0000-0000-0000-0000000327d1'), 'silent',
  'and the change sticks');
reset role;

select * from finish();
rollback;
