-- Audit 2026-11: on the Supabase Postgres image the self-host stack runs (17.11), reading
-- vault.decrypted_secrets also needs EXECUTE on Vault's crypto functions, which the worker's role
-- (D-095) didn't have: every run that loads secrets failed on a fresh self-hosted install. The local
-- Supabase CLI image allowed it implicitly, so tests passed. Skipped where the migration role may not
-- grant (local runs as `postgres`), applied where it can (self-host runs as `supabase_admin`).
do $$
declare f regprocedure;
begin
  for f in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'vault' and p.proname like '\_crypto\_aead\_%' loop
    begin
      execute format('grant execute on function %s to kasama_worker', f);
    exception when insufficient_privilege then
      raise notice 'skipped granting % (insufficient privilege)', f;
    end;
  end loop;
end $$;
