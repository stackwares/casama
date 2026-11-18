begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000e1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000e2', 'ben@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

-- Ana has a personal space and a team space she shares with Ben.
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
select public.create_organization('Ana solo', 'ana-solo');
select public.create_organization('Team', 'ana-team');
insert into public.user_about (user_id, about, reply_style) values
  ('00000000-0000-0000-0000-0000000000e1', 'Runs a bakery', 'Short answers');
insert into public.user_facts (user_id, content) values ('00000000-0000-0000-0000-0000000000e1', 'Has two kids');
update public.profiles set preferred_name = 'Ana', pronouns = 'she/her' where user_id = '00000000-0000-0000-0000-0000000000e1';
reset role;
insert into public.memberships (org_id, user_id, role)
  select id, '00000000-0000-0000-0000-0000000000e2', 'member' from public.organizations where slug = 'ana-team';
select set_config('test.solo', (select id::text from public.organizations where slug = 'ana-solo'), true);

select ok(public.profile_shared_in('00000000-0000-0000-0000-0000000000e1', (select id from public.organizations where slug = 'ana-solo')),
  'a space where the person is the only member uses what they shared');
select ok(not public.profile_shared_in('00000000-0000-0000-0000-0000000000e1', (select id from public.organizations where slug = 'ana-team')),
  'a team space does not by default');
select ok(not public.profile_shared_in('00000000-0000-0000-0000-0000000000e2', (select id from public.organizations where slug = 'ana-solo')),
  'nor a space the person is not in');

select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
insert into public.profile_spaces (user_id, org_id, share_about)
  select '00000000-0000-0000-0000-0000000000e1', id, true from public.organizations where slug = 'ana-team';
reset role;
select ok(public.profile_shared_in('00000000-0000-0000-0000-0000000000e1', (select id from public.organizations where slug = 'ana-team')),
  'turning it on for a team space');

select pg_temp.login('00000000-0000-0000-0000-0000000000e2');
select is((select preferred_name from public.profiles where user_id = '00000000-0000-0000-0000-0000000000e1'), 'Ana',
  'teammates see what to call someone');
select is((select count(*)::int from public.user_about), 0, 'but not their About me');
select is((select count(*)::int from public.user_facts), 0, 'nor their learned facts');
select is((select count(*)::int from public.profile_spaces), 0, 'nor their space choices');
select throws_ok($$ insert into public.user_facts (user_id, content) values ('00000000-0000-0000-0000-0000000000e1', 'planted') $$,
  '42501', null, 'nobody writes facts into someone else''s profile');
select throws_ok($$ insert into public.profile_spaces (user_id, org_id, share_about)
  values ('00000000-0000-0000-0000-0000000000e2', current_setting('test.solo')::uuid, true) $$,
  '42501', null, 'nor turns it on for a space they are not in');
reset role;

-- At most 200 facts: the oldest unpinned ones go first.
update public.user_facts set pinned = true where user_id = '00000000-0000-0000-0000-0000000000e1';
insert into public.user_facts (user_id, content, updated_at)
  select '00000000-0000-0000-0000-0000000000e1', 'fact ' || g, now() - make_interval(secs => 1000 - g) from generate_series(1, 205) g;
select is((select count(*)::int from public.user_facts where user_id = '00000000-0000-0000-0000-0000000000e1' and not pinned), 200,
  'unpinned facts are capped at 200');
select ok(exists (select 1 from public.user_facts where content = 'Has two kids'), 'pinned facts are kept');
select * from finish();
rollback;
