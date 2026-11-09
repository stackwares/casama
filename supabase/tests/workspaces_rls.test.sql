begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

-- Users: alice owns org A, bob owns org B, carol is a member of org A.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000c', 'carol@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid, email text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'email', email, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-00000000000a', 'alice@example.com');
select lives_ok($$ select public.create_organization('Org A', 'org-a') $$, 'alice creates org A');
reset role;
select pg_temp.login('00000000-0000-0000-0000-00000000000b', 'bob@example.com');
select lives_ok($$ select public.create_organization('Org B', 'org-b') $$, 'bob creates org B');
reset role;

-- alice invites carol
select pg_temp.login('00000000-0000-0000-0000-00000000000a', 'alice@example.com');
select lives_ok($$
  insert into public.invites (org_id, email, role, token_hash, invited_by)
  select id, 'carol@example.com', 'member', encode(extensions.digest('tok-carol', 'sha256'), 'hex'),
         '00000000-0000-0000-0000-00000000000a'
  from public.organizations where slug = 'org-a'
$$, 'owner can invite');
reset role;

-- bob cannot invite into org A, even with its id
select set_config('test.org_a', (select id::text from public.organizations where slug = 'org-a'), true);
select pg_temp.login('00000000-0000-0000-0000-00000000000b', 'bob@example.com');
select throws_ok($$
  insert into public.invites (org_id, email, token_hash, invited_by)
  values (current_setting('test.org_a')::uuid, 'x@example.com', 'h', '00000000-0000-0000-0000-00000000000b')
$$, '42501', null, 'non-member cannot invite into another org');
reset role;

-- carol accepts with wrong email -> fails; with right email -> joins
select pg_temp.login('00000000-0000-0000-0000-00000000000c', 'mallory@example.com');
select throws_ok($$ select public.accept_invite(encode(extensions.digest('tok-carol', 'sha256'), 'hex')) $$,
  '42501', 'invite_email_mismatch', 'invite email must match');
reset role;
select pg_temp.login('00000000-0000-0000-0000-00000000000c', 'carol@example.com');
select lives_ok($$ select public.accept_invite(encode(extensions.digest('tok-carol', 'sha256'), 'hex')) $$,
  'carol accepts invite');
select throws_ok($$ select public.accept_invite(encode(extensions.digest('tok-carol', 'sha256'), 'hex')) $$,
  'P0002', 'invite_invalid', 'invite is single use');
reset role;

-- Isolation: alice sees only org A
select pg_temp.login('00000000-0000-0000-0000-00000000000a', 'alice@example.com');
select results_eq($$ select slug from public.organizations order by slug $$, array['org-a'], 'alice sees only org A');
select is((select count(*)::int from public.memberships), 2, 'alice sees 2 memberships of org A');
select is((select count(*)::int from public.entitlements), 1, 'alice sees org A entitlement only');
select is((select count(*)::int from public.profiles), 2, 'alice sees her own and carol''s profile');
reset role;

-- bob sees only org B and none of org A's data
select pg_temp.login('00000000-0000-0000-0000-00000000000b', 'bob@example.com');
select results_eq($$ select slug from public.organizations $$, array['org-b'], 'bob sees only org B');
select is((select count(*)::int from public.memberships m join public.organizations o on o.id = m.org_id where o.slug = 'org-a'), 0, 'bob sees no org A memberships');
select is((select count(*)::int from public.invites), 0, 'bob sees no org A invites');
select is((select count(*)::int from public.profiles), 1, 'bob sees only his profile');
-- update on org A affects nothing
update public.organizations set name = 'pwned' where slug = 'org-a';
reset role;
select is((select name from public.organizations where slug = 'org-a'), 'Org A', 'bob cannot rename org A');

-- carol (member) cannot read invites or change roles
select pg_temp.login('00000000-0000-0000-0000-00000000000c', 'carol@example.com');
select is((select count(*)::int from public.invites), 0, 'members cannot read invites');
update public.memberships set role = 'owner' where user_id = '00000000-0000-0000-0000-00000000000c';
reset role;
select is((select role::text from public.memberships where user_id = '00000000-0000-0000-0000-00000000000c'), 'member', 'member cannot promote self');

select * from finish();
rollback;
