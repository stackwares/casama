-- Password managers (SPEC: Post-v1 roadmap → Password managers; D-128): 1Password or Bitwarden,
-- for the whole workspace or one person, with the vaults or collections bots may use. The token
-- lives in Vault; the model only ever sees [login:Name].
create table public.password_managers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  -- null: the whole workspace; set: only runs acting for this person
  user_id uuid references auth.users (id) on delete cascade,
  provider text not null check (provider in ('1password', 'bitwarden')),
  name text not null check (char_length(name) between 1 and 100),
  url text not null check (char_length(url) between 1 and 500),
  vault_secret_id uuid,
  allowed_vaults text[] not null default '{}',
  allowed_bot_ids uuid[],
  status text not null default 'ok' check (status in ('ok', 'error')),
  last_error text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.password_managers enable row level security;
create policy password_managers_select on public.password_managers for select to authenticated
  using (public.is_member(org_id) and (user_id is null or user_id = (select auth.uid())));
create policy password_managers_delete on public.password_managers for delete to authenticated
  using ((user_id is null and public.has_role(org_id, 'admin')) or user_id = (select auth.uid()));
select public.allow_worker('public.password_managers');
