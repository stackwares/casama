begin;
create extension if not exists pgtap;
select plan(4);

insert into auth.users (id, email) values
  ('b1000000-0000-0000-0000-000000000001', 'reach-owner@example.com'),
  ('b1000000-0000-0000-0000-000000000002', 'reach-member@example.com'),
  ('b1000000-0000-0000-0000-000000000003', 'reach-outsider@example.com');
insert into public.organizations (id, name, slug) values ('b2000000-0000-0000-0000-000000000001', 'Reach', 'reach');
insert into public.memberships (org_id, user_id, role) values
  ('b2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'owner'),
  ('b2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', 'member');
insert into public.local_devices (org_id, user_id, name, platform, token_hash) values
  ('b2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', 'Laptop', 'macos', 'hash-1');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is((select count(*)::int from public.local_devices where token_hash = 'hash-1'), 1, 'members see their own devices');
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is((select count(*)::int from public.local_devices where token_hash = 'hash-1'), 1, 'admins see the org''s devices');
select is((select count(*)::int from public.tts_cache), 0, 'nobody reads the audio cache directly');
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select is((select count(*)::int from public.local_devices where token_hash = 'hash-1'), 0, 'outsiders see no devices');

select * from finish();
rollback;
