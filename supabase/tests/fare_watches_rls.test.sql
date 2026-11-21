-- Price watches on Fares cards (docs/FLIGHT-SEARCH-PLAN.md §9): a watch is its person's own. A
-- teammate and anyone outside the workspace see none, and people write none; the server does.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000047a1', 'fw-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000047a2', 'fw-a2@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000047a3', 'fw-a3@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000047b1', 'Trips', 'fare-watches-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000047b1', '10000000-0000-0000-0000-0000000047a1', 'owner'),
  ('10000000-0000-0000-0000-0000000047b1', '10000000-0000-0000-0000-0000000047a2', 'member');
insert into public.live_cards (id, org_id, user_id, card, tool, args, data) values
  ('10000000-0000-0000-0000-0000000047c1', '10000000-0000-0000-0000-0000000047b1',
   '10000000-0000-0000-0000-0000000047a1', 'Fares', 'fares', '{"from":"MNL","to":"TYO"}', '{"component":"Fares"}');
insert into public.fare_watches (id, org_id, user_id, live_card_id, route, below, currency, next_check_at, ends_at) values
  ('10000000-0000-0000-0000-0000000047d1', '10000000-0000-0000-0000-0000000047b1',
   '10000000-0000-0000-0000-0000000047a1', '10000000-0000-0000-0000-0000000047c1',
   'Manila → Tokyo', 9000, 'PHP', now() + interval '6 hours', now() + interval '30 days');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000047a1');
select is((select count(*)::int from public.fare_watches), 1, 'the person sees their watch');
select throws_ok($$ update public.fare_watches set below = 1 $$, '42501', null,
  'nobody changes a watch directly');
select throws_ok($$ insert into public.fare_watches (org_id, user_id, live_card_id, route, currency, next_check_at, ends_at)
  values ('10000000-0000-0000-0000-0000000047b1', '10000000-0000-0000-0000-0000000047a1',
          '10000000-0000-0000-0000-0000000047c1', 'x', 'PHP', now(), now()) $$,
  '42501', null, 'watches are started by the server');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000047a2');
select is((select count(*)::int from public.fare_watches), 0, 'a teammate doesn''t see it');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000047a3');
select is((select count(*)::int from public.fare_watches), 0, 'nobody outside the workspace sees it');
reset role;

select throws_ok($$ insert into public.fare_watches (org_id, user_id, live_card_id, route, currency, next_check_at, ends_at)
  values ('10000000-0000-0000-0000-0000000047b1', '10000000-0000-0000-0000-0000000047a1',
          '10000000-0000-0000-0000-0000000047c1', 'again', 'PHP', now(), now()) $$,
  '23505', null, 'one active watch per card and person');

select * from finish();
rollback;
