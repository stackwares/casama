begin;
create extension if not exists pgtap with schema extensions;
select plan(6);
select ok((select relrowsecurity from pg_class where oid='public.decision_log'::regclass),'decision log has RLS');
select ok(exists(select 1 from pg_policies where tablename='decision_log' and policyname='casama_worker_all'),'worker has a decision log policy');
insert into public.organizations (id, name, slug) values ('00000000-0000-0000-0000-00000000d454', 'Decide', 'decide-pgtap');
insert into public.decision_log (org_id, use, model, shadow, answers)
  values ('00000000-0000-0000-0000-00000000d454', 'scan_gate', 'typesafe/jev-1.14', true, '{"needs_attention":0.1}');
set local role authenticated;
select throws_ok($$select * from public.decision_log$$,'42501',null,'members cannot read the decision log');
select throws_ok($$insert into public.decision_log (org_id, use, model, shadow) values ('00000000-0000-0000-0000-00000000d454', 'scan_gate', 'x', true)$$,'42501',null,'members cannot write it');
reset role;
select throws_ok($$insert into public.decision_log (org_id, use, model, shadow) values ('00000000-0000-0000-0000-00000000d454', 'nope', 'x', true)$$,'23514',null,'only known uses');
delete from public.organizations where id = '00000000-0000-0000-0000-00000000d454';
select is((select count(*)::int from public.decision_log where org_id = '00000000-0000-0000-0000-00000000d454'),0,'rows go with the workspace');
select * from finish();
rollback;
