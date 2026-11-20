-- Add the source before any complimentary subscription can be created.
alter table public.subscriptions drop constraint subscriptions_source_check;
alter table public.subscriptions add constraint subscriptions_source_check
  check (source in ('dodo', 'app_store', 'google_play', 'comp'));

-- Allow multi-month complimentary subscriptions to receive a grant each month.
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
      -- Complimentary subscriptions grant credits each month from their start.
      when s.source = 'comp' then to_char(
        (s.created_at at time zone 'utc') + make_interval(months => greatest(0,
          (extract(year from age(now() at time zone 'utc', s.created_at at time zone 'utc')) * 12
           + extract(month from age(now() at time zone 'utc', s.created_at at time zone 'utc')))::int)),
        'YYYY-MM')
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
