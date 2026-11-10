begin;
create extension if not exists pgtap with schema extensions;
select plan(7);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000c1', 'own@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000c2', 'new@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000c3', 'late@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000c1');
select public.create_organization('Home', 'home');
select lives_ok($$ update public.organizations set icon = 'house', color = '#22aa66' where slug = 'home' $$, 'admins restyle their space');
select lives_ok($$
  insert into public.invite_links (org_id, role, token_hash, token_hint, max_uses, created_by)
  select id, 'member', 'hash-1', 'kjoin_ab', 1, '00000000-0000-0000-0000-0000000000c1' from public.organizations where slug = 'home'
$$, 'admins create invite links');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000c2');
select is((select count(*)::int from public.invite_links), 0, 'outsiders do not see links');
select lives_ok($$ select public.accept_invite_link('hash-1') $$, 'a signed-in person joins with the link');
select ok(exists(select 1 from public.memberships m join public.organizations o on o.id = m.org_id
                 where o.slug = 'home' and m.user_id = '00000000-0000-0000-0000-0000000000c2' and m.role = 'member'),
          'they joined with the link''s role');
update public.organizations set name = 'Mine' where slug = 'home';
select is((select name from public.organizations where slug = 'home'), 'Home', 'members cannot rename the space');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000c3');
select throws_ok($$ select public.accept_invite_link('hash-1') $$, 'P0002', null, 'a used-up link stops working');
reset role;
select * from finish();
rollback;
