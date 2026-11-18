-- Kasama is now Casama (D-170). Earlier migrations already create the new names, so a fresh
-- database has nothing to do here; this renames what an existing database still calls kasama,
-- in place and without losing data. Every step checks first, so running it twice is harmless.

do $$
declare
  r record;
begin
  -- The worker role. Renaming keeps its password, grants and the policies that name it.
  if exists (select 1 from pg_roles where rolname = 'kasama_worker')
     and not exists (select 1 from pg_roles where rolname = 'casama_worker') then
    execute 'alter role kasama_worker rename to casama_worker';
  end if;

  -- Policies named after it. The Realtime broadcast policy keeps its old name on existing
  -- databases (only Realtime's admin may alter it; nothing refers to it by name).
  for r in
    select schemaname, tablename, policyname from pg_policies
    where policyname like 'kasama%' and schemaname <> 'realtime'
  loop
    execute format('alter policy %I on %I.%I rename to %I', r.policyname, r.schemaname,
      r.tablename, replace(r.policyname, 'kasama', 'casama'));
  end loop;

  -- Functions that send kasama_* notifications or read kasama.* settings: recreated with the
  -- new names (same signature, owner, security and body otherwise).
  for r in
    select p.oid
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private', 'billing', 'realtime')
      and p.prokind in ('f', 'p')
      and p.prosrc like '%kasama%'
  loop
    execute replace(replace(replace(pg_get_functiondef(r.oid),
      'com.kasama.', 'ai.casama.'), 'kasama', 'casama'), 'Kasama', 'Casama');
  end loop;
end
$$;

-- The hosted computer provider is now casama-cloud.
do $$
declare
  r record;
begin
  create temporary table casama_rename_checks on commit drop as
    select c.conrelid::regclass::text as tbl, c.conname, pg_get_constraintdef(c.oid) as def
    from pg_constraint c join pg_namespace n on n.oid = c.connamespace
    where n.nspname = 'public' and c.contype = 'c' and pg_get_constraintdef(c.oid) like '%kasama-cloud%';
  for r in select * from casama_rename_checks loop
    execute format('alter table %s drop constraint %I', r.tbl, r.conname);
  end loop;
  update public.computers set provider = 'casama-cloud' where provider = 'kasama-cloud';
  for r in select * from casama_rename_checks loop
    execute format('alter table %s add constraint %I %s', r.tbl, r.conname,
      replace(r.def, 'kasama-cloud', 'casama-cloud'));
  end loop;
end
$$;

-- Store product ids follow the new app id (ai.casama.app) and product names.
update public.plans
   set store_product_ids = replace(replace(store_product_ids::text,
         'com.kasama.', 'ai.casama.'), 'kasama_', 'casama_')::jsonb
 where store_product_ids::text like '%kasama%';
update public.credit_packs
   set store_product_ids = replace(replace(store_product_ids::text,
         'com.kasama.', 'ai.casama.'), 'kasama_', 'casama_')::jsonb
 where store_product_ids::text like '%kasama%';
