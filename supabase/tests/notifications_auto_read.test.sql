begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (id, email, aud, role) values
  ('a1000000-0000-0000-0000-00000000000a', 'reader@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values ('b1000000-0000-0000-0000-00000000000a', 'Read Org', 'read-org');
insert into public.memberships (org_id, user_id, role) values
  ('b1000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-00000000000a', 'owner');
insert into public.bots (id, org_id, created_by, name) values
  ('c1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-00000000000a', 'Reader bot');
insert into public.runs (id, org_id, bot_id) values
  ('d1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-00000000000a');
insert into public.approvals (id, org_id, bot_id, run_id, call_id, tool_name, risk) values
  ('e1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-00000000000a',
   'd1000000-0000-0000-0000-00000000000a', 'c1', 'shell.exec', 'high'),
  ('e1000000-0000-0000-0000-00000000000b', 'b1000000-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-00000000000a',
   'd1000000-0000-0000-0000-00000000000a', 'c2', 'http.request', 'medium');
insert into public.notifications (user_id, org_id, kind, payload) values
  ('a1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'approval_request', '{"approval_id": "e1000000-0000-0000-0000-00000000000a"}'),
  ('a1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'approval_request', '{"approval_id": "e1000000-0000-0000-0000-00000000000b"}'),
  ('a1000000-0000-0000-0000-00000000000a', 'b1000000-0000-0000-0000-00000000000a', 'routine_result', '{"approval_id": "e1000000-0000-0000-0000-00000000000a"}');

update public.approvals set status = 'approved' where id = 'e1000000-0000-0000-0000-00000000000a';
select isnt((select read_at from public.notifications where kind = 'approval_request' and payload ->> 'approval_id' = 'e1000000-0000-0000-0000-00000000000a'), null,
  'answering an approval marks its notification read');
select is((select read_at from public.notifications where payload ->> 'approval_id' = 'e1000000-0000-0000-0000-00000000000b'), null,
  'other approvals stay unread');
select is((select read_at from public.notifications where kind = 'routine_result'), null, 'only that kind of notification');
select throws_ok($$ select public.read_request_notifications('approval_request', 'approval_id', gen_random_uuid()) $$,
  '42501', null, 'the helper is not callable from outside') from (select set_config('role', 'authenticated', true)) s;
reset role;
select * from finish();
rollback;
