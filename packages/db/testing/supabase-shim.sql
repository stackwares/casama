-- Minimal Supabase compatibility layer for running migrations and RLS tests on plain Postgres
-- when Docker (and so `supabase start`) is not available. CI uses the real Supabase stack.
-- Mirrors: roles, auth schema essentials, auth.uid()/auth.jwt()/auth.role(), default grants.

create schema if not exists extensions;
create schema if not exists auth;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin noinherit bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticator') then create role authenticator login noinherit password 'authenticator'; end if;
end $$;
grant anon, authenticated, service_role to authenticator;

create table if not exists auth.users (
  instance_id uuid,
  id uuid primary key,
  aud varchar(255),
  role varchar(255),
  email varchar(255) unique,
  encrypted_password varchar(255),
  email_confirmed_at timestamptz,
  last_sign_in_at timestamptz,
  banned_until timestamptz,
  raw_app_meta_data jsonb default '{}'::jsonb,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Two-step sign-in factors (the columns the API touches; names unique per person, like Supabase).
create table if not exists auth.mfa_factors (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  friendly_name text,
  factor_type text not null default 'totp',
  status text not null default 'verified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists mfa_factors_user_friendly_name_unique on auth.mfa_factors (friendly_name, user_id)
  where trim(both from friendly_name) <> '';

create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;
create or replace function auth.uid() returns uuid language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;
create or replace function auth.role() returns text language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;

grant usage on schema auth, extensions, public to anon, authenticated, service_role;
grant execute on function auth.uid(), auth.jwt(), auth.role() to anon, authenticated, service_role;

-- Supabase grants table privileges broadly and relies on RLS; mirror that.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

-- Vault stand-in (no encryption: tests only). Real Supabase encrypts with pgsodium/libsodium.
create schema if not exists vault;
create table if not exists vault.secrets (
  id uuid primary key default gen_random_uuid(),
  name text unique,
  description text not null default '',
  secret text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create or replace function vault.create_secret(new_secret text, new_name text default null, new_description text default '')
returns uuid language sql as $$
  insert into vault.secrets (secret, name, description) values (new_secret, new_name, new_description) returning id
$$;
create or replace function vault.update_secret(secret_id uuid, new_secret text default null, new_name text default null, new_description text default null)
returns void language sql as $$
  update vault.secrets set secret = coalesce(new_secret, secret), name = coalesce(new_name, name),
    description = coalesce(new_description, description), updated_at = now() where id = secret_id
$$;
create or replace view vault.decrypted_secrets as
  select id, name, description, secret, secret as decrypted_secret, created_at, updated_at from vault.secrets;
revoke all on schema vault from anon, authenticated;

-- Realtime stand-in: broadcast messages land in realtime.messages, as in Supabase.
create schema if not exists realtime;
create table if not exists realtime.messages (
  id bigserial primary key,
  topic text not null,
  extension text not null,
  event text,
  payload jsonb,
  private boolean default true,
  inserted_at timestamptz not null default now()
);
create or replace function realtime.topic() returns text language sql stable as $$
  select nullif(current_setting('realtime.topic', true), '')
$$;
create or replace function realtime.send(payload jsonb, event text, topic text, private boolean default true)
returns void language sql as $$
  insert into realtime.messages (topic, extension, event, payload, private) values (topic, 'broadcast', event, payload, private)
$$;
alter table realtime.messages enable row level security;
grant usage on schema realtime to authenticated;
grant select on realtime.messages to authenticated;
grant execute on function realtime.topic() to authenticated;
