-- Price watches on Fares cards (docs/FLIGHT-SEARCH-PLAN.md §9, D-471): the worker checks a watched
-- route every 6 hours with free providers only and pushes the person when the price drops.

create table if not exists public.fare_watches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete set null,
  live_card_id uuid not null references public.live_cards (id) on delete cascade,
  -- "Manila → Tokyo · Mar 12–19", for the push and Settings → Cards.
  route text not null check (char_length(route) between 1 and 160),
  -- Push when the fare is at or under this; null means "a good drop" (10% under the last push).
  below numeric(14, 2) check (below is null or below > 0),
  currency text not null check (char_length(currency) between 3 and 3),
  first_price numeric(14, 2),
  last_price numeric(14, 2),
  last_checked_at timestamptz,
  pushed_price numeric(14, 2),
  pushed_at timestamptz,
  next_check_at timestamptz not null,
  -- The departure date or 60 days, whichever comes first.
  ends_at timestamptz not null,
  stopped_at timestamptz,
  -- 'person', 'ended', 'card_gone'.
  stopped_why text check (stopped_why is null or stopped_why in ('person', 'ended', 'card_gone')),
  created_at timestamptz not null default now()
);
create unique index if not exists fare_watches_one_active
  on public.fare_watches (live_card_id, user_id) where stopped_at is null;
create index if not exists fare_watches_due_idx
  on public.fare_watches (next_check_at) where stopped_at is null;
create index if not exists fare_watches_org_idx
  on public.fare_watches (org_id) where stopped_at is null;
create index if not exists fare_watches_user_idx on public.fare_watches (user_id, created_at);

alter table public.fare_watches enable row level security;
drop policy if exists fare_watches_select on public.fare_watches;
-- A watch is its person's own; the server starts, checks and stops them.
create policy fare_watches_select on public.fare_watches for select to authenticated
  using (user_id = (select auth.uid()) and public.is_member(org_id));
revoke all on public.fare_watches from anon, authenticated;
grant select on public.fare_watches to authenticated;
select public.allow_worker('public.fare_watches');
