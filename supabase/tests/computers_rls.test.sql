begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, aud, role) values
  ('60000000-0000-0000-0000-00000000000a', 'ca@example.com', 'authenticated', 'authenticated'),
  ('60000000-0000-0000-0000-00000000000b', 'cb@example.com', 'authenticated', 'authenticated'),
  ('60000000-0000-0000-0000-00000000000c', 'cc@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug) values
  ('70000000-0000-0000-0000-00000000000a', 'CA', 'comp-a'),
  ('70000000-0000-0000-0000-00000000000b', 'CB', 'comp-b');
insert into public.memberships (org_id, user_id, role) values
  ('70000000-0000-0000-0000-00000000000a', '60000000-0000-0000-0000-00000000000a', 'owner'),
  ('70000000-0000-0000-0000-00000000000a', '60000000-0000-0000-0000-00000000000c', 'member'),
  ('70000000-0000-0000-0000-00000000000b', '60000000-0000-0000-0000-00000000000b', 'owner');
insert into public.bots (id, org_id, created_by, name, visibility) values
  ('80000000-0000-0000-0000-00000000000a', '70000000-0000-0000-0000-00000000000a', '60000000-0000-0000-0000-00000000000a', 'Private', 'private');
insert into public.computers (id, org_id, kind, owner_bot_id, name) values
  ('90000000-0000-0000-0000-00000000000a', '70000000-0000-0000-0000-00000000000a', 'private', '80000000-0000-0000-0000-00000000000a', 'Private computer');
insert into public.checkpoints (org_id, computer_id, label, storage_ref)
select org_id, id, 'cp', '{"key":"k"}' from public.computers where org_id = '70000000-0000-0000-0000-00000000000a' and kind = 'team';

select is((select count(*)::int from public.computers where kind = 'team' and org_id in
  ('70000000-0000-0000-0000-00000000000a', '70000000-0000-0000-0000-00000000000b')), 2, 'each org gets a team computer');

create or replace function pg_temp.login(uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

select pg_temp.login('60000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from public.computers), 2, 'owner sees team and own private computer');
select is((select count(*)::int from public.checkpoints), 1, 'owner sees org checkpoints');
reset role;

select pg_temp.login('60000000-0000-0000-0000-00000000000c');
select is((select count(*)::int from public.computers), 1, 'member sees only the team computer');
reset role;

select pg_temp.login('60000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.computers), 1, 'other org sees only its own team computer');
select is((select count(*)::int from public.checkpoints), 0, 'other org sees no checkpoints');
update public.computers set state = 'running';
reset role;
select is((select count(*)::int from public.computers where state = 'running'), 0, 'users cannot change computers directly');

select * from finish();
rollback;
