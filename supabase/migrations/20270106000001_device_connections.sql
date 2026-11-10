-- Device connections (SPEC: Device connections; D-149). Phones and the desktop app upload
-- summaries of data the user turns on (calendar, reminders, contacts, places, photos, health,
-- notifications, activity). The data belongs to the person, not the workspace: only they see it,
-- and only runs acting for them, by bots they allowed per kind, read it.
create table public.device_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- A random id the app keeps for this install.
  device_key text not null check (device_key ~ '^[A-Za-z0-9_-]{8,100}$'),
  name text not null default 'Device' check (char_length(name) between 1 and 80),
  platform text not null check (platform in ('ios', 'android', 'macos', 'windows', 'linux', 'web')),
  -- The kinds turned on, each with its settings: {"calendar": {"retention_days": 365, "private_model": false}}.
  kinds jsonb not null default '{}'::jsonb check (jsonb_typeof(kinds) = 'object'),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, device_key)
);

create table public.device_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  source_id uuid not null references public.device_sources (id) on delete cascade,
  kind text not null check (kind in ('calendar', 'reminders', 'contacts', 'places', 'photos', 'health', 'notifications', 'activity')),
  period_start timestamptz not null,
  period_end timestamptz not null check (period_end >= period_start),
  -- What the reading stands for on the device (a day, a visit, an item), so re-uploads replace it.
  external_id text not null check (char_length(external_id) between 1 and 200),
  summary jsonb not null,
  collected_at timestamptz not null default now(),
  unique (source_id, kind, external_id)
);
create index device_readings_user_kind_idx on public.device_readings (user_id, kind, period_start desc);

create table public.device_grants (
  user_id uuid not null references auth.users (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  kind text not null check (kind in ('calendar', 'reminders', 'contacts', 'places', 'photos', 'health', 'notifications', 'activity')),
  created_at timestamptz not null default now(),
  primary key (user_id, bot_id, kind)
);

-- Work a device does for a run: a fresh read, or writing a calendar event or reminder.
create table public.device_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  source_id uuid not null references public.device_sources (id) on delete cascade,
  kind text not null,
  action text not null check (action in ('read', 'calendar.create', 'reminders.create')),
  params jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'done', 'failed', 'expired')),
  result jsonb,
  run_id uuid,
  created_at timestamptz not null default now(),
  answered_at timestamptz
);
create index device_requests_pending_idx on public.device_requests (source_id, created_at) where status = 'pending';

alter table public.device_sources enable row level security;
alter table public.device_readings enable row level security;
alter table public.device_grants enable row level security;
alter table public.device_requests enable row level security;
create policy device_sources_own on public.device_sources for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy device_readings_own on public.device_readings for select to authenticated using (user_id = (select auth.uid()));
create policy device_readings_delete on public.device_readings for delete to authenticated using (user_id = (select auth.uid()));
create policy device_grants_own on public.device_grants for select to authenticated using (user_id = (select auth.uid()));
create policy device_grants_delete on public.device_grants for delete to authenticated using (user_id = (select auth.uid()));
create policy device_requests_own on public.device_requests for select to authenticated using (user_id = (select auth.uid()));
select public.allow_worker('public.device_sources');
select public.allow_worker('public.device_readings');
select public.allow_worker('public.device_grants');
select public.allow_worker('public.device_requests');

-- The app hears about new requests at once on its private topic.
create or replace function public.device_requests_broadcast()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('id', new.id, 'source_id', new.source_id, 'kind', new.kind, 'action', new.action),
    'device_request', 'user:' || new.user_id::text, true);
  return null;
end;
$$;
create trigger device_requests_broadcast after insert on public.device_requests
for each row execute function public.device_requests_broadcast();
