-- Calendar triggers (SPEC: Post-v1 roadmap → Calendar triggers; D-132): routines that run a set
-- time before or after calendar events. The worker checks connected calendars every 5 minutes and
-- keeps one fire per routine and event.
create table public.calendar_fires (
  routine_id uuid not null references public.routines (id) on delete cascade,
  event_id text not null check (char_length(event_id) between 1 and 500),
  org_id uuid not null references public.organizations (id) on delete cascade,
  fire_at timestamptz not null,
  event jsonb not null,
  fired_at timestamptz,
  run_id uuid,
  created_at timestamptz not null default now(),
  primary key (routine_id, event_id)
);
create index calendar_fires_due_idx on public.calendar_fires (fire_at) where fired_at is null;
alter table public.calendar_fires enable row level security;
select public.allow_worker('public.calendar_fires');

-- The domain of a person's email, for "has outside guests" (the worker never reads auth.* itself).
create or replace function public.worker_user_email_domain(p_user uuid)
returns text language sql stable security definer set search_path = '' as $$
  select lower(split_part(email, '@', 2)) from auth.users where id = p_user
$$;
revoke all on function public.worker_user_email_domain(uuid) from public, anon, authenticated;
grant execute on function public.worker_user_email_domain(uuid) to kasama_worker;
