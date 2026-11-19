-- D-413: a person's message is announced on its conversation's topic, so the same account's
-- other devices show it while the bot works; the bot's own messages are not (they stream).
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000000f1', 'two-devices@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-0000000000f1', 'Two Devices', 'two-devices');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', 'Ada', 'private');
insert into public.conversations (id, org_id, bot_id, created_by) values
  ('40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '30000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1');

create or replace function pg_temp.sent() returns int language sql as $$
  select count(*)::int from realtime.messages
  where topic = 'conversation:40000000-0000-0000-0000-0000000000f1' and event = 'conversation_message'
$$;

insert into public.messages (id, org_id, conversation_id, role, author_user_id, content) values
  ('60000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', 'user',
   '10000000-0000-0000-0000-0000000000f1', '[{"type":"text","text":"Plan the trip"}]');
select is(pg_temp.sent(), 1, 'a message from a person is announced on the conversation''s topic');
select is(
  (select payload - 'id' from realtime.messages
    where topic = 'conversation:40000000-0000-0000-0000-0000000000f1' and event = 'conversation_message' limit 1),
  '{"kind": "message", "message_id": "60000000-0000-0000-0000-0000000000f1"}'::jsonb,
  'the announcement carries only the message id');

insert into public.messages (org_id, conversation_id, role, bot_id, content) values
  ('20000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', 'assistant',
   '30000000-0000-0000-0000-0000000000f1', '[{"type":"text","text":"On it."}]');
select is(pg_temp.sent(), 1, 'the bot''s own messages are not announced this way');

-- The second message continues from the first: appends go one after another (the lock).
select is(
  (select parent_message_id from public.messages where role = 'assistant'
    and conversation_id = '40000000-0000-0000-0000-0000000000f1'),
  '60000000-0000-0000-0000-0000000000f1'::uuid,
  'a message added without a parent continues the shown branch');

select * from finish();
rollback;
