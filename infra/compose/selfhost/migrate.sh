#!/bin/sh
# One-shot: waits for Supabase Auth and Realtime to create their schemas, then applies Kasama's
# migrations in order, once each (tracked in kasama_migrations). Safe to re-run on upgrades.
set -eu
export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h db -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -qtA"
for i in $(seq 1 120); do
  if $PSQL -c "select to_regclass('auth.users') is not null and to_regclass('realtime.messages') is not null" 2>/dev/null | grep -q t; then break; fi
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
echo "migrations up to date"
