-- D-420: Sign in with Apple refresh tokens. Nobody signed in reads them (only the API and the
-- worker), and the Vault secret goes with its row: replaced, deleted, or cascading with the user.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000a419', 'apple-token@example.com', 'authenticated', 'authenticated');

select ok((select relrowsecurity from pg_class where oid = 'public.apple_sign_in_tokens'::regclass),
  'row-level security is on');
select ok(exists (select 1 from pg_policies where tablename = 'apple_sign_in_tokens' and policyname = 'casama_worker_all'),
  'the worker may read and delete them');

insert into public.apple_sign_in_tokens (user_id, client_id, apple_sub, vault_secret_id) values
  ('00000000-0000-0000-0000-00000000a419', 'ai.casama.app', 'sub-1', vault.create_secret('rt-one', null, 'test'));

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000a419","role":"authenticated"}', true);
select is((select count(*)::int from public.apple_sign_in_tokens), 0, 'the person can''t read their own token row');
reset role;

update public.apple_sign_in_tokens set vault_secret_id = vault.create_secret('rt-two', null, 'test')
 where user_id = '00000000-0000-0000-0000-00000000a419';
select is((select count(*)::int from vault.secrets where secret = 'rt-one'), 0, 'a replaced token leaves Vault');
select is((select count(*)::int from vault.secrets where secret = 'rt-two'), 1, 'the new token is in Vault');

delete from public.apple_sign_in_tokens where user_id = '00000000-0000-0000-0000-00000000a419';
select is((select count(*)::int from vault.secrets where secret = 'rt-two'), 0, 'a deleted row''s token leaves Vault');

insert into public.apple_sign_in_tokens (user_id, client_id, apple_sub, vault_secret_id) values
  ('00000000-0000-0000-0000-00000000a419', 'ai.casama.app.signin', 'sub-1', vault.create_secret('rt-three', null, 'test'));
delete from auth.users where id = '00000000-0000-0000-0000-00000000a419';
select is((select count(*)::int from vault.secrets where secret = 'rt-three'), 0, 'a purged account''s token leaves Vault');

select * from finish();
rollback;
