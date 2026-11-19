-- Chat apps (D-413): where each run's answer goes. A thread kept one reply target, the one of the
-- newest message. For Discord that target is the command's own token: a second command in the
-- channel while the first was being answered took the first one's answer, and the first command
-- stayed on "thinking…". Each run now keeps the target that came with the message that started it.
-- Read and written by the server only, like channel_threads.
create table public.channel_run_replies (
  run_id uuid primary key references public.runs (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  reply jsonb not null,
  created_at timestamptz not null default now()
);
create index channel_run_replies_created_idx on public.channel_run_replies (created_at);

alter table public.channel_run_replies enable row level security;
select public.allow_worker('public.channel_run_replies');
