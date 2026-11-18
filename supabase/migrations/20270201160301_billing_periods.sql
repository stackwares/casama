-- Billing audit 2026-11-17 (D-333).
--
-- 1. Included credits follow the paid period, not the calendar month. A subscription started on
--    the 31st used to get the next calendar month's grant the next day, so N paid months earned
--    N+1 grants. grant_month() names the month a grant belongs to:
--      - no subscription (Free) or no period end: the calendar month (UTC), as before;
--      - a trial: the month it started;
--      - monthly plans: the month the current paid period started;
--      - yearly plans: the month of the current one-month slice of the paid year.
--    Grants keep their 'monthly:<YYYY-MM>:<plan>' references, so each period still grants once.
--
-- 2. A refund applies to the period it paid for. 'refunded' used to be final, so a partial or old
--    refund left a still-paying customer with no plan for good. refunded_through records the end
--    of the refunded period; a later paid period (a renewal past it) is honoured again.

alter table public.subscriptions add column if not exists refunded_through timestamptz;
update public.subscriptions set refunded_through = coalesce(current_period_end, now())
 where status = 'refunded' and refunded_through is null;

create or replace function public.grant_month(p_sub uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce((
    select case
      -- A trial's grant belongs to the month it started (when the subscription was first seen),
      -- so one trial is granted once.
      when s.status = 'trialing'
        then to_char(s.created_at at time zone 'utc', 'YYYY-MM')
      when s.current_period_end is null or p.interval not in ('month', 'year')
        then to_char(now() at time zone 'utc', 'YYYY-MM')
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
