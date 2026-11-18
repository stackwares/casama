begin;
create extension if not exists pgtap with schema extensions;
select plan(10);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000007a1', 'agents-admin@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000007a2', 'agents-member@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000007a1');
select public.create_organization('Agents Org', 'agents-org');
reset role;
insert into public.memberships (org_id, user_id, role)
  select id, '00000000-0000-0000-0000-0000000007a2', 'member' from public.organizations where slug = 'agents-org';
insert into public.local_devices (id, org_id, user_id, name, platform, token_hash)
  select '00000000-0000-0000-0000-0000000007d1', id, '00000000-0000-0000-0000-0000000007a2', 'Mac', 'macos', 'own-agents-hash'
  from public.organizations where slug = 'agents-org';

select is((select allowed_coding_agents from public.local_devices where id = '00000000-0000-0000-0000-0000000007d1'),
  '{}'::text[], 'a new computer has allowed no extra coding agents');

-- The device's owner adds an agent on their own computer.
select pg_temp.login('00000000-0000-0000-0000-0000000007a2');
select lives_ok($$
  insert into public.own_coding_agents (org_id, user_id, device_id, key, label, bin, command, result)
  select org_id, user_id, id, 'aider', 'Aider', 'aider', 'aider --message {task} --yes', 'tail'
  from public.local_devices where id = '00000000-0000-0000-0000-0000000007d1'
$$, 'the owner adds an agent on their computer');
select is((select count(*)::int from public.own_coding_agents), 1, 'and sees it');
reset role;

-- An admin can't see it, add one to that computer or change it.
select pg_temp.login('00000000-0000-0000-0000-0000000007a1');
select is((select count(*)::int from public.own_coding_agents), 0, 'admins do not see members'' own agents');
select throws_ok($$
  insert into public.own_coding_agents (org_id, user_id, device_id, key, label, bin, command, result)
  select id, '00000000-0000-0000-0000-0000000007a2', '00000000-0000-0000-0000-0000000007d1', 'evil', 'Evil', 'sh', 'sh {task}', 'tail'
  from public.organizations where slug = 'agents-org'
$$, '42501', null, 'admins cannot put an agent on a member''s computer');
select throws_ok($$
  insert into public.own_coding_agents (org_id, user_id, device_id, key, label, bin, command, result)
  select id, '00000000-0000-0000-0000-0000000007a1', '00000000-0000-0000-0000-0000000007d1', 'evil', 'Evil', 'sh', 'sh {task}', 'tail'
  from public.organizations where slug = 'agents-org'
$$, '42501', null, 'not even as their own row');
update public.own_coding_agents set command = 'sh -c {task}';
delete from public.own_coding_agents;
reset role;
select is((select command from public.own_coding_agents where key = 'aider'), 'aider --message {task} --yes',
  'admins cannot change or delete it');

select throws_ok($$
  insert into public.own_coding_agents (org_id, user_id, device_id, key, label, bin, command, result)
  select org_id, user_id, id, 'bad', 'Bad', 'bad', 'bad {task}', 'whatever'
  from public.local_devices where id = '00000000-0000-0000-0000-0000000007d1'
$$, '23514', null, 'the result is one of the named behaviours');

-- The worker reads them for coding.delegate.
set local role casama_worker;
select is((select count(*)::int from public.own_coding_agents), 1, 'the worker reads own agents');
reset role;

-- Unpairing the computer removes its agents.
delete from public.local_devices where id = '00000000-0000-0000-0000-0000000007d1';
select is((select count(*)::int from public.own_coding_agents), 0, 'they go with the computer');
select * from finish();
rollback;
