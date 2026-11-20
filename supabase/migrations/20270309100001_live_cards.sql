-- Live data cards (docs/RICH-CARDS-PLAN.md §4): weather, prices, rates, time, travel and more,
-- filled by the server from named providers and refreshed without the model.

-- A data card shown in a chat: the call to repeat and its latest filled card. The person refreshes
-- it with the session; args never come from the client.
create table if not exists public.live_cards (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  run_id uuid references public.runs (id) on delete cascade,
  -- The person the run acted for: personal cards (parcels, flights) are theirs alone.
  user_id uuid references auth.users (id) on delete cascade,
  personal boolean not null default false,
  card text not null check (char_length(card) between 1 and 40),
  tool text not null check (char_length(tool) between 1 and 60),
  args jsonb not null default '{}'::jsonb,
  data jsonb not null,
  fetched_at timestamptz not null default now(),
  -- Refresh limits: today's count and the day it counts.
  refreshes_day integer not null default 0,
  refresh_day date not null default current_date,
  -- Pinned to the person's widgets (§4.5): the canvas the worker keeps fresh.
  pinned_canvas_id uuid references public.widget_canvases (id) on delete set null,
  pinned_units jsonb,
  created_at timestamptz not null default now()
);
create index if not exists live_cards_run_idx on public.live_cards (run_id);
create index if not exists live_cards_pinned_idx on public.live_cards (pinned_canvas_id) where pinned_canvas_id is not null;
create index if not exists live_cards_org_idx on public.live_cards (org_id, created_at);

alter table public.live_cards enable row level security;
drop policy if exists live_cards_select on public.live_cards;
-- Whoever can read the run (its chat) can read and refresh its cards; personal ones only their person.
create policy live_cards_select on public.live_cards for select to authenticated
  using (
    public.is_member(org_id)
    and (not personal or user_id = (select auth.uid()))
    and (run_id is null or exists (select 1 from public.runs r where r.id = run_id))
  );
revoke all on public.live_cards from anon, authenticated;
grant select on public.live_cards to authenticated;
select public.allow_worker('public.live_cards');

-- The shared answer cache for public data (a weather grid point, a ticker, a currency pair). No
-- person or workspace in it.
create table if not exists public.live_data_cache (
  provider text not null,
  key text not null,
  payload jsonb not null,
  fetched_at timestamptz not null default now(),
  expires_at timestamptz not null,
  primary key (provider, key)
);
create index if not exists live_data_cache_expires_idx on public.live_data_cache (expires_at);
alter table public.live_data_cache enable row level security;
revoke all on public.live_data_cache from anon, authenticated;
select public.allow_worker('public.live_data_cache');

-- How much each provider is used, per day: upstream calls and cache hits.
create table if not exists public.live_data_daily (
  day date not null default current_date,
  provider text not null,
  calls integer not null default 0,
  cache_hits integer not null default 0,
  errors integer not null default 0,
  primary key (day, provider)
);
alter table public.live_data_daily enable row level security;
revoke all on public.live_data_daily from anon, authenticated;
select public.allow_worker('public.live_data_daily');

-- "Report wrong data" on a card: which card and provider, no words.
create table if not exists public.live_card_reports (
  id uuid primary key default gen_random_uuid(),
  live_card_id uuid references public.live_cards (id) on delete set null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete set null,
  card text not null,
  provider text,
  snapshot jsonb,
  created_at timestamptz not null default now()
);
alter table public.live_card_reports enable row level security;
revoke all on public.live_card_reports from anon, authenticated;
select public.allow_worker('public.live_card_reports');

-- A person's home place and units for cards (§4.6): a city, never a street.
alter table public.profiles add column if not exists home_place jsonb;
alter table public.profiles add column if not exists card_units jsonb;
