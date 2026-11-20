begin;
create extension if not exists pgtap;
select plan(2);
insert into public.organizations (id, name, slug)
values ('c2000000-0000-0000-0000-000000000099', 'Comp test', 'comp-grant-test');
insert into public.subscriptions (id, org_id, source, external_id, plan_code, status, created_at, current_period_end)
values ('c3000000-0000-0000-0000-000000000099', 'c2000000-0000-0000-0000-000000000099',
  'comp', 'comp:test', 'pro', 'active', now() - interval '1 month', now() + interval '2 months');
select is(public.grant_month('c3000000-0000-0000-0000-000000000099'),
  to_char(now() at time zone 'utc', 'YYYY-MM'), 'second month has its own grant label');
update public.subscriptions set created_at = now() where id = 'c3000000-0000-0000-0000-000000000099';
select is(public.grant_month('c3000000-0000-0000-0000-000000000099'),
  to_char(now() at time zone 'utc', 'YYYY-MM'), 'first month uses its start month');
select * from finish();
rollback;
