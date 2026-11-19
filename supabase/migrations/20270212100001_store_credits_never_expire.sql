-- D-418: credits bought in the App Store or Google Play never lapse. Apple's guideline 3.1.1 says
-- credits bought with in-app purchase may not expire. Store packs are credited through RevenueCat
-- (D-297) with reason 'purchase' and reference 'revenuecat:<RevenueCat purchase id>', the same for
-- the App Store, the Mac App Store and Google Play. Packs bought on the web (Dodo, reference
-- 'dodo:<payment id>') keep their 12 months. Otherwise unchanged from 20270129000101.
create or replace function public.credit_lot_expiry(p_reason text, p_reference text)
returns timestamptz
language sql stable set search_path = ''
as $$
  select case
    when p_reason = 'grant' and p_reference like 'monthly:%'
      then date_trunc('month', now()) + interval '2 months'
    when p_reason = 'purchase' and p_reference like 'revenuecat:%' then null
    when p_reason in ('grant', 'purchase') then now() + interval '12 months'
    else null
  end;
$$;

-- Store packs bought before this change: their lots no longer lapse.
update public.credit_lots set expires_at = null
where reason = 'purchase' and reference like 'revenuecat:%' and expires_at is not null;
