begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-00000000000a', 'a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-00000000000b', 'a2@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-00000000000c', 'b1@example.com', 'authenticated', 'authenticated');

-- org A: a1 owner, a2 member. org B: b1 owner. Set up as superuser.
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-00000000000a', 'A', 'rls-a'),
  ('20000000-0000-0000-0000-00000000000b', 'B', 'rls-b');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000000a', 'owner'),
  ('20000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000000b', 'member'),
  ('20000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-00000000000c', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000000a', 'Team bot', 'team'),
  ('30000000-0000-0000-0000-0000000000a2', '20000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000000a', 'Private bot', 'private'),
  ('30000000-0000-0000-0000-00000000000b', '20000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-00000000000c', 'B bot', 'team');
insert into public.conversations (id, org_id, bot_id) values
  ('40000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000000a'),
  ('40000000-0000-0000-0000-00000000000b', '20000000-0000-0000-0000-00000000000b', '30000000-0000-0000-0000-00000000000b');
insert into public.runs (id, org_id, bot_id, conversation_id) values
  ('50000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000000a', '40000000-0000-0000-0000-00000000000a'),
  ('50000000-0000-0000-0000-00000000000b', '20000000-0000-0000-0000-00000000000b', '30000000-0000-0000-0000-00000000000b', '40000000-0000-0000-0000-00000000000b');
select public.append_run_event('50000000-0000-0000-0000-00000000000a', 'run.started', '{}');
select public.append_run_event('50000000-0000-0000-0000-00000000000a', 'run.completed', '{}');
select public.append_run_event('50000000-0000-0000-0000-00000000000b', 'run.started', '{}');
insert into public.memories (org_id, bot_id, kind, content) values
  ('20000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000000a', 'fact', 'The user likes teal'),
  ('20000000-0000-0000-0000-00000000000b', '30000000-0000-0000-0000-00000000000b', 'fact', 'Org B secret plan');
insert into public.model_credentials (org_id, provider, label, vault_secret_id) values
  ('20000000-0000-0000-0000-00000000000a', 'openrouter', 'Main', vault.create_secret('sk-test-123'));

select is((select array_agg(seq order by seq) from public.run_events where run_id = '50000000-0000-0000-0000-00000000000a'), array[1, 2], 'seq is gap-free per run');
select is((select count(*)::int from realtime.messages where topic = 'run:50000000-0000-0000-0000-00000000000a'), 2, 'events broadcast to run topic');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

-- a2 (member of A, not creator of the private bot)
select pg_temp.login('10000000-0000-0000-0000-00000000000b');
select results_eq($$ select name from public.bots order by name $$, array['Team bot'], 'member sees team bot, not others'' private bots');
select is((select count(*)::int from public.conversations), 1, 'member sees only org A conversations');
select is((select count(*)::int from public.runs), 1, 'member sees only org A runs');
select is((select count(*)::int from public.run_events), 2, 'member sees only org A run events');
select is((select count(*)::int from public.memories), 1, 'member sees only org A memories');
select is((select count(*)::int from public.model_credentials), 1, 'member sees credential metadata');
select throws_ok($$ select * from vault.decrypted_secrets $$, '42501', null, 'members cannot read the vault');
select throws_ok($$ select public.append_run_event('50000000-0000-0000-0000-00000000000a', 'run.started', '{}') $$, '42501', null, 'users cannot append run events');
update public.run_events set type = 'tampered';
delete from public.run_events;
select lives_ok($$ insert into public.messages (org_id, conversation_id, role, author_user_id, content)
  values ('20000000-0000-0000-0000-00000000000a', '40000000-0000-0000-0000-00000000000a', 'user', '10000000-0000-0000-0000-00000000000b', '[]') $$, 'member writes own user message');
select throws_ok($$ insert into public.messages (org_id, conversation_id, role, content)
  values ('20000000-0000-0000-0000-00000000000a', '40000000-0000-0000-0000-00000000000a', 'assistant', '[]') $$, '42501', null, 'users cannot write assistant messages');
select throws_ok($$ insert into public.messages (org_id, conversation_id, role, author_user_id, content)
  values ('20000000-0000-0000-0000-00000000000b', '40000000-0000-0000-0000-00000000000b', 'user', '10000000-0000-0000-0000-00000000000b', '[]') $$, '42501', null, 'cannot write into another org''s conversation');
select throws_ok($$ insert into public.bots (org_id, created_by, name) values ('20000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-00000000000b', 'x') $$,
  '42501', null, 'cannot create bots in another org');
select ok(public.realtime_topic_allowed('run:50000000-0000-0000-0000-00000000000a'), 'may subscribe to own org run topic');
select ok(not public.realtime_topic_allowed('run:50000000-0000-0000-0000-00000000000b'), 'may not subscribe to other org run topic');
select ok(not public.realtime_topic_allowed('bot:30000000-0000-0000-0000-0000000000a2'), 'may not subscribe to others'' private bot');
select ok(not public.realtime_topic_allowed('run:not-a-uuid'), 'malformed topic is denied');
select throws_ok($$ select public.request_run_cancel('50000000-0000-0000-0000-00000000000b') $$, 'P0002', null, 'cannot cancel another org''s run');
select lives_ok($$ select public.request_run_cancel('50000000-0000-0000-0000-00000000000a') $$, 'can cancel own org run');
reset role;
select is((select count(*)::int from public.run_events where type = 'tampered'), 0, 'run events cannot be updated');
select is((select count(*)::int from public.run_events where run_id in ('50000000-0000-0000-0000-00000000000a', '50000000-0000-0000-0000-00000000000b')), 3, 'run events cannot be deleted');

select * from finish();
rollback;
