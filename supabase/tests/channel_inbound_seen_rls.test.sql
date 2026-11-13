-- D-270: the record of chat-app messages already seen is server-only.
begin;
create extension if not exists pgtap with schema extensions;
select plan(2);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c0d1', 'own-seen@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000c0d1');
select public.create_organization('Seen Org', 'seen-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'seen-org'), true);
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'S', '00000000-0000-0000-0000-00000000c0d1');
insert into public.channels (org_id, bot_id, kind, name)
  select current_setting('test.org')::uuid, id, 'telegram', 'tg' from public.bots where org_id = current_setting('test.org')::uuid;
insert into public.channel_inbound_seen (channel_id, message_id) select id, 'u1' from public.channels where org_id = current_setting('test.org')::uuid;
select is((select count(*)::int from public.channel_inbound_seen), 1, 'the server sees the row');
select pg_temp.login('00000000-0000-0000-0000-00000000c0d1');
select is((select count(*)::int from public.channel_inbound_seen), 0, 'the workspace owner sees nothing');
reset role;
select * from finish();
rollback;
