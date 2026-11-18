-- Computer updates on the person's terms (D-360): since when a running computer has been on an
-- older image than its profile's tag names now. Null: up to date, asleep, or not known (hosted
-- providers and personal computers). The worker sets and clears it every minute; any start clears it.
alter table public.computers add column update_available_since timestamptz;
