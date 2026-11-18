-- Coding agents as data (D-370, D-371).

-- One Allow per computer (D-370): catalog agents beyond the built-in five that the device's owner
-- allowed on this computer. The built-in five keep working whenever commands are on.
alter table public.local_devices
  add column allowed_coding_agents text[] not null default '{}'
    check (cardinality(allowed_coding_agents) <= 100);

-- People's own agents (D-371): one person, one computer. Never workspace-wide: only the device's
-- owner reads or writes them, admins included, so nobody can put a command on someone else's
-- computer. Bots reach them through coding.delegate in runs acting for that person.
create table public.own_coding_agents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id uuid not null references public.local_devices (id) on delete cascade,
  key text not null check (key ~ '^[a-z][a-z0-9_]{0,23}$'),
  label text not null check (char_length(label) between 1 and 40),
  bin text not null check (bin ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'),
  command text not null check (char_length(command) between 1 and 1000),
  result text not null check (
    result ~ '^(json_result|marker|stream_json|tail|json_field:[A-Za-z_][A-Za-z0-9_]{0,31})$'
  ),
  timeout_min integer not null default 30 check (timeout_min between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (device_id, key)
);
create index own_coding_agents_user_idx on public.own_coding_agents (org_id, user_id);
alter table public.own_coding_agents enable row level security;

-- Whether the signed-in person owns this device in this workspace.
create or replace function public.owns_local_device(p_device uuid, p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.local_devices d
    where d.id = p_device and d.org_id = p_org and d.user_id = (select auth.uid())
  );
$$;
revoke execute on function public.owns_local_device(uuid, uuid) from public, anon;
grant execute on function public.owns_local_device(uuid, uuid) to authenticated;

create policy own_coding_agents_select on public.own_coding_agents for select to authenticated
  using (user_id = (select auth.uid()) and public.owns_local_device(device_id, org_id));
create policy own_coding_agents_insert on public.own_coding_agents for insert to authenticated
  with check (user_id = (select auth.uid()) and public.owns_local_device(device_id, org_id));
create policy own_coding_agents_update on public.own_coding_agents for update to authenticated
  using (user_id = (select auth.uid()) and public.owns_local_device(device_id, org_id))
  with check (user_id = (select auth.uid()) and public.owns_local_device(device_id, org_id));
create policy own_coding_agents_delete on public.own_coding_agents for delete to authenticated
  using (user_id = (select auth.uid()) and public.owns_local_device(device_id, org_id));
grant select, insert, update, delete on public.own_coding_agents to authenticated;
select public.allow_worker('public.own_coding_agents');
