begin;
create extension if not exists pgtap with schema extensions;
select plan(8);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000325a1', 'n1@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000325a2', 'n2@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000325a1');
select lives_ok($$ insert into public.chat_focus (user_id, client_id, conversation_id)
  values ('00000000-0000-0000-0000-0000000325a1', 'install-one', null) $$, 'people record their own focus');
select throws_ok($$ insert into public.chat_focus (user_id, client_id)
  values ('00000000-0000-0000-0000-0000000325a2', 'install-two') $$, '42501', null, 'but not someone else''s');
select lives_ok($$ update public.chat_focus set updated_at = now() where client_id = 'install-one' $$, 'and refresh it');
select lives_ok($$ update public.profiles set push_prefs = '{"routines": false, "hide_reply_text": true}'
  where user_id = '00000000-0000-0000-0000-0000000325a1' $$, 'and set their push settings');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000325a2');
select is((select count(*)::int from public.chat_focus), 0, 'nobody sees another person''s focus');
reset role;

select is((select push_prefs ->> 'routines' from public.profiles where user_id = '00000000-0000-0000-0000-0000000325a1'),
  'false', 'push settings are stored');
select lives_ok($$ insert into public.notifications (user_id, kind, payload, push_status, read_at)
  values ('00000000-0000-0000-0000-0000000325a1', 'reply', '{}', 'off', now()) $$, 'a row can be kept without a push');
select is((select payload ->> 'push_status' || '|' || (payload ? 'read_at')::text || '|' || (payload ? 'urgency')::text
             || '|' || (payload ? 'held_reason')::text
           from realtime.messages where topic = 'user:00000000-0000-0000-0000-0000000325a1'
           order by inserted_at desc limit 1),
  'off|true|true|true', 'the broadcast carries read state, push status, urgency and hold reason');

select * from finish();
rollback;
