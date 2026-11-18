#!/usr/bin/env bash
# Checks that the one-click templates parse: `docker compose config -q` on each compose file,
# with dummy values for every variable. It starts nothing and pulls nothing.
#   deploy/check-templates.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/casama-templates.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0
check() { # name, compose arguments...
  local name="$1"; shift
  if docker compose "$@" config -q 2>"$tmp/err"; then echo "ok    $name"; else echo "FAIL  $name"; cat "$tmp/err"; fail=1; fi
}

cat >"$tmp/secrets.env" <<'ENV'
POSTGRES_PASSWORD=dummy
WORKER_DB_PASSWORD=dummy
JWT_SECRET=dummydummydummydummydummydummy12
ANON_KEY=dummy.anon.key
SERVICE_ROLE_KEY=dummy.service.key
SECRET_KEY_BASE=dummy
REALTIME_ENC_KEY=dummydummydummy1
SUPERVISOR_TOKEN=dummydummydummy1
COMPUTER_TOKEN_SECRET=dummy
SAML_PRIVATE_KEY=dummy
EGRESS_CONTROL_TOKEN=dummy
INTERNAL_TOKEN=dummydummydummydummydummydummy12
TURN_SECRET=dummydummydummy1
METRICS_TOKEN=dummydummydummy1
AUTH_HOOK_SECRET=v1,whsec_ZHVtbXk=
CONTENT_ENCRYPTION_KEY=ZHVtbXk=
CASAMA_PUBLIC_URL=http://casama.example.com
CASAMA_PAGES_URL=http://pages.example.com
TURN_PUBLIC_HOST=casama.example.com
SIGNUP_HOOK_URI=
SANDBOX_RUNTIME=
COMPUTER_HOST_MEMORY_GB=4
CASAMA_VERSION=latest
CASAMA_DATA_DIR=/DATA/AppData/casama
CASAMA_HTTP_PORT=8480
CASAMA_PAGES_PORT=8790
ENV

# Coolify: its own keys (a volume's `content: |` block and `exclude_from_hc`) are not Compose, so
# they come out first. The SERVICE_* names are the values Coolify generates.
awk '
  BEGIN { skip = -1 }
  { match($0, /^ */); indent = RLENGTH }
  skip >= 0 { if ($0 ~ /^ *$/ || indent > skip) next; skip = -1 }
  /^ *exclude_from_hc:/ { next }
  /^ *content: \|$/ { skip = indent; next }
  { print }
' coolify/casama.yaml >"$tmp/coolify.yaml"
cat >"$tmp/coolify.env" <<'ENV'
SERVICE_URL_CADDY=https://casama.example.com
SERVICE_URL_CADDY_80=https://casama.example.com
SERVICE_FQDN_CADDY=casama.example.com
SERVICE_URL_API=https://pages.example.com
SERVICE_URL_API_8790=https://pages.example.com
SERVICE_PASSWORD_JWT=dummydummydummydummydummydummy12
SERVICE_SUPABASEANON_KEY=dummy.anon.key
SERVICE_SUPABASESERVICE_KEY=dummy.service.key
SERVICE_PASSWORD_POSTGRES=dummy
SERVICE_PASSWORD_WORKERDB=dummy
SERVICE_PASSWORD_64_REALTIME=dummy
SERVICE_USER_REALTIMEENC=dummydummydummy1
SERVICE_PASSWORD_SUPERVISOR=dummydummydummy1
SERVICE_PASSWORD_64_COMPUTERTOKEN=dummy
SERVICE_PASSWORD_EGRESS=dummy
SERVICE_PASSWORD_64_INTERNAL=dummydummydummydummydummydummy12
SERVICE_PASSWORD_TURN=dummydummydummy1
SERVICE_PASSWORD_METRICS=dummydummydummy1
SERVICE_REALBASE64_AUTHHOOK=ZHVtbXk=
SERVICE_REALBASE64_CONTENTKEY=ZHVtbXk=
ENV
check "coolify/casama.yaml (without Coolify's own keys)" -f "$tmp/coolify.yaml" --env-file "$tmp/coolify.env"
check "dokploy/docker-compose.yml" -p casama-check -f dokploy/docker-compose.yml --env-file "$tmp/secrets.env"
check "casaos/docker-compose.yml" -f casaos/docker-compose.yml --env-file "$tmp/secrets.env"

# No template may build an image.
for f in coolify/casama.yaml dokploy/docker-compose.yml casaos/docker-compose.yml; do
  if grep -qE '^\s+build:' "$f"; then echo "FAIL  $f has a build: section"; fail=1; fi
done
exit "$fail"
