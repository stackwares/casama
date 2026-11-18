begin;
create extension if not exists pgtap with schema extensions;
select plan(5);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'dee@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000d2', 'out2@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select public.create_organization('Desk Org', 'desk-org');
reset role;
insert into public.bots (org_id, name) select id, 'Painter' from public.organizations where slug = 'desk-org';
insert into public.computer_desktop_leases (computer_id, bot_id, org_id, expires_at)
  select c.id, b.id, c.org_id, now() + interval '2 minutes'
  from public.computers c join public.bots b on b.org_id = c.org_id
  join public.organizations o on o.id = c.org_id where o.slug = 'desk-org' and c.kind = 'team';
select is((select max_desktops::int from public.computers c join public.organizations o on o.id = c.org_id where o.slug = 'desk-org'), 1, 'one desktop user at a time by default');
select throws_ok($$ update public.computers set max_desktops = 11 where kind = 'team' $$, '23514', null, 'the cap is at most 10');
select throws_ok($$ update public.bots set team_folder = '../etc' where name = 'Painter' $$, '23514', null, 'folder names are plain slugs');
select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select is((select count(*)::int from public.computer_desktop_leases), 1, 'members see who holds the desktop');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000d2');
select is((select count(*)::int from public.computer_desktop_leases), 0, 'outsiders see no leases');
reset role;
select * from finish();
rollback;
