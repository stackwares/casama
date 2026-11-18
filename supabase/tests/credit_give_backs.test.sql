-- Billing audit 2026-11-17: credits given back refill the lots they were spent from, so month
-- credits can't be turned into credits that never lapse.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000c9b1', 'give-back@example.com', 'authenticated', 'authenticated');
insert into public.organizations (id, name, slug, created_by) values
  ('00000000-0000-0000-0000-00000000c9b2', 'Give back', 'give-back', '00000000-0000-0000-0000-00000000c9b1');

select public.credit_apply('00000000-0000-0000-0000-00000000c9b2', 5, 'grant', 'monthly:2099-01:plus', 'Month');
select public.credit_apply('00000000-0000-0000-0000-00000000c9b2', 10, 'purchase', 'pack:give-back', 'Pack');
-- A $4 hold, then $1 of it given back when the usage settles lower.
select public.credit_apply('00000000-0000-0000-0000-00000000c9b2', -4, 'usage', 'usage:hold', 'Hold');
select public.credit_apply('00000000-0000-0000-0000-00000000c9b2', 1, 'usage', 'usage:back', 'Back');

select is((select count(*)::int from public.credit_lots where org_id = '00000000-0000-0000-0000-00000000c9b2'), 2,
  'no new lot for money given back');
select is((select remaining from public.credit_lots where org_id = '00000000-0000-0000-0000-00000000c9b2' and reason = 'grant'),
  2.000000::numeric, 'the month''s lot it was spent from is refilled');
select is((select sum(remaining) from public.credit_lots where org_id = '00000000-0000-0000-0000-00000000c9b2'),
  (select balance_after from public.credit_ledger where org_id = '00000000-0000-0000-0000-00000000c9b2' order by seq desc limit 1),
  'lots still add up to the balance');

-- A waived run gives back more than the open lots had spent (the lot it came from has lapsed).
update public.credit_lots set expires_at = now() - interval '1 minute', remaining = 0
 where org_id = '00000000-0000-0000-0000-00000000c9b2' and reason = 'grant';
select public.credit_apply('00000000-0000-0000-0000-00000000c9b2', 3, 'refund', 'failed-run:x', 'Waived');
select is((select remaining from public.credit_lots where org_id = '00000000-0000-0000-0000-00000000c9b2' and reason = 'purchase'),
  10.000000::numeric, 'the open pack lot is not overfilled');
select ok((select expires_at is not null and expires_at <= date_trunc('month', now()) + interval '2 months'
           from public.credit_lots where org_id = '00000000-0000-0000-0000-00000000c9b2' and reason = 'refund'),
  'the rest lapses at the end of next month, not never');

-- Purchases still last 12 months.
select ok((select expires_at > now() + interval '11 months' from public.credit_lots
           where org_id = '00000000-0000-0000-0000-00000000c9b2' and reason = 'purchase'),
  'purchases keep their own expiry');

select * from finish();
rollback;
