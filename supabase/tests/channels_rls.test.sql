begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000c1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000c2', 'eve@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select public.create_organization('Chat Org', 'chat-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'chat-org'), true);
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'Desk', '00000000-0000-0000-0000-0000000000c1');
select set_config('test.bot', (select id::text from public.bots where name = 'Desk'), true);
insert into public.channels (org_id, bot_id, kind, name, allowed_senders, created_by)
  values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'telegram', 'TG', '{7}', '00000000-0000-0000-0000-0000000000c1');
insert into public.channel_events (channel_id, org_id, direction, status, sender, preview)
  select id, org_id, 'in', 'ignored', '99', 'spam' from public.channels where name = 'TG';

select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select is((select count(*) from public.channels)::int, 1, 'the owner sees the bot''s chat app');
select is((select count(*) from public.channel_events)::int, 1, 'and its activity');
select throws_ok($$ insert into public.channels (org_id, bot_id, kind, name) values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'sms', 'x') $$,
  '42501', null, 'chat apps are only created through the API (secrets go to Vault)');
select is((select count(*) from public.channel_threads)::int, 0, 'thread mappings are not readable by users');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000c2');
select is((select count(*) from public.channels)::int, 0, 'outsiders see no chat apps');
select is((select count(*) from public.channel_events)::int, 0, 'or activity');
select lives_ok($$ delete from public.channels $$, 'deleting as an outsider is a no-op');
reset role;

select * from finish();
rollback;
