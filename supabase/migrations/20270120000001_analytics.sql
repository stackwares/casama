-- Analytics opt out and milestones (D-208, ANALYTICS-PLAN §4.3, §5.1)
-- Profile opt-out flag: when true, server and app omit product analytics events and daily rollups.
alter table public.profiles
  add column if not exists analytics_opt_out boolean not null default false,
  add column if not exists analytics_signup_sent_at timestamptz;

-- Milestones reached per user (once-only activation markers).
create table if not exists public.analytics_milestones (
  user_id uuid not null references auth.users (id) on delete cascade,
  milestone text not null,
  reached_at timestamptz not null default now(),
  primary key (user_id, milestone)
);

create index if not exists analytics_milestones_user_id_idx on public.analytics_milestones (user_id);
alter table public.analytics_milestones enable row level security;

-- Only service role and worker can write/read milestones.
select public.allow_worker('public.analytics_milestones');
