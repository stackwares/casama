begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'owner@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000d2', 'stranger@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select public.create_organization('Mail Org', 'mail-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'mail-org'), true);
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'Ada', '00000000-0000-0000-0000-0000000000d1');
select set_config('test.bot', (select id::text from public.bots where name = 'Ada'), true);
insert into public.channels (org_id, bot_id, kind, name, allowed_senders, created_by)
  values (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'email', 'Mail', '{}', '00000000-0000-0000-0000-0000000000d1');
insert into public.mail_addresses (local_part, org_id, bot_id, channel_id, created_by)
  select 'ada', current_setting('test.org')::uuid, current_setting('test.bot')::uuid, id, '00000000-0000-0000-0000-0000000000d1'
    from public.channels where name = 'Mail';
insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict)
  select id, current_setting('test.org')::uuid, 'in', 'owner@example.com', 'allowed' from public.mail_addresses where local_part = 'ada';
insert into public.mail_suppressions (address_id, email, reason)
  select id, 'gone@example.com', 'bounce' from public.mail_addresses where local_part = 'ada';
insert into public.mail_events (address_id, org_id, event_id, event, recipient)
  select id, current_setting('test.org')::uuid, 'ev-1', 'bounced', 'gone@example.com' from public.mail_addresses where local_part = 'ada';

select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select is((select count(*) from public.mail_addresses)::int, 1, 'the owner sees the bot''s address');
select is((select count(*) from public.mail_messages)::int, 1, 'and its mail');
select is((select count(*) from public.mail_suppressions)::int, 1, 'and its suppressions');
select is((select count(*) from public.mail_events)::int, 1, 'and its delivery events');
select throws_ok($$ insert into public.mail_addresses (local_part) values ('sneaky') $$,
  '42501', null, 'addresses are only created through the API');
select throws_ok($$ insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict)
  values ('00000000-0000-0000-0000-000000000000', current_setting('test.org')::uuid, 'in', 'x@y.z', 'stranger') $$,
  '42501', null, 'mail rows are only written through the API');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000d2');
select is((select count(*) from public.mail_addresses)::int, 0, 'outsiders see no addresses');
select is((select count(*) from public.mail_messages)::int, 0, 'or mail');
select is((select count(*) from public.mail_suppressions)::int, 0, 'or suppressions');
select is((select count(*) from public.mail_events)::int, 0, 'or delivery events');
reset role;

-- A deleted bot retires its address but keeps the name reserved.
delete from public.bots where name = 'Ada';
select is((select status from public.mail_addresses where local_part = 'ada'), 'retired', 'deleting the bot retires the address');
select throws_ok($$ insert into public.mail_addresses (local_part) values ('ada') $$,
  '23505', null, 'the retired name stays reserved');

select * from finish();
rollback;
