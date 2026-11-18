-- The island's server pushes (D-324, Phase 4; docs/ISLAND-AND-MENU-BAR-PLAN.md §6 F, §8.7).
--
-- A device that follows a run registers a live token for it: an iPhone Live Activity's own push
-- token, or an Android phone's push token. The worker and the API push the run's state to those
-- tokens while the app sleeps. The app writes rows itself, as it does voip_tokens: a person only
-- for themselves, and only for runs they can see. Safe to run twice (it was applied to local dev
-- stacks by hand while the branch was open).
create table if not exists public.run_live_tokens (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.runs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  token text not null check (char_length(token) between 8 and 4096),
  -- iPhone: the phone's own Firebase token, which Firebase needs beside the activity's (decision 8).
  fcm_token text check (char_length(fcm_token) between 8 and 4096),
  created_at timestamptz not null default now(),
  unique (run_id, token)
);

-- The sweep drops tokens once they are 12 hours old (iOS ends an activity after 8).
-- Stacks that applied the first draft of this file by hand.
alter table public.run_live_tokens add column if not exists fcm_token text
  check (char_length(fcm_token) between 8 and 4096);

create index if not exists run_live_tokens_created_idx on public.run_live_tokens (created_at);

alter table public.run_live_tokens enable row level security;
drop policy if exists run_live_tokens_own on public.run_live_tokens;
create policy run_live_tokens_own on public.run_live_tokens for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.runs r where r.id = run_id and public.can_access_bot(r.bot_id))
  );
select public.allow_worker('public.run_live_tokens');

-- The island asks for a workspace's unfinished runs every few seconds while a bot works
-- (client: SupabaseBackend.activeRuns). Only unfinished runs are indexed, so it stays small.
create index if not exists runs_unfinished_idx on public.runs (org_id, created_at desc)
  where status in ('queued', 'running', 'waiting_approval', 'waiting_takeover');
