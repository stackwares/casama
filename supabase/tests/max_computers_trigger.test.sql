-- The plan's max_computers holds in the database (no create race): hosted computers count, local
-- ones don't, and an unlimited plan has no limit.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into public.organizations (id, name, slug, plan) values
  ('c8000000-0000-0000-0000-000000000001', 'Comp limit', 'comp-limit', 'selfhost'),
  ('c8000000-0000-0000-0000-000000000002', 'Comp other', 'comp-other', 'selfhost');
insert into public.bots (id, org_id, name) values
  ('c8100000-0000-0000-0000-000000000001', 'c8000000-0000-0000-0000-000000000001', 'One'),
  ('c8100000-0000-0000-0000-000000000002', 'c8000000-0000-0000-0000-000000000001', 'Two'),
  ('c8100000-0000-0000-0000-000000000003', 'c8000000-0000-0000-0000-000000000002', 'Three');

-- Self-hosted (no max_computers): no limit.
select lives_ok($$ insert into public.computers (org_id, kind, owner_bot_id, name) values
  ('c8000000-0000-0000-0000-000000000002', 'private', 'c8100000-0000-0000-0000-000000000003', 'Free for all') $$,
  'no max_computers, no limit');

-- Two hosted computers allowed; the auto team computer counts as one.
update public.entitlements set limits = '{"max_computers": 2}'::jsonb
 where org_id = 'c8000000-0000-0000-0000-000000000001';
select is((select count(*)::int from public.computers where org_id = 'c8000000-0000-0000-0000-000000000001' and provider <> 'local'),
  1, 'the workspace starts with its team computer');
select lives_ok($$ insert into public.computers (org_id, kind, owner_bot_id, name) values
  ('c8000000-0000-0000-0000-000000000001', 'private', 'c8100000-0000-0000-0000-000000000001', 'Second') $$,
  'a computer under the limit');
select throws_ok($$ insert into public.computers (org_id, kind, owner_bot_id, name) values
  ('c8000000-0000-0000-0000-000000000001', 'private', 'c8100000-0000-0000-0000-000000000002', 'Third') $$,
  'PT402', null, 'one past the limit is refused');
select lives_ok($$ insert into public.computers (org_id, kind, provider, name) values
  ('c8000000-0000-0000-0000-000000000001', 'local', 'local', 'This Mac') $$,
  'local computers don''t count');
select throws_ok($$ update public.computers set provider = 'docker'
  where org_id = 'c8000000-0000-0000-0000-000000000001' and provider = 'local' $$,
  'PT402', null, 'turning a local computer hosted is checked');
select throws_ok($$ update public.computers set org_id = 'c8000000-0000-0000-0000-000000000001', owner_bot_id = 'c8100000-0000-0000-0000-000000000002'
  where org_id = 'c8000000-0000-0000-0000-000000000002' and kind = 'private' $$,
  'PT402', null, 'moving a computer into a full workspace is checked');
select lives_ok($$ update public.computers set name = 'Renamed', state = 'running'
  where org_id = 'c8000000-0000-0000-0000-000000000001' and kind = 'private' $$,
  'ordinary updates in a full workspace still work');
-- Server writes are checked too (computers are only made by the server).
select throws_ok($$ insert into public.computers (org_id, kind, provider, owner_bot_id, name) values
  ('c8000000-0000-0000-0000-000000000001', 'private', 'casama-cloud', 'c8100000-0000-0000-0000-000000000002', 'Cloud') $$,
  'PT402', null, 'every hosted provider counts');

select * from finish();
rollback;
