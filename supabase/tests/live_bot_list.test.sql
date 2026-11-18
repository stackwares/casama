-- D-225: bot changes broadcast on the workspace topic; only members may listen.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000000d1', 'live-a@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000000d2', 'live-b@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('20000000-0000-0000-0000-0000000000d1', 'Live A', 'live-a'),
  ('20000000-0000-0000-0000-0000000000d2', 'Live B', 'live-b');
insert into public.memberships (org_id, user_id, role) values
  ('20000000-0000-0000-0000-0000000000d1', '10000000-0000-0000-0000-0000000000d1', 'owner'),
  ('20000000-0000-0000-0000-0000000000d2', '10000000-0000-0000-0000-0000000000d2', 'owner');

create or replace function pg_temp.sent(p_org text) returns int language sql as $$
  select count(*)::int from realtime.messages where topic = 'org:' || p_org and event = 'bots_changed'
$$;

insert into public.bots (id, org_id, created_by, name, visibility) values
  ('30000000-0000-0000-0000-0000000000d1', '20000000-0000-0000-0000-0000000000d1', '10000000-0000-0000-0000-0000000000d1', 'Ada', 'private');
select is(pg_temp.sent('20000000-0000-0000-0000-0000000000d1'), 1, 'a new bot is announced on its workspace topic');
select is(pg_temp.sent('20000000-0000-0000-0000-0000000000d2'), 0, 'other workspaces hear nothing');
-- Realtime adds its own message id; the message carries no bot id or name.
select is(
  (select payload - 'id' from realtime.messages where topic = 'org:20000000-0000-0000-0000-0000000000d1' and event = 'bots_changed' limit 1),
  '{"kind": "bots"}'::jsonb,
  'the message names no bot');

update public.bots set name = 'Ada Lovelace' where id = '30000000-0000-0000-0000-0000000000d1';
update public.bots set name = 'Ada Lovelace' where id = '30000000-0000-0000-0000-0000000000d1';
select is(pg_temp.sent('20000000-0000-0000-0000-0000000000d1'), 2, 'a rename is announced; a write that changes nothing is not');

delete from public.bots where id = '30000000-0000-0000-0000-0000000000d1';
select is(pg_temp.sent('20000000-0000-0000-0000-0000000000d1'), 3, 'a deleted bot is announced');

set local role authenticated;
set local request.jwt.claims = '{"sub": "10000000-0000-0000-0000-0000000000d1", "role": "authenticated"}';
select ok(public.realtime_topic_allowed('org:20000000-0000-0000-0000-0000000000d1'), 'a member may listen to their workspace');
select ok(not public.realtime_topic_allowed('org:20000000-0000-0000-0000-0000000000d2'), 'not to another workspace');
select ok(not public.realtime_topic_allowed('org:not-a-uuid'), 'a malformed topic is denied');
reset role;

select * from finish();
rollback;
