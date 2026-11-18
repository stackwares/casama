-- Monthly email choices (D-408): a person reads only their own choice, never the address Resend
-- has; nobody changes it directly (the API does, and tells Resend); the worker retries; an email
-- change marks the row for the worker.
begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000005a1', 'news-a1@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000005a2', 'news-a2@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000005a3', 'news-a3@example.com', 'authenticated', 'authenticated');
-- Two people in the same workspace still don't see each other's choice.
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000005b1', 'Newsletter', 'newsletter-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a1', 'owner'),
  ('10000000-0000-0000-0000-0000000005b1', '10000000-0000-0000-0000-0000000005a2', 'member');
-- As the API writes them.
insert into public.newsletter_subscriptions (user_id, subscribed, changed_via, asked_at, resend_email) values
  ('10000000-0000-0000-0000-0000000005a1', true, 'settings', now(), 'news-a1@example.com'),
  ('10000000-0000-0000-0000-0000000005a2', false, 'card', now(), null),
  ('10000000-0000-0000-0000-0000000005a3', false, null, null, null);

select is((select subscribed from public.newsletter_subscriptions
  where user_id = '10000000-0000-0000-0000-0000000005a2'), false, 'off by default');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('10000000-0000-0000-0000-0000000005a2');
select is((select count(*)::int from public.newsletter_subscriptions), 1,
  'a person sees only their own choice, not a teammate''s');
select is((select changed_via from public.newsletter_subscriptions), 'card', 'and reads it');
select throws_ok($$ select resend_email from public.newsletter_subscriptions $$, '42501', null,
  'but not the address Resend has');
select throws_ok($$ update public.newsletter_subscriptions set subscribed = true $$, '42501', null,
  'changes go through the API, which tells Resend');
select throws_ok($$ insert into public.newsletter_subscriptions (user_id, subscribed)
  values ('10000000-0000-0000-0000-0000000005a2', true) $$, '42501', null,
  'nobody subscribes directly');
reset role;

select set_config('role', 'anon', true);
select throws_ok($$ select subscribed from public.newsletter_subscriptions $$, '42501', null,
  'signed out, nothing');
reset role;

-- An email change marks a subscribed row (or one Resend has an address for) for the worker.
update auth.users set email = 'news-a1-new@example.com' where id = '10000000-0000-0000-0000-0000000005a1';
update auth.users set email = 'news-a3-new@example.com' where id = '10000000-0000-0000-0000-0000000005a3';
select is((select sync_due from public.newsletter_subscriptions
  where user_id = '10000000-0000-0000-0000-0000000005a1'), true, 'an email change is sent to Resend');
select is((select sync_due from public.newsletter_subscriptions
  where user_id = '10000000-0000-0000-0000-0000000005a3'), false,
  'not for someone who never subscribed');

delete from auth.users where id = '10000000-0000-0000-0000-0000000005a2';
select is((select count(*)::int from public.newsletter_subscriptions
  where user_id = '10000000-0000-0000-0000-0000000005a2'), 0, 'goes with the account');

select ok(exists (select 1 from pg_policies where tablename = 'newsletter_subscriptions' and policyname = 'casama_worker_all'),
  'the worker retries failed syncs');

select * from finish();
rollback;
