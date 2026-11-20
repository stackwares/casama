begin;
create extension if not exists pgtap;
select plan(8);

insert into auth.users (id, email) values
  ('c1000000-0000-0000-0000-0000000000c1', 'comp-owner@example.com');
insert into public.organizations (id, name, slug) values ('c2000000-0000-0000-0000-0000000000c1', 'Comp RLS', 'comp-rls');
insert into public.memberships (org_id, user_id, role) values
  ('c2000000-0000-0000-0000-0000000000c1', 'c1000000-0000-0000-0000-0000000000c1', 'owner');
insert into public.comp_codes (id, code_hash, code_hint, plan_code, months, created_by)
  values ('c4000000-0000-0000-0000-0000000000c1', 'hash-c1', '…AAAA', 'pro', 2, 'c1000000-0000-0000-0000-0000000000c1');
insert into public.comps (org_id, user_id, plan_code, months, ends_at)
  values ('c2000000-0000-0000-0000-0000000000c1', 'c1000000-0000-0000-0000-0000000000c1', 'pro', 1, now() + interval '1 month');
insert into public.comp_events (action) values ('test');

select throws_ok($$insert into public.comps (org_id, plan_code, months, ends_at)
  values ('c2000000-0000-0000-0000-0000000000c1', 'plus', 1, now() + interval '1 month')$$,
  '23505', null, 'one running comp per workspace');
select throws_ok($$update public.comp_events set action = 'x'$$, 'P0001', 'comp_events is append only', 'the log is append only');
select is(public.worker_user_by_email(' COMP-OWNER@example.com '), 'c1000000-0000-0000-0000-0000000000c1'::uuid, 'finds a person by email');
select ok(exists (select 1 from pg_constraint where conname = 'subscriptions_source_check'
  and pg_get_constraintdef(oid) like '%comp%'), 'subscriptions accept the comp source');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"c1000000-0000-0000-0000-0000000000c1","role":"authenticated"}', true);
select throws_ok($$select count(*) from public.comps$$, '42501', null, 'owners never read comps directly');
select throws_ok($$select count(*) from public.comp_codes$$, '42501', null, 'nobody reads gift codes');
select throws_ok($$select count(*) from public.comp_events$$, '42501', null, 'nobody reads the log');
select throws_ok($$select public.worker_user_by_email('comp-owner@example.com')$$, '42501', null, 'the email lookup is not for clients');

select * from finish();
rollback;
