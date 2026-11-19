-- One run at a time drives a computer's screen: its browser and its desktop (D-413). A bot has one
-- computer and one browser on it, and nothing kept two of its runs (two topics, a routine beside a
-- chat) from using it at the same moment: one run's click landed on the other's page. On a team
-- computer the same happened between bots, since only desktop tools took a lease (D-148).
-- The run that uses the screen holds this row; it is renewed with each use, given back when the
-- run ends, and free again two minutes after the last use. Read and written by the server only.
create table public.computer_screen_leases (
  computer_id uuid primary key references public.computers (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid not null,
  expires_at timestamptz not null
);
create index computer_screen_leases_run_idx on public.computer_screen_leases (run_id);

alter table public.computer_screen_leases enable row level security;
select public.allow_worker('public.computer_screen_leases');
