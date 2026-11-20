-- Bot pictures (docs/BOT-PICTURES-PLAN.md §6): API-only table, avatar_url rules, prior mascot, pruning.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000b1', 'pic-ana@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000b2', 'pic-ben@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('00000000-0000-0000-0000-0000000000b1');
select public.create_organization('Pictures', 'pictures-test');
insert into public.bots (org_id, created_by, name, avatar_url)
  select id, '00000000-0000-0000-0000-0000000000b1', 'Ada', 'mascot:wow' from public.organizations where slug = 'pictures-test';
reset role;
select set_config('test.bot', (select id::text from public.bots where name = 'Ada' and created_by = '00000000-0000-0000-0000-0000000000b1'), true);
select set_config('test.org', (select id::text from public.organizations where slug = 'pictures-test'), true);
insert into public.bot_images (id, bot_id, org_id, source, large, small, original, original_type, colors)
values ('11111111-1111-4111-8111-111111111111', current_setting('test.bot')::uuid, current_setting('test.org')::uuid,
        'upload', '\x01', '\x01', '\x01', 'image/png', '7a90ff7de9f4');

select ok((select relrowsecurity from pg_class where oid = 'public.bot_images'::regclass), 'bot_images has RLS on');
select is((select count(*)::int from pg_policies where tablename = 'bot_images' and policyname <> 'casama_worker_all'), 0,
  'and no user policies: only the API reads pictures');
select is((select count(*)::int from pg_policies where tablename = 'bot_image_counts' and policyname <> 'casama_worker_all'), 0,
  'nor the daily counts');

select pg_temp.login('00000000-0000-0000-0000-0000000000b1');
select is((select count(*)::int from public.bot_images), 0, 'the bot''s own maker can''t read the bytes directly');
select throws_ok($$ update public.bots set avatar_url = 'https://tracker.example/p.gif' where id = current_setting('test.bot')::uuid $$,
  '23514', null, 'a web link is refused');
select throws_ok($$ update public.bots set avatar_url = 'image:11111111-1111-4111-8111-111111111111:000000ffffff' where id = current_setting('test.bot')::uuid $$,
  '23514', null, 'fake colours are refused');
select lives_ok($$ update public.bots set avatar_url = 'image:11111111-1111-4111-8111-111111111111:7a90ff7de9f4' where id = current_setting('test.bot')::uuid $$,
  'the bot''s own picture is fine');
reset role;
select is((select prior_mascot from public.bots where id = current_setting('test.bot')::uuid), 'mascot:wow',
  'the mascot it had is remembered');
select isnt((select used_at from public.bot_images where id = '11111111-1111-4111-8111-111111111111'), null,
  'switching to a picture marks it used');

-- Six newer pictures: the newest five stay, plus the one in use.
insert into public.bot_images (bot_id, org_id, source, large, small, original, original_type, colors, created_at)
select current_setting('test.bot')::uuid, current_setting('test.org')::uuid, 'upload', '\x01', '\x01', '\x01', 'image/png',
       '7a90ff7de9f4', now() + make_interval(secs => g)
from generate_series(1, 6) g;
select is((select count(*)::int from public.bot_images where bot_id = current_setting('test.bot')::uuid), 6,
  'five recent pictures and the one in use stay');
select ok(exists (select 1 from public.bot_images where id = '11111111-1111-4111-8111-111111111111'),
  'the picture in use is never pruned');
select is((select count(original)::int from public.bot_images where bot_id = current_setting('test.bot')::uuid), 3,
  'originals stay for the newest two and the one in use');

select * from finish();
rollback;
