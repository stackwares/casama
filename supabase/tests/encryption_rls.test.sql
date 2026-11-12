begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email, aud, role) values ('00000000-0000-0000-0000-0000000000e1', 'ana@example.com', 'authenticated', 'authenticated');
select set_config('request.jwt.claims', json_build_object('sub', '00000000-0000-0000-0000-0000000000e1', 'role', 'authenticated')::text, true);
select set_config('role', 'authenticated', true);
select public.create_organization('Key Org', 'key-org');
reset role;
insert into public.org_keys (org_id, wrapped_key, wrapper) select id, 'wrapped', 'local:test' from public.organizations where slug = 'key-org';

select set_config('role', 'authenticated', true);
select is((select count(*) from public.org_keys)::int, 0, 'even owners never read wrapped keys');
select throws_ok($$ update public.organizations set content_encryption = 'on' where slug = 'key-org' $$, null, 'owners change encryption only through the API');
reset role;
select is((select content_encryption from public.organizations where slug = 'key-org'), 'off', 'still off');

-- Data key rotation (D-238): one current key per workspace; retired keys may sit beside it.
select throws_ok($$ insert into public.org_keys (org_id, wrapped_key, wrapper) select id, 'w2', 'local:test' from public.organizations where slug = 'key-org' $$,
  '23505', null, 'only one current key per workspace');
update public.org_keys set retired_at = now() where org_id = (select id from public.organizations where slug = 'key-org');
select lives_ok($$ insert into public.org_keys (org_id, wrapped_key, wrapper) select id, 'w2', 'local:test' from public.organizations where slug = 'key-org' $$,
  'a new key beside a retired one');
-- The in-use check finds a sealed value in any column, and only the server may run it.
update public.organizations set name = 'enc:v1:' || (select id from public.org_keys where retired_at is not null and wrapper = 'local:test' limit 1) || ':abc' where slug = 'key-org';
select is(public.content_key_in_use((select id from public.org_keys where retired_at is not null and wrapper = 'local:test' limit 1)), 'organizations', 'a retired key still in use is found');
select is(public.content_key_in_use(gen_random_uuid()), null, 'an unused key is not');
select set_config('role', 'authenticated', true);
select throws_ok($$ select public.content_key_in_use(gen_random_uuid()) $$, '42501', null, 'app sessions cannot run the in-use check');
reset role;

select * from finish();
rollback;
