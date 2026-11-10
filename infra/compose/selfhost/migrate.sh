#!/bin/sh
# One-shot: waits for Supabase Auth and Realtime to create their schemas, then applies Kasama's
# migrations in order, once each (tracked in kasama_migrations). Safe to re-run on upgrades.
set -eu
export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h db -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -qtA"
for i in $(seq 1 120); do
  # The Postgres image ships a minimal auth.users, so wait for objects only Supabase Auth's own
  # migrations create (the MFA tables and email_confirmed_at), not just the table.
  if $PSQL -c "select to_regclass('auth.mfa_factors') is not null and to_regclass('auth.flow_state') is not null
      and exists (select 1 from information_schema.columns where table_schema = 'auth' and table_name = 'users' and column_name = 'email_confirmed_at')
      and to_regclass('realtime.messages') is not null" 2>/dev/null | grep -q t; then break; fi
  [ "$i" = 120 ] && { echo "Auth/Realtime schemas did not appear"; exit 1; }
  sleep 2
done
$PSQL -c "create table if not exists public.kasama_migrations (name text primary key, applied_at timestamptz not null default now())"
for f in $(ls /migrations/*.sql | sort); do
  name=$(basename "$f")
  if [ -z "$($PSQL -c "select 1 from public.kasama_migrations where name = '$name'")" ]; then
    echo "applying $name"
    $PSQL -1 -f "$f"
    $PSQL -c "insert into public.kasama_migrations (name) values ('$name')"
  fi
done
# The worker's least-privilege role (D-095) logs in with its own password.
if [ -n "${WORKER_DB_PASSWORD:-}" ]; then
  $PSQL -c "alter role kasama_worker with login password '$WORKER_DB_PASSWORD'"
fi
echo "migrations up to date"
