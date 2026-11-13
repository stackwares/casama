-- Casama Cloud pricing, revised (D-249): every price fits the App Store and Google Play without a
-- special request (Max yearly $899), Pro and Max sell extra people, Pro has a 7-day trial, and
-- computers are limited by how many run at once and sized by plan.
--
-- New limits keys:
--   max_running_computers  hosted computers running at the same time (others sleep)
--   computer_size          1, 2 or 4: vCPUs and GB of memory of each hosted computer
--   extra_seat_usd         a plan that sells extra people, and their monthly price
--   trial_days, trial_credits_usd, trial_computer_hours   what a trial gets instead
-- No max_bots key means unlimited bots.

update public.plans set
  limits = '{"credit_gate": true, "monthly_credits_usd": 1, "max_bots": 3, "max_computers": 1, "max_running_computers": 1, "computer_size": 1, "computer_hours": 5, "seats": 1, "cloud_daily_usd": 0.25}'
where code = 'free';

update public.plans set
  limits = '{"credit_gate": true, "monthly_credits_usd": 5, "max_bots": 10, "max_computers": 2, "max_running_computers": 1, "computer_size": 1, "computer_hours": 30, "seats": 1, "cloud_daily_usd": 5}',
  price_label = case code when 'plus' then '$15 / month' else '$150 / year' end
where code in ('plus', 'plus_yearly');

update public.plans set
  limits = '{"credit_gate": true, "monthly_credits_usd": 15, "max_computers": 5, "max_running_computers": 2, "computer_size": 2, "computer_hours": 100, "seats": 3, "extra_seat_usd": 12, "cloud_daily_usd": 10, "trial_days": 7, "trial_credits_usd": 2, "trial_computer_hours": 10}',
  price_label = case code when 'pro' then '$49 / month' else '$490 / year' end
where code in ('pro', 'pro_yearly');

update public.plans set
  limits = '{"credit_gate": true, "monthly_credits_usd": 30, "max_computers": 10, "max_running_computers": 3, "computer_size": 4, "computer_hours": 300, "seats": 10, "extra_seat_usd": 12, "cloud_daily_usd": 25}',
  price_label = case code when 'max' then '$99 / month' else '$899 / year' end
where code in ('max', 'max_yearly');

-- Extra people bought on a web subscription (a Dodo add-on), on top of the plan's seats.
alter table public.subscriptions add column if not exists extra_seats int not null default 0
  check (extra_seats >= 0);

-- The Dodo add-ons that sell an extra person, for monthly and yearly plans.
alter table public.billing_settings add column if not exists dodo_seat_addon_month text;
alter table public.billing_settings add column if not exists dodo_seat_addon_year text;

-- A workspace's limits: its plan's, plus what its subscription changes (extra people, a trial's
-- smaller allowance), with the owner's overrides on top. The server's recompute and the Admin
-- screen's saves both use this, so they can't disagree.
create or replace function public.entitlement_limits(p_plan text, p_subscription uuid, p_overrides jsonb)
returns jsonb
language sql stable set search_path = ''
as $$
  select p.limits
    || case when coalesce(s.extra_seats, 0) > 0 and jsonb_typeof(p.limits -> 'seats') = 'number'
         then jsonb_build_object('seats', (p.limits ->> 'seats')::numeric + s.extra_seats)
         else '{}'::jsonb end
    || case when s.status = 'trialing' and jsonb_typeof(p.limits -> 'trial_computer_hours') = 'number'
         then jsonb_build_object('computer_hours', p.limits -> 'trial_computer_hours')
         else '{}'::jsonb end
    || coalesce(p_overrides, '{}'::jsonb)
  from public.plans p
  left join public.subscriptions s on s.id = p_subscription
  where p.code = p_plan
$$;
revoke all on function public.entitlement_limits(text, uuid, jsonb) from public, anon, authenticated;

-- Workspaces keep their plan; refresh their copy of its limits.
update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';
