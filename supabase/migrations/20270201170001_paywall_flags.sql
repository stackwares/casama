-- Paywall picks from the server (D-332): which plan the paywall opens on (its tier for a Free
-- workspace, its billing period for everyone) and which plans carry the "Most popular" badge.
-- Edited in Admin → Pricing, read by every app on its next paywall load, no release needed.

alter table public.plans add column paywall_default boolean not null default false;
alter table public.plans add column paywall_popular boolean not null default false;

-- At most one plan opens the paywall.
create unique index plans_one_paywall_default on public.plans (paywall_default) where paywall_default;

-- Today's picks: Plus monthly first (the smallest price up front), Pro badged.
update public.plans set paywall_default = true where code = 'plus';
update public.plans set paywall_popular = true where code in ('pro', 'pro_yearly');
