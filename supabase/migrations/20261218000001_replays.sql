-- Step replay (SPEC: Post-v1 roadmap → Step replay; D-127): recorded browser and desktop actions
-- with element targets, parameters and checks, run without the model. A replay run hands over to
-- the model at the step that failed.
create table public.replays (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  name text not null check (name ~ '^[a-z0-9][a-z0-9_-]{0,62}$'),
  description text not null default '' check (char_length(description) <= 300),
  -- [{name, description?, default?, secret?}]
  params jsonb not null default '[]'::jsonb,
  -- [{tool, args, target?: {role?, name}, check?: {url_contains?, text_contains?}, host?, note?}]
  steps jsonb not null,
  source text not null default 'bot' check (source in ('bot', 'teach', 'manual')),
  source_id uuid,
  runs integer not null default 0,
  failures integer not null default 0,
  last_failure text,
  last_run_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bot_id, name)
);
alter table public.runs add column replay jsonb;
alter table public.replays enable row level security;
create policy replays_select on public.replays for select to authenticated using (public.can_access_bot(bot_id));
create policy replays_delete on public.replays for delete to authenticated using (public.can_manage_bot(bot_id));
select public.allow_worker('public.replays');
