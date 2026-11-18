-- Gallery reward rules (D-315 follow-up): rewards count only people who really use an item.
--
-- gallery_installs.qualified_at: the last time this (hashed) person used the item in a way that
-- counts toward contributor rewards: their email is confirmed, their account was at least 7 days
-- old, they didn't submit the item, and a run of theirs succeeded with it (or, for kinds no run
-- can point at, such as looks and plugins, a run of theirs succeeded after they first used it).
-- Still no user id or workspace id here, only the keyed hash.
alter table public.gallery_installs add column if not exists qualified_at timestamptz;
create index if not exists gallery_installs_qualified_idx on public.gallery_installs (qualified_at)
  where qualified_at is not null;

-- The rollup's count of those people in the last 14 days. active_14d stays the raw number shown
-- to people; rewards read qualified_14d.
alter table public.gallery_item_stats add column if not exists qualified_14d integer not null default 0;

-- Rewards are recorded when an item reaches a milestone and paid while the contributor is under
-- the monthly cap ($110 a calendar month, UTC). A row with paid_at null is due but held: the next
-- month pays it, or an owner reviews it. Rows from before this change were paid when granted.
alter table public.gallery_rewards add column if not exists paid_at timestamptz;
update public.gallery_rewards set paid_at = granted_at where paid_at is null;
create index if not exists gallery_rewards_unpaid_idx on public.gallery_rewards (granted_at)
  where paid_at is null;
create index if not exists gallery_rewards_paid_idx on public.gallery_rewards (user_id, paid_at)
  where paid_at is not null;

-- RLS stays on with no client grants: these tables are read and written by the server only.
alter table public.gallery_installs enable row level security;
alter table public.gallery_item_stats enable row level security;
alter table public.gallery_rewards enable row level security;
