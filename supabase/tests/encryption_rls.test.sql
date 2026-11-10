begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

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

select * from finish();
rollback;
