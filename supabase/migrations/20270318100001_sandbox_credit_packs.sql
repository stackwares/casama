-- Bug hunt 2026-11-21: credit packs bought with a store sandbox account (TestFlight, App Review,
-- Play license testers) still credit the workspace on the production server, so App Review sees
-- purchases work, but they're marked here so reports can leave them out, and their credits lapse
-- 7 days after they arrive (the server sets the lot's expiry; real store packs never lapse, D-418).
alter table public.credit_ledger add column sandbox boolean not null default false;
