-- Device triggers (SPEC: Device triggers; D-151). Routines start when the person wakes up, arrives
-- at or leaves a named place, needs to leave for an event, finishes a workout, gets a notification
-- from a watched app, or turns Focus on or off. Named places are the only coordinates kept (the
-- person sets them); visits are stored as arrive and leave times, never a GPS trail.
create table public.device_places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  radius_m integer not null default 150 check (radius_m between 50 and 2000),
  created_at timestamptz not null default now()
);
create unique index device_places_name_idx on public.device_places (user_id, lower(name));

-- Events a device reported, so a retried upload never starts a routine twice (no locations here).
create table public.device_event_log (
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id text not null check (char_length(event_id) between 1 and 200),
  type text not null,
  received_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

alter table public.device_places enable row level security;
alter table public.device_event_log enable row level security;
create policy device_places_own on public.device_places for select to authenticated using (user_id = (select auth.uid()));
create policy device_event_log_own on public.device_event_log for select to authenticated using (user_id = (select auth.uid()));
select public.allow_worker('public.device_places');
select public.allow_worker('public.device_event_log');

-- "Where am I now" for leave-now: a one-off live read, answered and then cleared.
alter table public.device_requests drop constraint device_requests_action_check;
alter table public.device_requests add constraint device_requests_action_check
  check (action in ('read', 'calendar.create', 'reminders.create', 'locate'));

-- Travel times for leave-now use the workspace's own maps key.
alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal',
                      'brave_search', 'tavily', 'deepgram', 'elevenlabs', 'cartesia', 'fish_audio', 'chatgpt', 'treg',
                      'google_maps', 'mapbox'));
