-- Check-ins (SPEC: Post-v1 roadmap → Check-ins; D-114): an opt-in morning brief and periodic scans
-- per bot, run as routines on the bot's cheaper model with a daily cap. Scans leave suggestions;
-- the app's "For you" feed shows the latest brief, pending suggestions and approvals.

alter table public.routines add column kind text not null default 'task' check (kind in ('task', 'brief', 'scan'));

create table public.bot_checkins (
  bot_id uuid primary key references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  enabled boolean not null default false,
  brief_time text not null default '08:00' check (brief_time ~ '^([01]\d|2[0-3]):[0-5]\d$'),
  scan_every_hours integer not null default 3 check (scan_every_hours between 1 and 24),
  daily_cap_usd numeric(8, 2) not null default 1 check (daily_cap_usd > 0),
  updated_at timestamptz not null default now()
);
alter table public.bot_checkins enable row level security;
create policy bot_checkins_select on public.bot_checkins for select to authenticated using (public.can_access_bot(bot_id));
select public.allow_worker('public.bot_checkins');

create table public.suggestions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  title text not null check (char_length(title) between 1 and 200),
  body_md text not null default '' check (char_length(body_md) <= 5000),
  -- {tool, args} the bot would run when accepted; null for "just look at this"
  proposed_action jsonb,
  sources jsonb not null default '[]'::jsonb,
  urgency text not null default 'normal' check (urgency in ('low', 'normal', 'urgent')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'dismissed', 'expired')),
  expires_at timestamptz not null default now() + interval '3 days',
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);
create index suggestions_user_idx on public.suggestions (user_id, org_id, status, created_at desc);
alter table public.suggestions enable row level security;
-- Suggestions are for one person.
create policy suggestions_select on public.suggestions for select to authenticated using (user_id = (select auth.uid()));
select public.allow_worker('public.suggestions');
