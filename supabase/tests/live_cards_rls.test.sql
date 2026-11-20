-- Live data cards (docs/RICH-CARDS-PLAN.md §4.4, §10): whoever can read a run's chat reads its
-- cards; a personal card (a parcel, a flight) only its person; nobody outside the workspace. The
-- shared cache, the daily counts and reports are the server's alone; people write none of them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000006a1', 'live-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000006a2', 'live-a2@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000006a3', 'live-a3@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000006b1', 'Live', 'live-cards-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000006b1', '10000000-0000-0000-0000-0000000006a1', 'owner'),
  ('10000000-0000-0000-0000-0000000006b1', '10000000-0000-0000-0000-0000000006a2', 'member');
insert into public.bots (id, org_id, created_by, name) values
  ('10000000-0000-0000-0000-0000000006d1', '10000000-0000-0000-0000-0000000006b1',
   '10000000-0000-0000-0000-0000000006a1', 'Sky');
insert into public.runs (id, org_id, bot_id, trigger, status, created_by) values
  ('10000000-0000-0000-0000-0000000006e1', '10000000-0000-0000-0000-0000000006b1',
   '10000000-0000-0000-0000-0000000006d1', 'chat', 'completed', '10000000-0000-0000-0000-0000000006a1');
-- As the worker writes them.
insert into public.live_cards (id, org_id, bot_id, run_id, user_id, personal, card, tool, args, data) values
  ('10000000-0000-0000-0000-0000000006c1', '10000000-0000-0000-0000-0000000006b1',
   '10000000-0000-0000-0000-0000000006d1', '10000000-0000-0000-0000-0000000006e1',
   '10000000-0000-0000-0000-0000000006a1', false, 'Weather', 'weather', '{"place":"Manila"}', '{"component":"Weather"}'),
  ('10000000-0000-0000-0000-0000000006c2', '10000000-0000-0000-0000-0000000006b1',
   '10000000-0000-0000-0000-0000000006d1', '10000000-0000-0000-0000-0000000006e1',
   '10000000-0000-0000-0000-0000000006a1', true, 'Parcel', 'parcel', '{"tracking":"X"}', '{"component":"Parcel"}');
insert into public.live_data_cache (provider, key, payload, expires_at) values ('met_norway', '14.6,121.0', '{}', now() + interval '1 hour');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000006a1');
select is((select count(*)::int from public.live_cards), 2, 'the person the run acted for sees both cards');
select throws_ok($$ insert into public.live_cards (org_id, card, tool, data)
  values ('10000000-0000-0000-0000-0000000006b1', 'Weather', 'weather', '{}') $$,
  '42501', null, 'cards are written by the server, not by people');
select throws_ok($$ update public.live_cards set args = '{"place":"elsewhere"}' $$, '42501', null,
  'nobody changes the call a card repeats');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000006a2');
select is((select count(*)::int from public.live_cards where personal), 0, 'a teammate doesn''t see a personal card');
select is((select count(*)::int from public.live_cards where not personal), 1, 'but sees the chat''s weather card');
reset role;

select pg_temp.login('10000000-0000-0000-0000-0000000006a3');
select is((select count(*)::int from public.live_cards), 0, 'nobody outside the workspace sees any');
select throws_ok($$ select count(*) from public.live_data_cache $$, '42501', null, 'the shared cache is the server''s');
select throws_ok($$ select count(*) from public.live_data_daily $$, '42501', null, 'so are the daily counts');
select throws_ok($$ select count(*) from public.live_card_reports $$, '42501', null, 'and the reports');
reset role;

select has_column('public', 'profiles', 'home_place', 'profiles keep a home city for cards');

select * from finish();
rollback;
