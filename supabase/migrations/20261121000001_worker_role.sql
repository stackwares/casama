-- Least-privilege database role for the worker and system jobs (D-016, D-095).
-- The worker acts for every workspace, so it reads and writes public tables through an explicit
-- policy for this role (it is not a superuser and does not bypass RLS). It cannot change the
-- schema, read other Supabase schemas, or see auth.users beyond a few columns. Deployments give it
-- a password and point WORKER_DATABASE_URL at it; without that the worker keeps DATABASE_URL.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'kasama_worker') then
    create role kasama_worker nologin noinherit;
  end if;
end $$;

-- DBOS runs `create schema if not exists dbos` at start, which needs CREATE on the database.
do $$ begin
  execute format('grant connect, create on database %I to kasama_worker', current_database());
end $$;
grant usage on schema public to kasama_worker;
grant select, insert, update, delete on all tables in schema public to kasama_worker;
grant usage, select on all sequences in schema public to kasama_worker;
grant execute on all functions in schema public to kasama_worker;
alter default privileges in schema public grant select, insert, update, delete on tables to kasama_worker;
alter default privileges in schema public grant usage, select on sequences to kasama_worker;
alter default privileges in schema public grant execute on functions to kasama_worker;

-- One policy per table for this role. New tables add theirs with public.allow_worker(table);
-- a test fails when a table with RLS lacks it.
create or replace function public.allow_worker(p_table regclass)
returns void
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = (select relname from pg_class where oid = p_table)
      and policyname = 'kasama_worker_all'
  ) then
    execute format('create policy kasama_worker_all on %s for all to kasama_worker using (true) with check (true)', p_table);
  end if;
end;
$$;
revoke execute on function public.allow_worker(regclass) from public, anon, authenticated;

do $$
declare t record;
begin
  for t in select c.oid::regclass as rel from pg_class c join pg_namespace n on n.oid = c.relnamespace
           where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity loop
    perform public.allow_worker(t.rel);
  end loop;
end $$;

-- Extensions (pgvector types and functions for memory search).
grant usage on schema extensions to kasama_worker;

-- Vault: read model keys and secrets, write refreshed tokens (never delete).
grant usage on schema vault to kasama_worker;
grant select on vault.decrypted_secrets to kasama_worker;
grant execute on function vault.create_secret(text, text, text) to kasama_worker;
grant execute on function vault.update_secret(uuid, text, text, text) to kasama_worker;

-- auth.users: only the columns system jobs need.
grant usage on schema auth to kasama_worker;
grant select (id, email, email_confirmed_at, created_at) on auth.users to kasama_worker;

-- DBOS keeps its system tables in its own schema, owned by the worker.
create schema if not exists dbos;
alter schema dbos owner to kasama_worker;
do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'dbos' loop
    execute format('alter table dbos.%I owner to kasama_worker', t.tablename);
  end loop;
end $$;
