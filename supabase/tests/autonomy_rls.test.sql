begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email, aud, role) values
  ('a0000000-0000-0000-0000-00000000000a', 'p4a@example.com', 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-00000000000b', 'p4b@example.com', 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-00000000000c', 'p4c@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('b0000000-0000-0000-0000-00000000000a', 'P4A', 'p4-a'),
  ('b0000000-0000-0000-0000-00000000000b', 'P4B', 'p4-b');
insert into public.memberships (org_id, user_id, role) values
  ('b0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000000a', 'owner'),
  ('b0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000000c', 'member'),
  ('b0000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-00000000000b', 'owner');
insert into public.bots (id, org_id, created_by, name) values
  ('c0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000000a', 'A bot'),
  ('c0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-00000000000b', 'B bot');
insert into public.runs (id, org_id, bot_id) values
  ('d0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'c0000000-0000-0000-0000-00000000000a');
insert into public.approvals (id, org_id, bot_id, run_id, call_id, tool_name, risk) values
  ('e0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'c0000000-0000-0000-0000-00000000000a',
   'd0000000-0000-0000-0000-00000000000a', 'c1', 'shell.exec', 'high'),
  ('e0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000a', 'c0000000-0000-0000-0000-00000000000a',
   'd0000000-0000-0000-0000-00000000000a', 'c2', 'http.request', 'medium');
insert into public.secrets (org_id, name, vault_secret_id, allowed_hosts) values
  ('b0000000-0000-0000-0000-00000000000a', 'GITHUB_TOKEN', vault.create_secret('ghp_secret_value_123'), '{api.github.com}');
insert into public.integrations (org_id, kind, name) values
  ('b0000000-0000-0000-0000-00000000000a', 'mcp', 'tools'),
  ('b0000000-0000-0000-0000-00000000000b', 'mcp', 'other');
insert into public.routines (org_id, bot_id, name, instructions_md, schedule_cron, timezone) values
  ('b0000000-0000-0000-0000-00000000000a', 'c0000000-0000-0000-0000-00000000000a', 'Morning', 'Summarize news', '0 8 * * *', 'America/Chicago');
insert into public.notifications (user_id, org_id, kind, payload) values
  ('a0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'approval', '{"title":"Approve?"}'),
  ('a0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'routine', '{"title":"Done"}');

select is((select count(*)::int from realtime.messages where topic = 'user:a0000000-0000-0000-0000-00000000000a'), 1, 'notifications broadcast to the user topic');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

-- Member of org A
select pg_temp.login('a0000000-0000-0000-0000-00000000000c');
select is((select count(*)::int from public.approvals), 2, 'member sees the org''s approvals');
select is((select count(*)::int from public.secrets), 1, 'member sees secret metadata');
select throws_ok($$ select * from vault.decrypted_secrets $$, '42501', null, 'secret values stay in the vault');
select is((select count(*)::int from public.integrations), 1, 'member sees only org A integrations');
select is((select count(*)::int from public.routines), 1, 'member sees the bot''s routines');
select is((select count(*)::int from public.notifications), 0, 'notifications are personal');
select is((select status from public.decide_approval('e0000000-0000-0000-0000-00000000000a', 'approved', true)), 'approved', 'member approves with always-allow');
select is((select count(*)::int from public.tool_grants where tool_name = 'shell.exec'), 1, 'always-allow creates a grant');
select throws_ok($$ select public.decide_approval('e0000000-0000-0000-0000-00000000000a', 'denied') $$, '55000', null, 'an approval is decided once');
select lives_ok($$ insert into public.devices (user_id, platform, fcm_token) values ('a0000000-0000-0000-0000-00000000000c', 'ios', 'token-c') $$, 'users register their own devices');
select throws_ok($$ insert into public.devices (user_id, platform, fcm_token) values ('a0000000-0000-0000-0000-00000000000a', 'ios', 'token-x') $$, '42501', null, 'not for someone else');
reset role;

-- Owner of org B
select pg_temp.login('a0000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.approvals), 0, 'other orgs see no approvals');
select throws_ok($$ select public.decide_approval('e0000000-0000-0000-0000-00000000000b', 'approved') $$, 'P0002', null, 'other orgs cannot decide');
select is((select count(*)::int from public.secrets), 0, 'other orgs see no secrets');
select is((select count(*)::int from public.notifications), 1, 'owner sees own notification');
reset role;

select * from finish();
rollback;
