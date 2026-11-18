-- Billing audit 2026-11-17: free credits, the trial and referral decisions are keyed on a
-- normalised inbox, survive deleting the account, and aren't reachable through /rest/v1.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

select is(public.email_key('Ana.Reyes+casama@GoogleMail.com'), public.email_key('anareyes@gmail.com'),
  'Gmail ignores dots, case, +tags and googlemail.com');
select is(public.email_key(' bo+x@example.com '), public.email_key('bo@example.com'),
  '+tags and spaces are ignored everywhere');
select isnt(public.email_key('b.o@example.com'), public.email_key('bo@example.com'),
  'dots count outside Gmail');
select ok(public.email_key('nobody') is null and public.email_key(null) is null and public.email_key('@x.com') is null,
  'no key without a real address');
select ok(public.email_key('bo@example.com') !~ 'bo', 'only a hash is stored');

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000e1d1', 'inbox.test@gmail.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000e1d2', 'inboxtest+2@gmail.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000e1d3', 'someone-else@example.com', 'authenticated', 'authenticated');

select ok(public.claim_free_credits('00000000-0000-0000-0000-00000000e1d1'), 'the first account claims the free credits');
select ok(public.claim_free_credits('00000000-0000-0000-0000-00000000e1d1'), 'and keeps them');
select ok(not public.claim_free_credits('00000000-0000-0000-0000-00000000e1d2'), 'a +tag account on the same inbox doesn''t');
select ok(public.claim_free_credits('00000000-0000-0000-0000-00000000e1d3'), 'another inbox does');
select ok(public.claim_free_credits(null), 'no account, no limit');

select ok(not public.trial_used('00000000-0000-0000-0000-00000000e1d2'), 'no trial used yet');
select ok(public.claim_trial('00000000-0000-0000-0000-00000000e1d2', 'dodo:sub_1'), 'the first subscription holds the trial');
select ok(not public.claim_trial('00000000-0000-0000-0000-00000000e1d1', 'dodo:sub_2'), 'a second one on the same inbox doesn''t');
select ok(public.trial_used('00000000-0000-0000-0000-00000000e1d1'), 'the trial is used for every account on the inbox');

delete from auth.users where id = '00000000-0000-0000-0000-00000000e1d1';
select ok(public.claim_free_credits('00000000-0000-0000-0000-00000000e1d2') and public.trial_used('00000000-0000-0000-0000-00000000e1d2'),
  'once the holder is deleted another account gets the free credits, but the trial stays used');

select ok(not has_table_privilege('authenticated', 'public.email_identities', 'select')
  and not has_function_privilege('authenticated', 'public.claim_free_credits(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.trial_used(uuid)', 'execute'),
  'nothing callable through /rest/v1');

select * from finish();
rollback;
