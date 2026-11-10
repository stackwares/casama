-- Audit 2026-11: row-level security on sensitive tables that had no pgTAP coverage, and the new
-- private-conversation and teach-replay rules.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000a0d1', 'own-audit@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000a0d2', 'mem-audit@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000a0d3', 'out-audit@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-00000000a0d1');
select public.create_organization('Audit Org', 'audit-org');
reset role;
select set_config('test.org', (select id::text from public.organizations where slug = 'audit-org'), true);
insert into public.memberships (org_id, user_id, role) values (current_setting('test.org')::uuid, '00000000-0000-0000-0000-00000000a0d2', 'member');
insert into public.bots (org_id, name, created_by) values (current_setting('test.org')::uuid, 'Shared', '00000000-0000-0000-0000-00000000a0d1');
select set_config('test.bot', (select id::text from public.bots where name = 'Shared' and org_id = current_setting('test.org')::uuid), true);

-- Secrets and payments: admins or owners only.
insert into public.password_managers (org_id, provider, name, url, user_id) values
  (current_setting('test.org')::uuid, 'bitwarden', 'Team vault', 'https://vault.example.com', null),
  (current_setting('test.org')::uuid, 'bitwarden', 'Owner personal', 'https://vault.example.com', '00000000-0000-0000-0000-00000000a0d1');
insert into public.org_secret_stores (org_id, site_url, project_id, client_id, vault_secret_id) values (current_setting('test.org')::uuid, 'https://infisical.example.com', 'p1', 'c1', gen_random_uuid());
insert into public.org_payments (org_id, vault_secret_id, webhook_secret_id, cardholder_id) values (current_setting('test.org')::uuid, gen_random_uuid(), gen_random_uuid(), 'ich_1');
insert into public.mcp_tokens (token_hash, kind, user_id, org_id) values ('audit-hash-1', 'api_key', '00000000-0000-0000-0000-00000000a0d1', current_setting('test.org')::uuid);

-- Conversations: one ordinary, one private (personal device data reached it).
insert into public.conversations (org_id, bot_id, title, created_by, private) values
  (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'Team chat', '00000000-0000-0000-0000-00000000a0d1', false),
  (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'My calendar', '00000000-0000-0000-0000-00000000a0d1', true);
insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
  select org_id, bot_id, id, created_by, 'chat' from public.conversations where title = 'My calendar' and bot_id = current_setting('test.bot')::uuid;
insert into public.run_events (run_id, seq, org_id, bot_id, type, payload)
  select r.id, 1, r.org_id, r.bot_id, 'message.delta', '{"text":"Dentist at 9"}' from public.runs r join public.conversations c on c.id = r.conversation_id where c.title = 'My calendar';
-- Replays: one taught by the owner, one the bot saved.
insert into public.replays (org_id, bot_id, name, steps, source, created_by) values
  (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'my-expense', '[]', 'teach', '00000000-0000-0000-0000-00000000a0d1'),
  (current_setting('test.org')::uuid, current_setting('test.bot')::uuid, 'shared-flow', '[]', 'bot', null);

select pg_temp.login('00000000-0000-0000-0000-00000000a0d2');
select is((select count(*)::int from public.password_managers), 1, 'members see workspace password managers, not someone else''s personal one');
select is((select count(*)::int from public.org_secret_stores), 0, 'members don''t see the secret store settings');
select is((select count(*)::int from public.org_payments), 0, 'members don''t see payment settings');
select is((select count(*)::int from public.mcp_tokens), 0, 'members don''t see API keys');
select is((select count(*)::int from public.conversations where bot_id = current_setting('test.bot')::uuid), 1, 'a teammate sees the team chat but not the private one');
select is((select count(*)::int from public.run_events where bot_id = current_setting('test.bot')::uuid), 0, 'or its run events');
select is((select count(*)::int from public.replays where bot_id = current_setting('test.bot')::uuid), 2, 'replays are shared with the bot''s users (saving one from a recording is the owner''s choice to share it)');
select is((select count(*)::int from public.mcp_clients), 0, 'server-only: MCP clients');
select is((select count(*)::int from public.account_deletions), 0, 'server-only: account deletions');
select throws_ok($$ insert into public.org_payments (org_id, vault_secret_id, webhook_secret_id, cardholder_id) values (current_setting('test.org')::uuid, gen_random_uuid(), gen_random_uuid(), 'x') $$, '42501', null, 'members can''t write payment settings');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000a0d1');
select is((select count(*)::int from public.password_managers), 2, 'the owner sees both');
select is((select count(*)::int from public.org_payments), 1, 'owners see payment settings');
select is((select count(*)::int from public.conversations where bot_id = current_setting('test.bot')::uuid), 2, 'the starter sees their private conversation');
select is((select count(*)::int from public.run_events where bot_id = current_setting('test.bot')::uuid), 1, 'and its run events');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000a0d3');
select is((select count(*)::int from public.password_managers), 0, 'outsiders see nothing');
select is((select count(*)::int from public.conversations), 0, 'outsiders see no conversations');
reset role;
select * from finish();
rollback;
