-- Least-privilege database role for the worker and system jobs (D-016, D-095).
-- The worker acts for every workspace, so it reads and writes public tables through an explicit
-- policy for this role (it is not a superuser and does not bypass RLS). It cannot change the
-- schema, read other Supabase schemas, or see auth.users at all. Deployments give it
-- a password and point WORKER_DATABASE_URL at it; without that the worker keeps DATABASE_URL.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'casama_worker') then
    create role casama_worker nologin noinherit;
  end if;
  -- Postgres 16+: handing objects to the role (below) needs SET ROLE on it when not a superuser.
  if not (select rolsuper from pg_roles where rolname = current_user) then
    execute format('grant casama_worker to %I with inherit false, set true', current_user);
  end if;
end $$;

-- DBOS runs `create schema if not exists dbos` at start, which needs CREATE on the database.
do $$ begin
  execute format('grant connect, create on database %I to casama_worker', current_database());
end $$;
grant usage on schema public to casama_worker;
grant select, insert, update, delete on all tables in schema public to casama_worker;
grant usage, select on all sequences in schema public to casama_worker;
grant execute on all functions in schema public to casama_worker;
alter default privileges in schema public grant select, insert, update, delete on tables to casama_worker;
alter default privileges in schema public grant usage, select on sequences to casama_worker;
alter default privileges in schema public grant execute on functions to casama_worker;

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
      and policyname = 'casama_worker_all'
  ) then
    execute format('create policy casama_worker_all on %s for all to casama_worker using (true) with check (true)', p_table);
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
grant usage on schema extensions to casama_worker;

-- Vault: read model keys and secrets, write refreshed tokens (never delete).
grant usage on schema vault to casama_worker;
grant select on vault.decrypted_secrets to casama_worker;
-- By name: the argument lists differ between Vault versions (newer ones add a key id).
do $$
declare f regprocedure;
begin
  for f in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'vault' and p.proname in ('create_secret', 'update_secret') loop
    execute format('grant execute on function %s to casama_worker', f);
  end loop;
end $$;

-- auth.users: never directly; see public.worker_* functions (20261125000002).

-- DBOS keeps its system tables in its own schema, owned by the worker.
create schema if not exists dbos;
alter schema dbos owner to casama_worker;
do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'dbos' loop
    execute format('alter table dbos.%I owner to casama_worker', t.tablename);
  end loop;
end $$;
