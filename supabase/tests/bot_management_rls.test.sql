begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000d1', 'boss@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000d2', 'outsider@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
select pg_temp.login('00000000-0000-0000-0000-0000000000d1');
select public.create_organization('Bots Org', 'bots-org');
insert into public.bots (org_id, name, created_by)
  select id, 'Ada', '00000000-0000-0000-0000-0000000000d1' from public.organizations where slug = 'bots-org';
update public.bots set persona_md = 'Be brief.', autonomy = 'autonomous' where name = 'Ada';
select is((select changed_fields from public.bot_revisions), array['persona_md', 'autonomy'], 'a change keeps the previous version');
select is((select changed_by_user from public.bot_revisions), '00000000-0000-0000-0000-0000000000d1'::uuid, 'with who changed it');
select lives_ok($$ insert into public.bot_folders (org_id, name) select id, 'Sales' from public.organizations where slug = 'bots-org' $$, 'members make folders');
reset role;
select pg_temp.login('00000000-0000-0000-0000-0000000000d2');
select is((select count(*)::int from public.bot_revisions), 0, 'outsiders see no history');
reset role;
select * from finish();
rollback;
