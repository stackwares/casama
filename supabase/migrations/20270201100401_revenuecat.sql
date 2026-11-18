-- App Store and Google Play purchases now come through RevenueCat (D-297). Its webhooks are logged
-- in billing_events under their own source. Subscriptions keep the store they were bought in
-- ('app_store' or 'google_play'), which is what people see and where they change plans.
alter table public.billing_events drop constraint billing_events_source_check;
alter table public.billing_events add constraint billing_events_source_check
  check (source in ('dodo', 'app_store', 'google_play', 'revenuecat'));
