-- The island's live tokens (D-324, Phase 4): a person registers tokens only for themselves and only
-- for runs they can see, and sees only their own.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000001a1', 'live-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000001a2', 'live-a2@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000001b1', 'live-b1@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-0000000001aa', 'Live A', 'live-a'),
  ('20000000-0000-0000-0000-0000000001bb', 'Live B', 'live-b');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1', 'owner'),
  ('20000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a2', 'member'),
  ('20000000-0000-0000-0000-0000000001bb', '10000000-0000-0000-0000-0000000001b1', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-0000000001aa', '20000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1', 'Team bot', 'team'),
  ('30000000-0000-0000-0000-0000000001a2', '20000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1', 'Private bot', 'private');
insert into public.runs (id, org_id, bot_id, created_by) values
  ('50000000-0000-0000-0000-0000000001aa', '20000000-0000-0000-0000-0000000001aa', '30000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1'),
  ('50000000-0000-0000-0000-0000000001a2', '20000000-0000-0000-0000-0000000001aa', '30000000-0000-0000-0000-0000000001a2', '10000000-0000-0000-0000-0000000001a1');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000001a1');
select lives_ok($$ insert into public.run_live_tokens (run_id, user_id, platform, token)
  values ('50000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1', 'ios', 'abcdef0123456789') $$,
  'a person registers a live token for a run they can see');
select lives_ok($$ insert into public.run_live_tokens (run_id, user_id, platform, token)
  values ('50000000-0000-0000-0000-0000000001a2', '10000000-0000-0000-0000-0000000001a1', 'android', 'fcm-token-0001') $$,
  'including their own private bot''s run');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000001a2');
select is((select count(*)::int from public.run_live_tokens), 0, 'a teammate doesn''t see someone else''s tokens');
select throws_ok($$ insert into public.run_live_tokens (run_id, user_id, platform, token)
  values ('50000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001a1', 'ios', 'zzzzzzzzzzzzzzzz') $$,
  '42501', null, 'nobody registers a token for someone else');
select throws_ok($$ insert into public.run_live_tokens (run_id, user_id, platform, token)
  values ('50000000-0000-0000-0000-0000000001a2', '10000000-0000-0000-0000-0000000001a2', 'ios', 'yyyyyyyyyyyyyyyy') $$,
  '42501', null, 'or for a run on a private bot they can''t see');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000001b1');
select throws_ok($$ insert into public.run_live_tokens (run_id, user_id, platform, token)
  values ('50000000-0000-0000-0000-0000000001aa', '10000000-0000-0000-0000-0000000001b1', 'ios', 'xxxxxxxxxxxxxxxx') $$,
  '42501', null, 'or for another workspace''s run');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000001a1');
select is((select count(*)::int from public.run_live_tokens), 2, 'the person sees their own tokens');
select lives_ok($$ delete from public.run_live_tokens where token = 'fcm-token-0001' $$, 'and drops one');
reset role;

select * from finish();
rollback;
