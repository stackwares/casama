-- D-334: leaving a workspace pauses the person's routines and watchers there (nothing else), and
-- knowledge uploads count toward the workspace's storage.
begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000d3341', 'leave-owner@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000d3342', 'leave-member@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug, plan) values
  ('d3340000-0000-0000-0000-000000000001', 'Leave one', 'leave-one-d334', 'selfhost'),
  ('d3340000-0000-0000-0000-000000000002', 'Leave two', 'leave-two-d334', 'selfhost');
insert into public.memberships (org_id, user_id, role) values
  ('d3340000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3341', 'owner'),
  ('d3340000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3342', 'member'),
  ('d3340000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000d3342', 'owner');
insert into public.bots (id, org_id, name) values
  ('d3341000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'One'),
  ('d3341000-0000-0000-0000-000000000002', 'd3340000-0000-0000-0000-000000000002', 'Two');
insert into public.routines (id, org_id, bot_id, created_by, name, instructions_md, schedule_cron) values
  ('d3342000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'd3341000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3342', 'Mine here', 'x', '0 9 * * *'),
  ('d3342000-0000-0000-0000-000000000002', 'd3340000-0000-0000-0000-000000000001', 'd3341000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3341', 'Owner''s', 'x', '0 9 * * *'),
  ('d3342000-0000-0000-0000-000000000003', 'd3340000-0000-0000-0000-000000000002', 'd3341000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000d3342', 'Mine there', 'x', '0 9 * * *');
insert into public.watchers (id, org_id, bot_id, created_by, name, kind, target) values
  ('d3343000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'd3341000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3342', 'Mine here', 'time', '{}'),
  ('d3343000-0000-0000-0000-000000000002', 'd3340000-0000-0000-0000-000000000001', 'd3341000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000d3341', 'Owner''s', 'time', '{}'),
  ('d3343000-0000-0000-0000-000000000003', 'd3340000-0000-0000-0000-000000000002', 'd3341000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000d3342', 'Mine there', 'time', '{}');

delete from public.memberships
 where org_id = 'd3340000-0000-0000-0000-000000000001' and user_id = '00000000-0000-0000-0000-0000000d3342';

select is((select enabled from public.routines where id = 'd3342000-0000-0000-0000-000000000001'), false,
  'their routine in the workspace they left is switched off');
select is((select status from public.watchers where id = 'd3343000-0000-0000-0000-000000000001'), 'paused',
  'their watcher there is paused');
select is((select enabled from public.routines where id = 'd3342000-0000-0000-0000-000000000002'), true,
  'a routine of someone still there keeps running');
select is((select status from public.watchers where id = 'd3343000-0000-0000-0000-000000000002'), 'active',
  'and so does their watcher');
select is((select enabled from public.routines where id = 'd3342000-0000-0000-0000-000000000003'), true,
  'their routine in a workspace they stayed in keeps running');
select is((select status from public.watchers where id = 'd3343000-0000-0000-0000-000000000003'), 'active',
  'and so does their watcher there');
select lives_ok($$ delete from public.organizations where id = 'd3340000-0000-0000-0000-000000000002' $$,
  'deleting a workspace still works');

-- Knowledge uploads count toward storage.
insert into public.knowledge_sources (id, org_id, kind, name) values
  ('d3344000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'upload', 'Files');
update public.organizations set storage_bytes = 100 where id = 'd3340000-0000-0000-0000-000000000001';
insert into public.knowledge_uploads (source_id, org_id, name, content) values
  ('d3344000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'a.md', convert_to(repeat('a', 1000), 'UTF8')),
  ('d3344000-0000-0000-0000-000000000001', 'd3340000-0000-0000-0000-000000000001', 'b.md', convert_to(repeat('b', 500), 'UTF8'));
select is((select storage_bytes from public.organizations where id = 'd3340000-0000-0000-0000-000000000001'), 1600::bigint,
  'uploads add their bytes to the workspace''s storage');
delete from public.knowledge_uploads where name = 'b.md' and org_id = 'd3340000-0000-0000-0000-000000000001';
select is((select storage_bytes from public.organizations where id = 'd3340000-0000-0000-0000-000000000001'), 1100::bigint,
  'deleting an upload gives its bytes back');
delete from public.knowledge_sources where id = 'd3344000-0000-0000-0000-000000000001';
select is((select storage_bytes from public.organizations where id = 'd3340000-0000-0000-0000-000000000001'), 100::bigint,
  'deleting the source gives the rest back');

-- A drafting failure's reason fits on the recording.
select has_column('public', 'teach_sessions', 'error_code', 'teach recordings keep why a draft failed');

select * from finish();
rollback;
