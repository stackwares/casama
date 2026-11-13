-- Routines that end (D-262): a repeating or event routine can stop at a date and time (ends_at)
-- or after a number of runs (max_runs). run_count counts the runs it started on its own
-- (manual "run now" doesn't count). The worker switches a routine off once either is reached.
alter table public.routines add column ends_at timestamptz;
alter table public.routines add column max_runs integer check (max_runs is null or max_runs between 1 and 10000);
alter table public.routines add column run_count integer not null default 0;

create index routines_ends_idx on public.routines (ends_at) where enabled and ends_at is not null;
