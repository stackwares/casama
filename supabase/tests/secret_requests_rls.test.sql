begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000e1', 'keys@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000e2', 'keys-outsider@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
select public.create_organization('Keys Org', 'keys-org');
insert into public.bots (org_id, name, created_by, visibility)
  select id, 'Biller', '00000000-0000-0000-0000-0000000000e1', 'team' from public.organizations where slug = 'keys-org';
reset role;
insert into public.runs (org_id, bot_id, trigger, created_by)
  select org_id, id, 'chat', '00000000-0000-0000-0000-0000000000e1' from public.bots where name = 'Biller';
insert into public.secret_requests (org_id, bot_id, run_id, name, service, allowed_hosts)
  select r.org_id, r.bot_id, r.id, 'STRIPE_API_KEY', 'Stripe', array['api.stripe.com'] from public.runs r
  join public.bots b on b.id = r.bot_id where b.name = 'Biller';
select pg_temp.login('00000000-0000-0000-0000-0000000000e1');
select is((select count(*)::int from public.secret_requests), 1, 'members see their bot''s requests');
update public.secret_requests set status = 'fulfilled';
select is((select status from public.secret_requests), 'pending', 'but answer only through the API');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000e2');
select is((select count(*)::int from public.secret_requests), 0, 'outsiders see none');
reset role;
select throws_ok($$ insert into public.secret_requests (org_id, bot_id, run_id, name, service, allowed_hosts)
  select org_id, bot_id, run_id, 'bad name', 'X', array['x.com'] from public.secret_requests limit 1 $$, '23514', null, 'names are UPPER_SNAKE_CASE');
select * from finish();
rollback;
