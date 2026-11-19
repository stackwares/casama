-- D-432: weekly plans as a price anchor. Plus, Pro and Max can be paid by the week, at about twice
-- the monthly rate ($7.99 / $19.99 / $39.99), so monthly and yearly read as the good deals.
--
-- 1. plans.interval allows 'week'. The API lists week plans only to apps that ask for them
--    (?periods=week), because shipped apps parse the interval as a strict enum.
-- 2. Weekly rows copy their monthly tier's limits without the Pro trial (no trial on weekly) and
--    without extra people (the seat add-on is monthly or yearly only).
-- 3. grant_month() names each paid week by the day it started ('YYYY-MM-DD'), so included credits
--    are granted once a week; the server grants a quarter of monthly_credits_usd per week.
--    References stay 'monthly:<label>:<plan>', so expiry and refund rules apply unchanged.

alter table public.plans drop constraint if exists plans_interval_check;
alter table public.plans add constraint plans_interval_check
  check (interval in ('none', 'week', 'month', 'year'));

insert into public.plans (code, name, interval, limits, store_product_ids, sort, price_label, active)
select w.code, p.name, 'week',
       p.limits - 'trial_days' - 'trial_credits_usd' - 'trial_computer_hours' - 'extra_seat_usd',
       w.store, p.sort, w.price_label, true
from (values
  ('plus_weekly', 'plus', '$7.99 / week',
   '{"app_store": "ai.casama.plus.weekly", "google_play": "casama_plus:weekly"}'::jsonb),
  ('pro_weekly', 'pro', '$19.99 / week',
   '{"app_store": "ai.casama.pro.weekly", "google_play": "casama_pro:weekly"}'::jsonb),
  ('max_weekly', 'max', '$39.99 / week',
   '{"app_store": "ai.casama.max.weekly", "google_play": "casama_max:weekly"}'::jsonb)
) as w(code, base, price_label, store)
join public.plans p on p.code = w.base
on conflict (code) do nothing;

create or replace function public.grant_month(p_sub uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce((
    select case
      -- A trial's grant belongs to the month it started (when the subscription was first seen),
      -- so one trial is granted once.
      when s.status = 'trialing'
        then to_char(s.created_at at time zone 'utc', 'YYYY-MM')
      when s.current_period_end is null or p.interval not in ('week', 'month', 'year')
        then to_char(now() at time zone 'utc', 'YYYY-MM')
      -- Weekly plans: the day the current paid week started (D-432).
      when p.interval = 'week'
        then to_char((s.current_period_end at time zone 'utc') - interval '7 days', 'YYYY-MM-DD')
      when p.interval = 'month'
        then to_char((s.current_period_end at time zone 'utc') - interval '1 month', 'YYYY-MM')
      else (
        select to_char(y.start + make_interval(months => greatest(0, least(11,
                 (extract(year from age(now() at time zone 'utc', y.start)) * 12
                  + extract(month from age(now() at time zone 'utc', y.start)))::int))), 'YYYY-MM')
        from (select (s.current_period_end at time zone 'utc') - interval '1 year' as start) y)
    end
    from public.subscriptions s join public.plans p on p.code = s.plan_code
    where s.id = p_sub
  ), to_char(now() at time zone 'utc', 'YYYY-MM'));
$$;
revoke execute on function public.grant_month(uuid) from public, anon, authenticated;
