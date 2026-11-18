-- Phase 5: live view, control leases and takeover requests.

-- A lease is active while released_at is null and expires_at is in the future. The app renews
-- a user lease while the user is giving input; 15 minutes without input lets it lapse.
alter table public.computer_leases add column note text check (char_length(note) <= 2000);
alter table public.computer_leases add column released_at timestamptz;
-- Whether the bot may keep using shell and file tools while a person has control.
alter table public.computer_leases add column allow_shell boolean not null default false;
create index computer_leases_active_idx on public.computer_leases (computer_id) where released_at is null;

-- The computer a paused run waits on (user in control or a takeover request).
alter table public.runs add column waiting_computer_id uuid references public.computers (id) on delete set null;
create index runs_waiting_computer_idx on public.runs (waiting_computer_id) where waiting_computer_id is not null;

-- A bot asking a person to take over the screen (request_takeover).
create table public.takeover_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid not null references public.runs (id) on delete cascade,
  computer_id uuid not null references public.computers (id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 1000),
  status text not null default 'pending' check (status in ('pending', 'taken', 'completed', 'dismissed', 'expired')),
  note text check (char_length(note) <= 2000),
  resolved_by uuid references auth.users (id) on delete set null,
  resolved_at timestamptz,
  expires_at timestamptz not null default now() + interval '24 hours',
  created_at timestamptz not null default now()
);
create index takeover_requests_computer_idx on public.takeover_requests (computer_id, status);
create index takeover_requests_run_idx on public.takeover_requests (run_id);

alter table public.takeover_requests enable row level security;
create policy takeover_requests_select on public.takeover_requests for select to authenticated
  using (public.can_access_bot(bot_id));
-- Changes go through the API and worker.
