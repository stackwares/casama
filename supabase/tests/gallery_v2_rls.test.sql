-- Gallery v2 (D-315): usage counts stay server-only; workspace rows only for members.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000f1', 'gal@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000f2', 'out@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select public.create_organization('Gallery Org', 'gallery-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'gallery-org'), true);
insert into public.gallery_installs (item_key, user_hash) values ('skill/meeting-notes', repeat('a', 64));
insert into public.gallery_item_stats (item_key, installers) values ('skill/meeting-notes', 12);
insert into public.gallery_links (org_id, target_kind, target_id, item_key, installed_by)
  values (current_setting('test.org')::uuid, 'skill', 'x', 'skill/meeting-notes', '00000000-0000-0000-0000-0000000000f1');
insert into public.gallery_policies (org_id, policy) values (current_setting('test.org')::uuid, '{"mode":"open"}');
insert into public.gallery_approvals (org_id, requested_by, item_type, item_id, name, reason)
  values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000000f1', 'skill', 'meeting-notes', 'Meeting notes', 'x');
insert into public.gallery_requests (kind, title, created_by) values ('skill', 'Recipe planner', '00000000-0000-0000-0000-0000000000f1');

select pg_temp.login('00000000-0000-0000-0000-0000000000f1');
select is((select count(*)::int from public.gallery_installs), 0, 'nobody reads usage rows');
select is((select count(*)::int from public.gallery_item_stats), 0, 'stats are served by the API only');
select is((select count(*)::int from public.gallery_links), 1, 'members see their workspace''s gallery links');
select is((select count(*)::int from public.gallery_policies), 1, 'members see their workspace''s gallery rules');
select is((select count(*)::int from public.gallery_approvals), 1, 'the requester sees their approval');
select is((select count(*)::int from public.gallery_requests), 0, 'the requests board is served by the API');
select throws_ok($$
  insert into public.gallery_links (org_id, target_kind, target_id, item_key)
  values (current_setting('test.org')::uuid, 'skill', 'y', 'skill/other')
$$, '42501', null, 'members cannot write gallery links directly');
select throws_ok($$
  insert into public.gallery_installs (item_key, user_hash) values ('skill/x', repeat('b', 64))
$$, '42501', null, 'clients cannot write usage rows');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000f2');
select is((select count(*)::int from public.gallery_links), 0, 'outsiders see no gallery links');
select is((select count(*)::int from public.gallery_policies), 0, 'outsiders see no gallery rules');
select is((select count(*)::int from public.gallery_approvals), 0, 'outsiders see no approvals');
reset role;

select lives_ok($$
  insert into public.content_reports (target_kind, target_id, reason) values ('gallery_item', 'app/x', 'health:dead_link')
$$, 'the nightly check can file health findings');
select * from finish();
rollback;
