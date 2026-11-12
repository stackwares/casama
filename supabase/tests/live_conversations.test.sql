-- D-224: a run starting in a conversation is announced on its topic; only people who can read
-- the conversation may listen.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000000e1', 'conv-a@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000000e2', 'conv-b@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-0000000000e1', 'Conv A', 'conv-a'),
  ('20000000-0000-0000-0000-0000000000e2', 'Conv B', 'conv-b');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000e1', 'owner'),
  ('20000000-0000-0000-0000-0000000000e2', '10000000-0000-0000-0000-0000000000e2', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-0000000000e1', '20000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000e1', 'Ada', 'private');
insert into public.conversations (id, org_id, bot_id, created_by) values
  ('40000000-0000-0000-0000-0000000000e1', '20000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000e1', '10000000-0000-0000-0000-0000000000e1');

create or replace function pg_temp.sent() returns int language sql as $$
  select count(*)::int from realtime.messages
  where topic = 'conversation:40000000-0000-0000-0000-0000000000e1' and event = 'conversation_activity'
$$;

insert into public.runs (id, org_id, bot_id, conversation_id, trigger, status) values
  ('50000000-0000-0000-0000-0000000000e1', '20000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000e1', '40000000-0000-0000-0000-0000000000e1', 'chat', 'queued');
select is(pg_temp.sent(), 1, 'a run starting in a conversation is announced on its topic');
select is(
  (select payload - 'id' from realtime.messages where topic = 'conversation:40000000-0000-0000-0000-0000000000e1' limit 1),
  '{"kind": "run", "run_id": "50000000-0000-0000-0000-0000000000e1"}'::jsonb,
  'the message carries only the run id');

update public.runs set status = 'running' where id = '50000000-0000-0000-0000-0000000000e1';
insert into public.runs (org_id, bot_id, trigger, status) values
  ('20000000-0000-0000-0000-0000000000e1', '30000000-0000-0000-0000-0000000000e1', 'schedule', 'queued');
select is(pg_temp.sent(), 1, 'status changes and runs outside a conversation stay quiet');

set local role authenticated;
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000e1", "role": "authenticated"}';
select ok(public.realtime_topic_allowed('conversation:40000000-0000-0000-0000-0000000000e1'), 'someone who can read the chat may listen');
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000e2", "role": "authenticated"}';
select ok(not public.realtime_topic_allowed('conversation:40000000-0000-0000-0000-0000000000e1'), 'someone from another workspace may not');
select ok(not public.realtime_topic_allowed('conversation:not-a-uuid'), 'a malformed topic is denied');
reset role;

select * from finish();
rollback;
