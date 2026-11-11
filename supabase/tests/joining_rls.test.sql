begin;
create extension if not exists pgtap with schema extensions;
select plan(10);
insert into auth.users (id, email, aud, role, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000d1', 'own@acme.dev', 'authenticated', 'authenticated', now()),
  ('00000000-0000-0000-0000-0000000000d2', 'new@acme.dev', 'authenticated', 'authenticated', null),
  ('00000000-0000-0000-0000-0000000000d3', 'pal@acme.dev', 'authenticated', 'authenticated', now()),
  ('00000000-0000-0000-0000-0000000000d4', 'me@gmail.com', 'authenticated', 'authenticated', now());
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select public.create_organization('Acme', 'acme-j');
insert into public.invite_links (org_id, role, token_hash, token_hint, created_by, requires_approval)
  select id, 'member', 'gate-1', 'kjoin_ga', '00000000-0000-0000-0000-0000000000d1', true from public.organizations where slug = 'acme-j';
select lives_ok($$ insert into public.org_join_domains (org_id, domain, created_by)
  select id, 'acme.dev', '00000000-0000-0000-0000-0000000000d1' from public.organizations where slug = 'acme-j' $$,
  'an admin opens the workspace to their own verified domain');
select throws_ok($$ insert into public.org_join_domains (org_id, domain, created_by)
  select id, 'other.dev', '00000000-0000-0000-0000-0000000000d1' from public.organizations where slug = 'acme-j' $$,
  '42501', null, 'not someone else''s domain');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000d2');
select is((select status from public.use_invite_link('gate-1')), 'requested', 'a link that asks first files a request');
select is((select count(*)::int from public.memberships m join public.organizations o on o.id = m.org_id where o.slug = 'acme-j'
           and m.user_id = '00000000-0000-0000-0000-0000000000d2'), 0, 'and does not join yet');
select is((select count(*)::int from public.join_requests), 1, 'people see their own request');
select is((select count(*)::int from public.joinable_workspaces()), 0, 'an unverified address sees no domain workspaces');
select throws_ok($$ select public.decide_join_request((select id from public.join_requests limit 1), true) $$,
  'P0002', null, 'people cannot approve themselves');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000d3');
select is((select count(*)::int from public.join_requests), 0, 'outsiders do not see requests');
select is((select org_name from public.joinable_workspaces()), 'Acme', 'a verified address at the domain sees the workspace');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000d4');
select public.create_organization('Mine', 'mine-j');
select throws_ok($$ insert into public.org_join_domains (org_id, domain, created_by)
  select id, 'gmail.com', '00000000-0000-0000-0000-0000000000d4' from public.organizations where slug = 'mine-j' $$,
  '42501', null, 'shared domains cannot be claimed');
reset role;
select * from finish();
rollback;
