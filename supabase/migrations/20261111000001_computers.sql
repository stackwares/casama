-- Phase 2: computers, control leases (used from Phase 5), checkpoints.

create table public.computers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null default 'team' check (kind in ('private', 'team', 'local')),
  owner_bot_id uuid references public.bots (id) on delete cascade,
  name text not null default 'Team computer',
  provider text not null default 'docker' check (provider in ('docker', 'e2b', 'daytona', 'local', 'casama-cloud')),
  provider_ref text,
  profile text not null default 'headless' check (profile in ('headless', 'desktop')),
  state text not null default 'stopped' check (state in ('provisioning', 'starting', 'running', 'idle', 'sleeping', 'stopped', 'error')),
  size jsonb not null default '{"cpus": 1, "memory_mb": 1024, "disk_gb": 10}'::jsonb,
  image_version text,
  last_active_at timestamptz,
  running_since timestamptz,
  -- latest sleep snapshot: {key, size, createdAt}
  snapshot_ref jsonb,
  error text,
  created_at timestamptz not null default now(),
  check ((kind = 'private') = (owner_bot_id is not null) or kind = 'local')
);
create index computers_org_idx on public.computers (org_id);
create index computers_state_idx on public.computers (state, last_active_at);
create unique index computers_one_team_per_org on public.computers (org_id) where kind = 'team';

-- bots.default_computer_id stays a plain uuid (validated by the API): a foreign key back to
-- computers would make bots and computers reference each other.

create table public.computer_leases (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  computer_id uuid not null references public.computers (id) on delete cascade,
  holder_type text not null check (holder_type in ('bot', 'user')),
  holder_id uuid not null,
  mode text not null check (mode in ('view', 'control')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index computer_leases_computer_idx on public.computer_leases (computer_id, expires_at);

create table public.checkpoints (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  computer_id uuid not null references public.computers (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  label text not null check (char_length(label) between 1 and 200),
  -- {key, size, createdAt} in object storage
  storage_ref jsonb not null,
  created_at timestamptz not null default now()
);
create index checkpoints_computer_idx on public.checkpoints (computer_id, created_at desc);

-- Computer access: team computers for any member; private computers follow their bot.
create or replace function public.can_access_computer(p_computer_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.computers c
    where c.id = p_computer_id
      and public.is_member(c.org_id)
      and (c.owner_bot_id is null or public.can_access_bot(c.owner_bot_id))
  );
$$;
grant execute on function public.can_access_computer(uuid) to authenticated;

alter table public.computers enable row level security;
alter table public.computer_leases enable row level security;
alter table public.checkpoints enable row level security;

-- Reads go through RLS; all changes go through the API and worker.
create policy computers_select on public.computers for select to authenticated
  using (public.is_member(org_id) and (owner_bot_id is null or public.can_access_bot(owner_bot_id)));
create policy computer_leases_select on public.computer_leases for select to authenticated
  using (public.can_access_computer(computer_id));
create policy checkpoints_select on public.checkpoints for select to authenticated
  using (public.can_access_computer(computer_id));

-- One team computer per organization, created with the organization.
create or replace function public.organizations_team_computer()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.computers (org_id, kind, name) values (new.id, 'team', 'Team computer')
  on conflict do nothing;
  return new;
end;
$$;
create trigger organizations_team_computer
after insert on public.organizations
for each row execute function public.organizations_team_computer();

insert into public.computers (org_id, kind, name)
select o.id, 'team', 'Team computer' from public.organizations o
where not exists (select 1 from public.computers c where c.org_id = o.id and c.kind = 'team');
