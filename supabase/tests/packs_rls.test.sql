-- Packs (docs/PLUGINS-AND-PACKS-PLAN.md): members read their workspace's packs; only the API writes.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'pack@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000a2', 'pack-out@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000a1');
select public.create_organization('Pack Org', 'pack-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'pack-org'), true);
insert into public.packs (id, org_id, name, source)
  values ('00000000-0000-0000-0000-0000000000b1', current_setting('test.org')::uuid, 'hello-pack', '{"kind":"upload"}');
insert into public.pack_files (pack_id, org_id, path, content)
  values ('00000000-0000-0000-0000-0000000000b1', current_setting('test.org')::uuid, 'plugin.json', '{}'::bytea);
insert into public.pack_items (pack_id, org_id, kind, item_id)
  values ('00000000-0000-0000-0000-0000000000b1', current_setting('test.org')::uuid, 'look', 'theme/x');
insert into public.pack_shares (org_id, token_hash, name, files, expires_at)
  values (current_setting('test.org')::uuid, repeat('c', 64), 'shared', '[]', now() + interval '1 day');

select pg_temp.login('00000000-0000-0000-0000-0000000000a1');
select is((select count(*)::int from public.packs), 1, 'members see their workspace''s packs');
select is((select count(*)::int from public.pack_files), 1, 'members see a pack''s files');
select is((select count(*)::int from public.pack_items), 1, 'members see what a pack made');
select is((select count(*)::int from public.pack_shares), 1, 'members see their workspace''s share links');
select throws_ok($$
  insert into public.packs (org_id, name, source) values (current_setting('test.org')::uuid, 'other', '{"kind":"upload"}')
$$, '42501', null, 'members cannot install a pack directly');
select throws_ok($$
  insert into public.pack_shares (org_id, token_hash, name, files, expires_at)
  values (current_setting('test.org')::uuid, repeat('d', 64), 'x', '[]', now())
$$, '42501', null, 'members cannot make share links directly');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000a2');
select is((select count(*)::int from public.packs), 0, 'outsiders see no packs');
select is((select count(*)::int from public.pack_items), 0, 'outsiders see no pack items');
select is((select count(*)::int from public.pack_shares), 0, 'outsiders see no share links (the API serves them by token)');
reset role;

select throws_ok($$
  insert into public.packs (org_id, name, source) values (current_setting('test.org')::uuid, 'Bad Name', '{}')
$$, '23514', null, 'pack names follow the plugin name rules');
select lives_ok($$
  insert into public.gallery_approvals (org_id, requested_by, item_type, item_id, name, reason)
  values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000000a1', 'pack', 'pack/hello-pack', 'hello-pack', 'x')
$$, 'a pack can wait for an admin');
select lives_ok($$
  insert into public.content_reports (target_kind, target_id, reason) values ('pack_share', gen_random_uuid()::text, 'spam')
$$, 'a shared pack can be reported');
select * from finish();
rollback;
