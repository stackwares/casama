begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000005a1', 'site-owner@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000005a2', 'site-member@example.com', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000005a3', 'site-stranger@example.com', 'authenticated', 'authenticated');
create or replace function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;

insert into public.organizations (id, name, slug) values
  ('c5000000-0000-0000-0000-000000000001', 'Sites', 'sites-rls'),
  ('c5000000-0000-0000-0000-000000000002', 'Other', 'sites-rls-other');
insert into public.memberships (org_id, user_id, role) values
  ('c5000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000005a1', 'owner'),
  ('c5000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000005a2', 'member'),
  ('c5000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000005a3', 'owner');
insert into public.bots (id, org_id, name) values
  ('c5000000-0000-0000-0000-0000000000b1', 'c5000000-0000-0000-0000-000000000001', 'Builder');
insert into public.pages (id, org_id, bot_id, created_by, title, html, visibility) values
  ('c5000000-0000-0000-0000-0000000000f1', 'c5000000-0000-0000-0000-000000000001',
   'c5000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000005a1', 'Bakery', '<p>hi</p>', 'public');
insert into public.sites (page_id, org_id, created_by) values
  ('c5000000-0000-0000-0000-0000000000f1', 'c5000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000005a1');
insert into public.site_hosts (hostname, kind, org_id, page_id, is_primary, status) values
  ('bakery.sites.test', 'address', 'c5000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-0000000000f1', true, 'active');
insert into public.domains (id, name, kind, org_id, target, verify_code) values
  ('c5000000-0000-0000-0000-0000000000d1', 'bakery.com', 'connected', 'c5000000-0000-0000-0000-000000000001',
   'd-abcdefgh12345678.sites.test', 'code1');
insert into public.site_hosts (hostname, kind, org_id, page_id, domain_id, status, provider_ref) values
  ('www.bakery.com', 'custom', 'c5000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-0000000000f1',
   'c5000000-0000-0000-0000-0000000000d1', 'pending_dns', 'cf-host-1');
insert into public.domain_events (domain_id, org_id, kind) values
  ('c5000000-0000-0000-0000-0000000000d1', 'c5000000-0000-0000-0000-000000000001', 'connected');
insert into public.domain_contacts (org_id, data) values
  ('c5000000-0000-0000-0000-000000000001', '{"first_name": "Ana"}');
insert into public.domain_orders (org_id, kind, name, price_usd, cost_usd, status) values
  ('c5000000-0000-0000-0000-000000000001', 'register', 'crumb.com', 16.99, 12.03, 'checkout');

-- Members read sites, hosts, domains and history.
select pg_temp.login('00000000-0000-0000-0000-0000000005a2');
select is((select count(*)::int from public.sites), 1, 'a member reads the workspace''s sites');
select is((select count(*)::int from public.site_hosts), 2, 'a member reads its hosts');
select is((select count(*)::int from public.domains), 1, 'a member reads its domains');
select is((select count(*)::int from public.domain_events), 1, 'a member reads a domain''s history');
select is((select count(*)::int from public.domain_contacts), 0, 'only admins read the registrant''s details');
select is((select count(*)::int from public.domain_orders), 0, 'only admins read orders');
-- Nobody writes from a client.
update public.sites set indexable = true;
select is((select count(*)::int from public.sites where indexable), 0, 'a member can''t change a site');
reset role;

select pg_temp.login('00000000-0000-0000-0000-0000000005a1');
select is((select count(*)::int from public.domain_contacts), 1, 'an admin reads the registrant''s details');
select is((select count(*)::int from public.domain_orders), 1, 'an admin reads orders');
select throws_ok($$ insert into public.sites (page_id, org_id) values ('c5000000-0000-0000-0000-0000000000f1', 'c5000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'an owner can''t insert a site from a client');
select throws_ok($$ insert into public.site_hosts (hostname, kind, org_id) values ('evil.sites.test', 'address', 'c5000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'nor a host');
update public.site_hosts set status = 'active' where hostname = 'www.bakery.com';
select is((select status from public.site_hosts where hostname = 'www.bakery.com'), 'pending_dns',
  'an owner can''t mark a host live');
update public.domains set org_id = 'c5000000-0000-0000-0000-000000000002';
select is((select count(*)::int from public.domains), 1, 'nor move a domain to another workspace');
delete from public.domain_events;
select is((select count(*)::int from public.domain_events), 1, 'nor delete history');
select throws_ok($$ insert into public.domain_contacts (org_id, data) values ('c5000000-0000-0000-0000-000000000002', '{}') $$,
  '42501', null, 'nor write contacts');
select is((select count(*)::int from public.provider_cleanups), 0, 'the cleanup queue is server only');
select is((select count(*)::int from public.site_labels_retired), 0, 'retired names are server only');
reset role;

-- Another workspace sees nothing.
select pg_temp.login('00000000-0000-0000-0000-0000000005a3');
select is((select count(*)::int from public.sites) + (select count(*)::int from public.site_hosts)
  + (select count(*)::int from public.domains) + (select count(*)::int from public.domain_events)
  + (select count(*)::int from public.domain_orders) + (select count(*)::int from public.domain_contacts),
  0, 'another workspace sees none of it');
reset role;

-- Rules the schema keeps.
select throws_ok($$ insert into public.site_hosts (hostname, kind, org_id, page_id, is_primary) values
  ('second.sites.test', 'address', 'c5000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-0000000000f1', true) $$,
  '23505', null, 'one primary host per site');
select throws_ok($$ insert into public.domain_orders (org_id, kind, name, price_usd, cost_usd, status) values
  ('c5000000-0000-0000-0000-000000000002', 'register', 'crumb.com', 16.99, 12.03, 'paid') $$,
  '23505', null, 'one live checkout per name');
select throws_ok($$ insert into public.site_hosts (hostname, kind, org_id) values ('Upper.Sites.Test', 'address', 'c5000000-0000-0000-0000-000000000001') $$,
  '23514', null, 'host names are stored lowercase');
select throws_ok($$ insert into public.site_hosts (hostname, kind, org_id) values ('shop.bakery.com', 'custom', 'c5000000-0000-0000-0000-000000000001') $$,
  '23514', null, 'a custom host belongs to a domain');

-- A deleted host is queued for the edge; a deleted address is retired.
delete from public.site_hosts where hostname = 'www.bakery.com';
select is((select ref from public.provider_cleanups where hostname = 'www.bakery.com'), 'cf-host-1',
  'deleting a host queues its removal at the edge');
delete from public.pages where id = 'c5000000-0000-0000-0000-0000000000f1';
select is((select count(*)::int from public.site_hosts where kind = 'address'), 0,
  'deleting the page removes its address');
select is((select org_id from public.site_labels_retired where label = 'bakery'),
  'c5000000-0000-0000-0000-000000000001'::uuid, 'and retires the name for its workspace');

-- Deleting a workspace keeps a bought domain's record and queues its hosts' removal.
update public.domains set kind = 'registered', registrar = 'fake', status = 'active' where name = 'bakery.com';
insert into public.site_hosts (hostname, kind, org_id, domain_id, status, provider_ref) values
  ('bakery.com', 'custom', 'c5000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-0000000000d1', 'active', 'cf-host-2');
delete from public.organizations where id = 'c5000000-0000-0000-0000-000000000001';
select is((select org_id from public.domains where name = 'bakery.com'), null, 'the domain row stays with no workspace');
select is((select count(*)::int from public.provider_cleanups where ref = 'cf-host-2'), 1,
  'its hosts are queued for removal at the edge');

-- A released domain's registrant is emailed by address (§7.10); any other row still needs a recipient.
select lives_ok($$ insert into public.email_outbox (kind, dedupe_key, data)
  values ('domain_released', 'pgtap:released', '{"to": "registrant@example.com"}') $$,
  'an outbox row may name an address instead of a workspace or person');
select throws_ok($$ insert into public.email_outbox (kind, dedupe_key, data) values ('welcome', 'pgtap:nobody', '{}') $$,
  '23514', null, 'an outbox row with no recipient at all is refused');

-- Plan limits were merged, not replaced.
select is((select jsonb_object_agg(code, limits -> 'max_sites') from public.plans where code <> 'selfhost' and interval <> 'week'),
  '{"free": 1, "plus": 3, "plus_yearly": 3, "pro": 10, "pro_yearly": 10, "max": 50, "max_yearly": 50}'::jsonb,
  'max_sites per plan');

select * from finish();
rollback;
