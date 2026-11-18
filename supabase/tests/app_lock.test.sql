-- D-375: the app lock requirement is off for a new workspace, and a member can't change it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000a1c01', 'applock-owner@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000a1c02', 'applock-member@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000a1c01');
select public.create_organization('App Lock', 'app-lock-test');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'app-lock-test'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000a1c02', 'member');

select ok((select not require_app_lock from public.organizations where id = current_setting('test.org')::uuid),
  'a new workspace does not require the app lock');

select pg_temp.login('00000000-0000-0000-0000-0000000a1c02');
update public.organizations set require_app_lock = true where id = current_setting('test.org')::uuid;
reset role;
select ok((select not require_app_lock from public.organizations where id = current_setting('test.org')::uuid),
  'a member cannot turn it on');

select pg_temp.login('00000000-0000-0000-0000-0000000a1c01');
update public.organizations set require_app_lock = true where id = current_setting('test.org')::uuid;
reset role;
select ok((select require_app_lock from public.organizations where id = current_setting('test.org')::uuid),
  'the owner can');
select * from finish();
rollback;
