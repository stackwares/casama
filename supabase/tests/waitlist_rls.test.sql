-- The waitlist and invite gate (docs/WAITLIST-PLAN.md): only the API reads the list and the
-- campaign codes; nobody signed in or signed out can read them or call the functions that admit;
-- the worker can reach what its sweep needs; and the rules the hook and the claim rely on hold.
begin;
create extension if not exists pgtap with schema extensions;
select plan(37);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000007a1', 'wl-member@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000007a2', 'wl-other@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('10000000-0000-0000-0000-0000000007b1', 'Waitlist Co', 'waitlist-rls');
insert into public.memberships (org_id, user_id, role) values
  ('10000000-0000-0000-0000-0000000007b1', '10000000-0000-0000-0000-0000000007a1', 'owner');
insert into public.referral_codes (user_id, code) values
  ('10000000-0000-0000-0000-0000000007a1', 'W7A1XZ');
insert into public.invite_campaigns (code, label, max_uses) values ('LAUNCH-DAY', 'Launch day', 1);
insert into public.waitlist_entries (email, email_key, status, admitted_at, admitted_via) values
  ('in@example.com', public.email_key('in@example.com'), 'admitted', now(), 'admin'),
  ('wait@example.com', public.email_key('wait@example.com'), 'waiting', null, null);

-- The shapes the tables hold.
select throws_ok($$ insert into public.invite_campaigns (code, label, max_uses) values ('ABC123', 'x', 1) $$,
  '23514', null, 'a campaign code can''t look like a member''s 6-character code');
select throws_ok($$ insert into public.invite_campaigns (code, label, max_uses) values ('AB12CD34', 'x', 1) $$,
  '23514', null, 'nor like an 8-character workspace code');
select throws_ok($$ insert into public.invite_campaigns (code, label, max_uses) values ('lower-case', 'x', 1) $$,
  '23514', null, 'and is stored in capitals');
select throws_ok($$ insert into public.waitlist_entries (email, email_key) values ('IN+tag@example.com', public.email_key('in+tag@example.com')) $$,
  '23505', null, 'one entry per inbox, however the address is written');
select throws_ok($$ insert into public.waitlist_entries (email, email_key, status) values ('x@example.com', 'k', 'removed') $$,
  '23514', null, 'an entry is waiting, admitted or joined');

-- What the hook asks.
select ok(public.signup_admitted('IN+casama@Example.com'), 'an admitted inbox may sign up, however it is written');
select ok(not public.signup_admitted('wait@example.com'), 'someone only waiting may not');
select ok(not public.signup_admitted('nobody@example.com'), 'nor a stranger');
select ok(not public.signup_admitted(''), 'nor an empty address');

insert into public.invites (org_id, email, role, token_hash) values
  ('10000000-0000-0000-0000-0000000007b1', 'guest@example.com', 'member', 'wl-token-1');
delete from public.entitlements where org_id = '10000000-0000-0000-0000-0000000007b1';
select ok(public.signup_invited_with_seat('Guest@Example.com'), 'a workspace invite counts when the workspace has no seat limit');
insert into public.entitlements (org_id, plan_code, limits)
  values ('10000000-0000-0000-0000-0000000007b1', (select code from public.plans order by code limit 1), '{"seats": 1}'::jsonb);
select ok(not public.signup_invited_with_seat('guest@example.com'), 'not when every seat is taken');
update public.entitlements set limits = '{"seats": 2}'::jsonb where org_id = '10000000-0000-0000-0000-0000000007b1';
select ok(public.signup_invited_with_seat('guest@example.com'), 'again when there is a seat for it');
update public.invites set accepted_at = now() where token_hash = 'wl-token-1';
select ok(not public.signup_invited_with_seat('guest@example.com'), 'and not once the invite was used');

-- Claiming.
select is((select outcome from public.waitlist_claim('first@example.com', 'launch-day', 3)), 'admitted',
  'a campaign code lets someone in');
select is((select outcome from public.waitlist_claim('second@example.com', 'LAUNCH-DAY', 3)), 'waitlisted',
  'and puts the next person on the list once its total is used');
select is((select priority from public.waitlist_entries where email = 'second@example.com'), 10,
  'near the front');
select is((select used from public.invite_campaigns where code = 'LAUNCH-DAY'), 1, 'the total is never passed');
select is((select outcome from public.waitlist_claim('wl-other@example.com', 'LAUNCH-DAY', 3)), 'admitted',
  'someone with an account is told they are in');
select is((select count(*)::int from public.waitlist_entries where email = 'wl-other@example.com'), 0,
  'and uses up nothing');
select is((select outcome from public.waitlist_claim('friend@example.com', 'W7A1XZ', 3)), 'waitlisted',
  'a member''s invites are locked before their first finished chat');
insert into public.analytics_milestones (user_id, milestone)
  values ('10000000-0000-0000-0000-0000000007a1', 'first_value');
select is((select outcome from public.waitlist_claim('friend@example.com', 'W7A1XZ', 1)), 'admitted',
  'and let a friend in after it');
select is((select outcome from public.waitlist_claim('friend2@example.com', 'W7A1XZ', 1)), 'waitlisted',
  'up to the member''s number of invites');
select is(public.invites_used('10000000-0000-0000-0000-0000000007a1'), 1, 'which are counted');
select throws_ok($$ select * from public.waitlist_claim('x@example.com', 'NOSUCH', 3) $$,
  'P0002', 'invite_not_found', 'a code that doesn''t exist says so');
select throws_ok($$ select * from public.waitlist_claim('not-an-address', 'LAUNCH-DAY', 3) $$,
  '22023', 'bad_email', 'and so does something that isn''t an address');

-- Who can see and call what.
create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('10000000-0000-0000-0000-0000000007a1');
select throws_ok($$ select * from public.waitlist_entries $$, '42501', null, 'a signed-in person can''t read the list');
select throws_ok($$ select * from public.invite_campaigns $$, '42501', null, 'nor the campaign codes');
select throws_ok($$ select public.signup_admitted('in@example.com') $$, '42501', null, 'nor ask who was let in');
select throws_ok($$ select * from public.waitlist_claim('me@example.com', 'LAUNCH-DAY', 99) $$, '42501', null,
  'nor claim a code with their own number of invites');
select throws_ok($$ select * from public.invite_code_preview('W7A1XZ', 3) $$, '42501', null,
  'nor look codes up past the API''s guessing limit');
-- No policy lets them change their code's row, so this touches nothing.
update public.referral_codes set invite_bonus = 99 where user_id = auth.uid();
reset role;
select is((select invite_bonus from public.referral_codes where code = 'W7A1XZ'), 0,
  'nor give themselves more invites');
set local role anon;
select throws_ok($$ select * from public.waitlist_entries $$, '42501', null, 'a signed-out caller can''t read the list');
select throws_ok($$ select * from public.waitlist_claim('me@example.com', 'LAUNCH-DAY', 99) $$, '42501', null,
  'nor claim a code');
reset role;
set local role casama_worker;
select lives_ok($$ select * from public.worker_waitlist_link(true, 10) $$, 'the worker can tie sign-ups to their entries');
reset role;

-- A deleted account leaves its inbox's hash, and nothing that names the person.
insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000007a3', 'leaver@example.com', 'authenticated', 'authenticated');
insert into public.waitlist_entries (email, email_key, status, admitted_at, admitted_via, note, ip_hash, user_id, joined_at) values
  ('leaver@example.com', public.email_key('leaver@example.com'), 'joined', now(), 'batch', 'My plans', 'abc', '10000000-0000-0000-0000-0000000007a3', now());
delete from auth.users where id = '10000000-0000-0000-0000-0000000007a3';
select is((select email::text || '|' || coalesce(note, '') || '|' || coalesce(ip_hash, '')
           from public.waitlist_entries where email_key = public.email_key('leaver@example.com')), '||',
  'deleting an account removes the address, the note and the network hash from its entry');
select is((select status from public.waitlist_entries where email_key = public.email_key('leaver@example.com')), 'joined',
  'the entry itself stays');
select ok(public.signup_admitted('Leaver@example.com'), 'so the same inbox can sign up again');

select * from finish();
rollback;
