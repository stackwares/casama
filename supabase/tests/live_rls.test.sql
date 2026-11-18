begin;
create extension if not exists pgtap;
select plan(5);

insert into auth.users (id, email) values
  ('a1000000-0000-0000-0000-000000000001', 'live-owner@example.com'),
  ('a1000000-0000-0000-0000-000000000002', 'live-outsider@example.com');
insert into public.organizations (id, name, slug) values
  ('a2000000-0000-0000-0000-000000000001', 'Live A', 'live-a'),
  ('a2000000-0000-0000-0000-000000000002', 'Live B', 'live-b');
insert into public.memberships (org_id, user_id, role) values
  ('a2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'owner'),
  ('a2000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 'owner');
insert into public.bots (id, org_id, name, created_by) values
  ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Ada', 'a1000000-0000-0000-0000-000000000001');
insert into public.computers (id, org_id, kind, owner_bot_id, name, profile) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'private', 'a3000000-0000-0000-0000-000000000001', 'Ada''s computer', 'desktop');
insert into public.runs (id, org_id, bot_id, trigger, status) values
  ('a5000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'chat', 'waiting_takeover');
insert into public.takeover_requests (org_id, bot_id, run_id, computer_id, reason) values
  ('a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a5000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'Please sign in to the site');
insert into public.computer_leases (org_id, computer_id, holder_type, holder_id, mode, expires_at) values
  ('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'user', 'a1000000-0000-0000-0000-000000000001', 'control', now() + interval '15 minutes');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is((select count(*)::int from public.takeover_requests), 1, 'members see their bots'' takeover requests');
select is((select count(*)::int from public.computer_leases where computer_id = 'a4000000-0000-0000-0000-000000000001'), 1, 'members see leases on their computers');
update public.takeover_requests set status = 'completed';
select is((select status from public.takeover_requests limit 1), 'pending', 'users cannot change takeover requests');

select set_config('request.jwt.claims', '{"sub":"a1000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is((select count(*)::int from public.takeover_requests), 0, 'outsiders see no takeover requests');
select is((select count(*)::int from public.computer_leases where computer_id = 'a4000000-0000-0000-0000-000000000001'), 0, 'outsiders see no leases');

select * from finish();
rollback;
