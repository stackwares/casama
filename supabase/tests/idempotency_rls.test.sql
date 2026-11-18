begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'u1@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000a2', 'u2@example.com', 'authenticated', 'authenticated');

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$ insert into public.idempotency_keys (user_id, key, method, path, status, response)
  values ('00000000-0000-0000-0000-0000000000a1', 'k1', 'POST', '/v1/orgs', 201, '{}') $$, 'user stores own key');
select throws_ok($$ insert into public.idempotency_keys (user_id, key, method, path, status, response)
  values ('00000000-0000-0000-0000-0000000000a2', 'k2', 'POST', '/v1/orgs', 201, '{}') $$, '42501', null, 'cannot store for another user');
reset role;

select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a2","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*)::int from public.idempotency_keys), 0, 'other users see nothing');
reset role;

select * from finish();
rollback;
