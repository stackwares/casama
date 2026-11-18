-- Casama Link (D-296): who can read the linked servers, link codes and sign-in codes directly.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000c1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000c2', 'ben@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000c3', 'eve@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

-- Ana owns a workspace, Ben is a member of it, Eve owns another.
select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select public.create_organization('Home', 'link-home');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000c3');
select public.create_organization('Elsewhere', 'link-elsewhere');
reset role;
insert into public.memberships (org_id, user_id, role)
  select id, '00000000-0000-0000-0000-0000000000c2', 'member' from public.organizations where slug = 'link-home';

insert into public.link_servers (org_id, instance_id, instance_name, label, tunnel_id)
  select id, 'home-mac-0001', 'Home Mac', 'k7qm2xfd9abc', 'tunnel-1' from public.organizations where slug = 'link-home';
insert into public.link_sign_in_requests (device_code_hash, user_code, instance_id, instance_name, org_id, expires_at)
  select 'hash-of-device-code', 'K7QM-2XFD', 'home-mac-0001', 'Home Mac', id, now() + interval '15 minutes'
  from public.organizations where slug = 'link-home';
insert into public.signin_codes (user_id, code_hash, expires_at)
  values ('00000000-0000-0000-0000-0000000000c1', 'hash-of-sign-in-code', now() + interval '5 minutes');

select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select is((select count(*) from public.link_servers)::int, 1, 'an owner sees the workspace''s servers');
select is((select count(*) from public.link_sign_in_requests)::int, 0, 'but never a link code, even their own workspace''s');
select is((select count(*) from public.signin_codes)::int, 0, 'or a sign-in code, even their own');
select throws_ok($$ insert into public.link_servers (org_id, instance_id, instance_name, label)
  select id, 'made-by-hand-01', 'Mine', 'handmade0001' from public.organizations where slug = 'link-home' $$,
  '42501', null, 'and nobody makes an address by hand');
update public.link_servers set label = 'takenover0001';
reset role;
select is((select label from public.link_servers where instance_id = 'home-mac-0001'), 'k7qm2xfd9abc', 'or changes one');

select pg_temp.login('00000000-0000-0000-0000-0000000000c2');
select is((select count(*) from public.link_servers)::int, 0, 'a member who isn''t an admin doesn''t see the servers');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000c3');
select is((select count(*) from public.link_servers)::int, 0, 'another workspace''s owner doesn''t either');
select is((select count(*) from public.signin_codes)::int, 0, 'nor anyone''s sign-in codes');
reset role;

set local role casama_worker;
select is((select count(*) from public.link_servers)::int, 1, 'the worker, which does the upkeep, sees the servers');
reset role;

select * from finish();
rollback;
