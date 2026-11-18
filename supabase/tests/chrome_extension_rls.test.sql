-- D-323 (Casama for Chrome, Phase 1): attachments a person sends stay out of the Library; things
-- they save go in it, private to them; the extension is a push platform of its own.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c4e1', 'chrome-own@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000c4e2', 'chrome-mem@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000c4e1');
select public.create_organization('Chrome Org', 'chrome-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'chrome-org'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000c4e2', 'member');

insert into public.chat_media (org_id, name, content_type, bytes, size, uploaded_by, in_library)
values (current_setting('test.org')::uuid, 'shot.png', 'image/png', '\x89504e47'::bytea, 4, '00000000-0000-0000-0000-00000000c4e1', false),
       (current_setting('test.org')::uuid, 'Saved page.md', 'text/markdown', '\x2320'::bytea, 2, '00000000-0000-0000-0000-00000000c4e1', true);
select is((select count(*)::int from public.creations where org_id = current_setting('test.org')::uuid), 1,
  'a message attachment is not put in the Library; a saved page is');
select is((select made_for from public.creations where org_id = current_setting('test.org')::uuid),
  '00000000-0000-0000-0000-00000000c4e1'::uuid, 'a saved page is made for the person who saved it');
select is((select kind || ' ' || title from public.creations where org_id = current_setting('test.org')::uuid),
  'document Saved page', 'it is a document titled from its name');
select is((select storage_bytes from public.organizations where id = current_setting('test.org')::uuid), 6::bigint,
  'the attachment counts toward storage too, though it is not in the Library');
delete from public.chat_media where name = 'shot.png';
select is((select storage_bytes from public.organizations where id = current_setting('test.org')::uuid), 2::bigint,
  'deleting the attachment gives its space back');

select pg_temp.login('00000000-0000-0000-0000-00000000c4e2');
select is((select count(*)::int from public.creations), 0, 'another member does not see it');
select pg_temp.login('00000000-0000-0000-0000-00000000c4e1');
select lives_ok($$ insert into public.devices (user_id, platform, fcm_token) values ('00000000-0000-0000-0000-00000000c4e1', 'chrome', 'chrome-token-1') $$,
  'the extension registers its own devices row');
select throws_ok($$ insert into public.devices (user_id, platform, fcm_token) values ('00000000-0000-0000-0000-00000000c4e2', 'chrome', 'chrome-token-2') $$,
  '42501', null, 'but not for someone else');
reset role;
select * from finish();
rollback;
