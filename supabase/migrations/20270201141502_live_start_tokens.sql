-- Push-to-start for the island (D-324, Phase 6; decision 11): a run a person starts on another
-- device (their Mac, the web) appears on their phone without being asked for there.
--
-- A phone registers one start token: an iPhone's Live Activity push-to-start token (with the
-- phone's own Firebase token, which Firebase needs beside it), or an Android phone's push token.
-- When a person's run starts, the worker sends a start to their phones that aren't already
-- following it. The app writes its own rows, for itself only. Safe to run twice.
--
-- A shared phone follows whoever signed in on it last: the newest row for a token wins. So turning
-- the setting off keeps the row with `enabled = false` (still the newest) instead of deleting it,
-- which would hand the phone back to an earlier account; signing out deletes it.
create table if not exists public.live_start_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  token text not null check (char_length(token) between 8 and 4096),
  fcm_token text check (char_length(fcm_token) between 8 and 4096),
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);
alter table public.live_start_tokens add column if not exists enabled boolean not null default true;

alter table public.live_start_tokens enable row level security;
drop policy if exists live_start_tokens_own on public.live_start_tokens;
create policy live_start_tokens_own on public.live_start_tokens for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
select public.allow_worker('public.live_start_tokens');
