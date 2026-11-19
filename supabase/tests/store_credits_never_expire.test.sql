-- D-418: credit packs bought in the App Store or Google Play (through RevenueCat) never lapse
-- (Apple guideline 3.1.1); packs bought on the web keep 12 months.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000d4a1', 'store-pack@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug, created_by) values
  ('00000000-0000-0000-0000-00000000d4a2', 'Store pack', 'store-pack', '00000000-0000-0000-0000-00000000d4a1');

select is(public.credit_lot_expiry('purchase', 'revenuecat:purch_abc'), null::timestamptz,
  'a store pack never lapses');
select ok(public.credit_lot_expiry('purchase', 'dodo:pay_abc') > now() + interval '11 months',
  'a web pack lapses after 12 months');
select ok(public.credit_lot_expiry('grant', 'revenuecat:purch_abc') > now() + interval '11 months',
  'only purchases are exempt, not grants with a lookalike reference');

select public.credit_apply('00000000-0000-0000-0000-00000000d4a2', 5, 'grant', 'monthly:2099-01:plus', 'Month');
select public.credit_apply('00000000-0000-0000-0000-00000000d4a2', 10, 'purchase', 'revenuecat:purch_store', 'Store pack');
select public.credit_apply('00000000-0000-0000-0000-00000000d4a2', 25, 'purchase', 'dodo:pay_web', 'Web pack');

select is((select expires_at from public.credit_lots
           where org_id = '00000000-0000-0000-0000-00000000d4a2' and reference = 'revenuecat:purch_store'),
  null::timestamptz, 'the store pack''s lot has no expiry');
select ok((select expires_at > now() + interval '11 months' from public.credit_lots
           where org_id = '00000000-0000-0000-0000-00000000d4a2' and reference = 'dodo:pay_web'),
  'the web pack''s lot keeps 12 months');

-- Spending takes credits that lapse first, so the store pack is used last.
select public.credit_apply('00000000-0000-0000-0000-00000000d4a2', -30, 'usage', 'usage:big', 'Usage');
select is((select remaining from public.credit_lots
           where org_id = '00000000-0000-0000-0000-00000000d4a2' and reference = 'revenuecat:purch_store'),
  10.000000::numeric, 'the store pack is spent last');

-- The lapse sweep never touches it, even far in the future.
update public.credit_lots set expires_at = now() - interval '1 minute'
 where org_id = '00000000-0000-0000-0000-00000000d4a2' and reference <> 'revenuecat:purch_store';
select public.expire_credits();
select is((select remaining from public.credit_lots
           where org_id = '00000000-0000-0000-0000-00000000d4a2' and reference = 'revenuecat:purch_store'),
  10.000000::numeric, 'expire_credits leaves the store pack alone');

select * from finish();
rollback;
