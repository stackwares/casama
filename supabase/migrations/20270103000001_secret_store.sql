-- Secret store (D-145): bots' named secrets ({{secret:NAME}}) live in Supabase Vault by default, or
-- in the workspace's own Infisical project.
alter table public.secrets add column store text not null default 'vault' check (store in ('vault', 'infisical'));

create table public.org_secret_stores (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  provider text not null default 'infisical' check (provider in ('infisical')),
  site_url text not null check (site_url ~ '^https?://'),
  project_id text not null check (char_length(project_id) between 1 and 100),
  environment text not null default 'prod' check (char_length(environment) between 1 and 64),
  secret_path text not null default '/' check (secret_path ~ '^/'),
  client_id text not null,
  vault_secret_id uuid not null,
  updated_at timestamptz not null default now()
);
alter table public.org_secret_stores enable row level security;
create policy org_secret_stores_select on public.org_secret_stores for select to authenticated using (public.has_role(org_id, 'admin'));
select public.allow_worker('public.org_secret_stores');
