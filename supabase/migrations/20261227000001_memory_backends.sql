-- Memory backends (SPEC: Memory backends; D-137): a workspace can keep bot memory in Honcho or
-- Supermemory with its own key instead of the built-in Postgres store.
create table public.org_memory_backends (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  provider text not null check (provider in ('honcho', 'supermemory')),
  vault_secret_id uuid not null,
  base_url text check (base_url is null or base_url ~ '^https?://'),
  workspace text check (workspace is null or char_length(workspace) between 1 and 100),
  created_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.org_memory_backends enable row level security;
create policy org_memory_backends_select on public.org_memory_backends for select to authenticated using (public.has_role(org_id, 'member'));
select public.allow_worker('public.org_memory_backends');
