begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000d2', 'eve@example.com', 'authenticated', 'authenticated');

create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select public.create_organization('Call Org', 'call-org');
select lives_ok($$ insert into public.voip_tokens (user_id, token) values ('00000000-0000-0000-0000-0000000000d1', 'abcdef0123456789') $$, 'people register their own VoIP token');
reset role;
insert into public.bots (org_id, name, created_by) select id, 'Max', '00000000-0000-0000-0000-0000000000d1' from public.organizations where slug = 'call-org';
insert into public.voice_calls (org_id, bot_id, user_id, reason)
  select b.org_id, b.id, '00000000-0000-0000-0000-0000000000d1', 'Deploy failed' from public.bots b where b.name = 'Max';

select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select is((select count(*) from public.voice_calls)::int, 1, 'the person sees calls to them');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000000d2');
select is((select count(*) from public.voice_calls)::int, 0, 'others don''t');
select is((select count(*) from public.voip_tokens)::int, 0, 'or their tokens');
select throws_ok($$ insert into public.voip_tokens (user_id, token) values ('00000000-0000-0000-0000-0000000000d1', 'zzzzzzzzzzzzzzzz') $$,
  '42501', null, 'nobody registers a token for someone else');
reset role;

select * from finish();
rollback;
