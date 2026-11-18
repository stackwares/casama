-- D-331: reactions on messages. Readers of a chat see its reactions; people add, change and
-- remove only their own; one per person per message; conversation and workspace come from the
-- message; every change is announced on the conversation's topic.
begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000000f1', 'rx-a@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000000f2', 'rx-b@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000000f3', 'rx-c@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-0000000000f1', 'Rx A', 'rx-a'),
  ('20000000-0000-0000-0000-0000000000f2', 'Rx B', 'rx-b');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', 'owner'),
  ('20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f3', 'member'),
  ('20000000-0000-0000-0000-0000000000f2', '10000000-0000-0000-0000-0000000000f2', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', 'Ada', 'team');
insert into public.conversations (id, org_id, bot_id, created_by) values
  ('40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '30000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1');
insert into public.messages (id, org_id, conversation_id, role, author_user_id, content) values
  ('60000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', 'user', '10000000-0000-0000-0000-0000000000f1', '[{"type":"text","text":"hi"}]'),
  ('60000000-0000-0000-0000-0000000000f2', '20000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', 'assistant', null, '[{"type":"text","text":"hello"}]'),
  ('60000000-0000-0000-0000-0000000000f3', '20000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', 'tool', null, '[]');

create or replace function pg_temp.sent() returns int language sql as $$
  select count(*)::int from realtime.messages
  where topic = 'conversation:40000000-0000-0000-0000-0000000000f1' and event = 'message_reaction'
$$;

select ok(exists (select 1 from pg_policies where tablename = 'message_reactions' and policyname = 'casama_worker_all'), 'the worker can read and write reactions');

set local role authenticated;
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f1", "role": "authenticated"}';

-- conversation_id and org_id are taken from the message, whatever was sent.
insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
values ('60000000-0000-0000-0000-0000000000f2', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f2', '10000000-0000-0000-0000-0000000000f1', '❤️');
select is((select org_id::text from public.message_reactions where message_id = '60000000-0000-0000-0000-0000000000f2'),
  '20000000-0000-0000-0000-0000000000f1', 'the workspace comes from the message');
reset role;
select is(pg_temp.sent(), 1, 'adding a reaction is announced on the conversation');
select is(
  (select payload - 'id' from realtime.messages where topic = 'conversation:40000000-0000-0000-0000-0000000000f1' and event = 'message_reaction' limit 1),
  '{"kind": "reaction", "message_id": "60000000-0000-0000-0000-0000000000f2"}'::jsonb,
  'the announcement carries only the message id');
set local role authenticated;

select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f2', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', '👍')
$$, '23505', null, 'one reaction per person per message');

update public.message_reactions set emoji = '👍' where message_id = '60000000-0000-0000-0000-0000000000f2';
select is((select emoji from public.message_reactions where message_id = '60000000-0000-0000-0000-0000000000f2'), '👍', 'a person can change their reaction');

select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f3', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', '👍')
$$, '22023', null, 'tool messages take no reactions');

select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', 'lol')
$$, '23514', null, 'words are not a reaction');

select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f3', '👍')
$$, '42501', null, 'nobody reacts as someone else');

select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, bot_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '30000000-0000-0000-0000-0000000000f1', '👍')
$$, '42501', null, 'people cannot react as a bot');

insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', '1️⃣');
select is((select count(*)::int from public.message_reactions), 2, 'a keycap emoji is a reaction');

-- A teammate who can see the bot sees the reactions but can't touch them.
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f3", "role": "authenticated"}';
select is((select count(*)::int from public.message_reactions), 2, 'a teammate who can read the chat sees its reactions');
update public.message_reactions set emoji = '😡';
select is((select count(*)::int from public.message_reactions where emoji = '😡'), 0, 'nobody changes someone else''s reaction');
delete from public.message_reactions;
reset role;
select is((select count(*)::int from public.message_reactions), 2, 'nobody removes someone else''s reaction');
set local role authenticated;

-- Another workspace sees nothing and can't react.
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f2", "role": "authenticated"}';
select is((select count(*)::int from public.message_reactions), 0, 'another workspace sees no reactions');
select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f2', '👍')
$$, '42501', null, 'another workspace cannot react');

set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f1", "role": "authenticated"}';
delete from public.message_reactions where message_id = '60000000-0000-0000-0000-0000000000f1';
select is((select count(*)::int from public.message_reactions), 1, 'a person removes their own reaction');
reset role;
select is(pg_temp.sent(), 4, 'adding, changing and removing are each announced');

-- Someone in a chat app (no Casama account) reacts through the worker; the chat's readers see it.
insert into public.channels (id, org_id, bot_id, kind, name) values
  ('70000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '30000000-0000-0000-0000-0000000000f1', 'telegram', 'tg');
insert into public.message_reactions (message_id, conversation_id, org_id, external_sender, external_name, emoji, source)
values ('60000000-0000-0000-0000-0000000000f2', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '70000000-0000-0000-0000-0000000000f1:42', 'Mara', '🔥', 'channel');
select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, external_sender, emoji, source)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', 'x:1', '👍', 'app')
$$, '23514', null, 'a chat-app sender''s reaction is always marked as from a chat app');
select throws_ok($$
  insert into public.message_reactions (message_id, conversation_id, org_id, user_id, bot_id, emoji, source)
  values ('60000000-0000-0000-0000-0000000000f1', '40000000-0000-0000-0000-0000000000f1', '20000000-0000-0000-0000-0000000000f1', '10000000-0000-0000-0000-0000000000f1', '30000000-0000-0000-0000-0000000000f1', '👍', 'app')
$$, '23514', null, 'a reaction has exactly one author');
insert into public.channel_message_links (channel_id, ref, message_id, org_id) values
  ('70000000-0000-0000-0000-0000000000f1', '99:7', '60000000-0000-0000-0000-0000000000f2', '20000000-0000-0000-0000-0000000000f1');
set local role authenticated;
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f3", "role": "authenticated"}';
select is((select count(*)::int from public.message_reactions where external_sender is not null), 1, 'readers see a chat-app sender''s reaction');
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000f1", "role": "authenticated"}';
select is((select count(*)::int from public.channel_message_links), 0, 'chat-app message links are server-only');
reset role;
select ok(exists (select 1 from pg_policies where tablename = 'channel_message_links' and policyname = 'casama_worker_all'), 'the worker can read and write message links');

delete from public.messages where id = '60000000-0000-0000-0000-0000000000f2';
select is((select count(*)::int from public.message_reactions), 0, 'deleting a message deletes its reactions');
select is((select count(*)::int from public.channel_message_links), 0, 'and its chat-app links');

select * from finish();
rollback;
