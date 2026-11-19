-- The waitlist's Phases 2 and 3 (docs/WAITLIST-PLAN.md §7.3, §6.4, §11): one-time codes let in
-- exactly one more address, the daily batch's table is the API's and the worker's only, and how a
-- person got in can be read by the worker without an address ever leaving.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

insert into auth.users (id, email, aud, role) values
  ('10000000-0000-0000-0000-0000000008a1', 'p3-coded@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000008a2', 'p3-picked@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000008a3', 'p3-auto@example.com', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-0000000008a4', 'p3-open@example.com', 'authenticated', 'authenticated');
-- An entry let in from the list, with the hash of its email's one-time code K7M2-QXAB.
insert into public.waitlist_entries (email, email_key, status, admitted_at, admitted_via, one_time_code_hash) values
  ('p3-issuer@example.com', public.email_key('p3-issuer@example.com'), 'admitted', now(), 'batch',
   encode(sha256(convert_to('K7M2QXAB', 'UTF8')), 'hex')),
  ('p3-waiting@example.com', public.email_key('p3-waiting@example.com'), 'waiting', null, null,
   encode(sha256(convert_to('W8W8W8W8', 'UTF8')), 'hex'));
insert into public.waitlist_entries (email, email_key, status, admitted_at, admitted_via) values
  ('p3-coded@example.com', public.email_key('p3-coded@example.com'), 'admitted', now(), 'campaign:SHOWHN'),
  ('p3-picked@example.com', public.email_key('p3-picked@example.com'), 'admitted', now(), 'batch'),
  ('p3-auto@example.com', public.email_key('p3-auto@example.com'), 'admitted', now(), 'auto');
insert into public.invite_campaigns (code, label, max_uses) values ('SHOW-HN26', 'Same shape', 5);

-- One-time codes.
select is((select kind || '|' || available::text from public.invite_code_preview('K7M2-QXAB', 3)),
  'one_time|true', 'a handed-out one-time code previews as one, with its invite left');
select is((select outcome || '|' || kind || '|' || admitted_now::text
           from public.waitlist_claim('relay1@privaterelay.appleid.com', 'K7M2-QXAB', 3)),
  'admitted|one_time|true', 'it lets one other address in');
select is((select invite_code || '|' || admitted_via from public.waitlist_entries
           where email_key = public.email_key('relay1@privaterelay.appleid.com')),
  'ONE-TIME|one_time:' || (select id from public.waitlist_entries where email = 'p3-issuer@example.com')::text,
  'the entry it lets in names the issuing entry, never the code');
select ok((select one_time_used_at is not null and one_time_used_for = public.email_key('relay1@privaterelay.appleid.com')
           from public.waitlist_entries where email = 'p3-issuer@example.com'),
  'the code is marked used, with the inbox it let in as a hash');
select is((select outcome || '|' || admitted_now::text
           from public.waitlist_claim('relay1@privaterelay.appleid.com', 'K7M2-QXAB', 3)),
  'admitted|false', 'the same address again is in already and uses nothing');
select is((select outcome || '|' || kind from public.waitlist_claim('relay2@privaterelay.appleid.com', 'K7M2-QXAB', 3)),
  'waitlisted|one_time', 'a second address goes on the list instead');
select is((select priority from public.waitlist_entries
           where email_key = public.email_key('relay2@privaterelay.appleid.com')), 10, 'near the front');
select is((select available from public.invite_code_preview('K7M2-QXAB', 3)), false, 'and the code shows as used');
select throws_ok($$ select * from public.waitlist_claim('x@example.com', 'W8W8-W8W8', 3) $$,
  'P0002', 'invite_not_found', 'a code from an entry that was never let in is no code');
select is((select count(*)::int from public.invite_code_preview('W8W8-W8W8', 3)), 0, 'and has no preview');
select is((select outcome || '|' || kind from public.waitlist_claim('shape@example.com', 'SHOW-HN26', 3)),
  'admitted|campaign', 'a campaign code of the same shape is still a campaign');
select is((select count(*)::int from public.waitlist_entries where one_time_code_hash is not null
           and one_time_code_hash !~ '^[0-9a-f]{64}$'), 0, 'only hashes are kept');
select throws_ok($$ update public.waitlist_entries set one_time_code_hash = 'K7M2QXAB' where email = 'p3-issuer@example.com' $$,
  '23514', null, 'and a code itself can''t be stored');

-- How people got in, for analytics.
select is((select string_agg(admitted_via, ',' order by user_id) from public.worker_admitted_via(array[
    '10000000-0000-0000-0000-0000000008a1', '10000000-0000-0000-0000-0000000008a2',
    '10000000-0000-0000-0000-0000000008a3', '10000000-0000-0000-0000-0000000008a4']::uuid[])),
  'code,hand,batch,none', 'a code, an owner, the daily batch, or no entry');

-- The daily batch's days.
insert into public.waitlist_batches (day, admitted) values ('2031-01-01', 3);
select throws_ok($$ insert into public.waitlist_batches (day) values ('2031-01-01') $$,
  '23505', null, 'one row a day, so two workers can''t both run it');

-- Who can see and call what.
create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('10000000-0000-0000-0000-0000000008a1');
select throws_ok($$ select * from public.waitlist_batches $$, '42501', null, 'a signed-in person can''t read the batches');
select throws_ok($$ select * from public.worker_admitted_via(array['10000000-0000-0000-0000-0000000008a2']::uuid[]) $$,
  '42501', null, 'nor ask how someone got in');
select throws_ok($$ select * from public.waitlist_claim('me@example.com', 'K7M2-QXAB', 3) $$, '42501', null,
  'nor claim a one-time code');
select throws_ok($$ select * from public.invite_code_preview('K7M2-QXAB', 3) $$, '42501', null,
  'nor look one up');
reset role;
set local role anon;
select throws_ok($$ select * from public.waitlist_batches $$, '42501', null, 'a signed-out caller can''t read the batches');
select throws_ok($$ select * from public.worker_admitted_via(array['10000000-0000-0000-0000-0000000008a2']::uuid[]) $$,
  '42501', null, 'nor ask how someone got in');
reset role;
set local role casama_worker;
select lives_ok($$ select * from public.worker_admitted_via(array['10000000-0000-0000-0000-0000000008a2']::uuid[]) $$,
  'the worker can ask how someone got in');
select lives_ok($$ insert into public.waitlist_batches (day) values ('2031-01-02') $$,
  'and can record a batch day');
reset role;
select is((select count(*)::int from pg_policies where tablename = 'waitlist_batches'
           and 'casama_worker' = any(roles)), 1, 'through the worker policy');

select * from finish();
rollback;
