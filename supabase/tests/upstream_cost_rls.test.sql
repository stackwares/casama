begin;
create extension if not exists pgtap;
select plan(5);

-- What the server paid for usage is for the platform admin only (D-395): members read their
-- workspace's usage rows, but not that column.
insert into auth.users (id, email) values
  ('c7000000-0000-0000-0000-000000000001', 'upstream-member@example.com');
insert into public.organizations (id, name, slug) values ('c7100000-0000-0000-0000-000000000001', 'Upstream', 'upstream-rls');
insert into public.memberships (org_id, user_id, role) values
  ('c7100000-0000-0000-0000-000000000001', 'c7000000-0000-0000-0000-000000000001', 'owner');
insert into public.usage_ledger (org_id, kind, quantity, cost_usd, upstream_cost_usd, billable) values
  ('c7100000-0000-0000-0000-000000000001', 'tokens_in', 1000, 0.014, 0.01, true);

select ok(has_column_privilege('authenticated', 'public.usage_ledger', 'cost_usd', 'select'), 'members may read the price');
select ok(not has_column_privilege('authenticated', 'public.usage_ledger', 'upstream_cost_usd', 'select'), 'members may not read the cost');
select ok(not has_table_privilege('anon', 'public.usage_ledger', 'select'), 'signed-out callers read nothing');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"c7000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is((select cost_usd from public.usage_ledger where org_id = 'c7100000-0000-0000-0000-000000000001'), 0.014::numeric(12, 6), 'a member reads the row''s price');
select throws_ok(
  $$select upstream_cost_usd from public.usage_ledger where org_id = 'c7100000-0000-0000-0000-000000000001'$$,
  '42501', null, 'selecting the cost is refused');

select * from finish();
rollback;
