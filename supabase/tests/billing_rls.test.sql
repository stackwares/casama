begin;
create extension if not exists pgtap;
select plan(9);

insert into auth.users (id, email) values
  ('c1000000-0000-0000-0000-000000000001', 'bill-owner@example.com'),
  ('c1000000-0000-0000-0000-000000000002', 'bill-member@example.com'),
  ('c1000000-0000-0000-0000-000000000003', 'bill-outsider@example.com');
insert into public.organizations (id, name, slug) values ('c2000000-0000-0000-0000-000000000001', 'Billing', 'billing-rls');
insert into public.memberships (org_id, user_id, role) values
  ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'owner'),
  ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000002', 'member');
insert into public.subscriptions (org_id, source, external_id, plan_code, status)
  values ('c2000000-0000-0000-0000-000000000001', 'dodo', 'sub_rls_1', 'pro', 'active');
insert into public.billing_events (source, event_id, type, payload) values ('dodo', 'evt_rls_1', 'subscription.active', '{}');
insert into public.cloud_connect_keys (org_id, key_hash, key_hint, instance_name)
  values ('c2000000-0000-0000-0000-000000000001', 'rls-hash-1', 'kcc_…', 'home');

-- Credits apply once per reference and keep a running balance.
select is(public.credit_apply('c2000000-0000-0000-0000-000000000001', 5, 'grant', 'rls:1'), 5.0, 'first grant');
select is(public.credit_apply('c2000000-0000-0000-0000-000000000001', 5, 'grant', 'rls:1'), 5.0, 'same reference applies once');
select is(public.credit_apply('c2000000-0000-0000-0000-000000000001', -1.5, 'usage', 'rls:2'), 3.5, 'usage deducts');

-- Platform usage is billable by default; BYO-key tokens are not.
insert into public.usage_ledger (org_id, kind, quantity, cost_usd) values
  ('c2000000-0000-0000-0000-000000000001', 'computer_seconds', 60, 0.01),
  ('c2000000-0000-0000-0000-000000000001', 'tokens_in', 1000, 0.01);
select is((select array_agg(kind order by kind) from public.usage_ledger
  where org_id = 'c2000000-0000-0000-0000-000000000001' and billable), array['computer_seconds'], 'only platform usage is billable');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is((select count(*)::int from public.subscriptions where external_id = 'sub_rls_1'), 1, 'members see subscriptions');
select is((select count(*)::int from public.credit_ledger where reference like 'rls:%'), 2, 'members see credits');
select is((select count(*)::int from public.cloud_connect_keys where key_hash = 'rls-hash-1'), 0, 'members do not see Cloud Connect keys');
select is((select count(*)::int from public.billing_events where event_id = 'evt_rls_1'), 0, 'nobody reads webhook events');
select set_config('request.jwt.claims', '{"sub":"c1000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select is((select count(*)::int from public.subscriptions where external_id = 'sub_rls_1'), 0, 'outsiders see nothing');

select * from finish();
rollback;
