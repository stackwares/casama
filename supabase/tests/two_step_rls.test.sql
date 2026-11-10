begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000a2', 'max@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid, aal text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal)::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000a1', 'aal1');
select lives_ok($$ select public.create_organization('MFA Org', 'mfa-org') $$, 'ana creates a workspace');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'mfa-org'), true);
insert into public.memberships (org_id, user_id, role)
  values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-0000000000a2', 'member');

select pg_temp.login('00000000-0000-0000-0000-0000000000a1', 'aal1');
select ok(public.has_role(current_setting('test.org')::uuid, 'admin'), 'admin without the setting at aal1');
reset role;

update public.organizations set require_mfa = true where id = current_setting('test.org')::uuid;

select pg_temp.login('00000000-0000-0000-0000-0000000000a1', 'aal1');
select ok(not public.has_role(current_setting('test.org')::uuid, 'admin'), 'required: aal1 loses admin powers');
select ok(public.has_role(current_setting('test.org')::uuid, 'member'), 'required: aal1 is still a member');
select ok(public.mfa_blocks_admin(current_setting('test.org')::uuid), 'the block is reported');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000a1', 'aal2');
select ok(public.has_role(current_setting('test.org')::uuid, 'owner'), 'required: aal2 keeps owner powers');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000a2', 'aal1');
select ok(public.has_role(current_setting('test.org')::uuid, 'member'), 'members are unaffected');
reset role;

select * from finish();
rollback;
