-- Import an agent (SPEC: Post-v1 roadmap → Import an agent; D-122): an uploaded OpenClaw or Hermes
-- Agent folder, kept for a day so the files nothing maps to can be copied to the new bot's computer.
create table public.agent_imports (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('openclaw', 'hermes')),
  bot_id uuid references public.bots (id) on delete set null,
  files_written_at timestamptz,
  expires_at timestamptz not null default now() + interval '1 day',
  created_at timestamptz not null default now()
);
create table public.agent_import_files (
  import_id uuid not null references public.agent_imports (id) on delete cascade,
  path text not null check (char_length(path) between 1 and 1000),
  content bytea not null,
  primary key (import_id, path)
);
alter table public.agent_imports enable row level security;
alter table public.agent_import_files enable row level security;
create policy agent_imports_select on public.agent_imports for select to authenticated using (user_id = (select auth.uid()));
select public.allow_worker('public.agent_imports');
select public.allow_worker('public.agent_import_files');
