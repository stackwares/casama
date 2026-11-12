#!/usr/bin/env bash
# Casama self-host installer (SPEC "Self-host"). Checks Docker, generates every secret with
# OpenSSL, writes infra/compose/.env, builds the images and starts the stack. Re-running keeps the
# existing .env (and so all data and keys); use it to upgrade after `git pull`.
#
#   ./install.sh --domain casama.example.com     # public server with automatic HTTPS
#   ./install.sh --local [--http-port 8080]      # this machine only, plain HTTP
# Other options: --with-desktop (also build the desktop computer image, slower), --no-start,
#   --monitoring (Prometheus and Grafana), --web (the web app; needs a Flutter build image),
#   --search (SearXNG: free web search for bots without a Brave or Tavily key).
# Published images (D-197): --pull [tag] uses ghcr.io/stackwares/casama images instead of building
#   them (tag defaults to latest); re-running then upgrades by pulling.
# Behind a tunnel or another proxy: --behind-proxy --domain api.example.com serves plain HTTP on
#   --http-port while the public address stays https://<domain>; live view then needs
#   --turn-host <name or IP> that reaches this machine directly (UDP and TCP 3478).
# Also: --admin-email <a@b,c@d> (instance admins), --settings <file> (KEY=VALUE lines merged into
#   the .env, e.g. deploy/casama-cloud/settings.env), --backups (daily off-site backups; set the
#   BACKUP_* settings, see docs-site/self-hosting/operations.md).
set -euo pipefail

cd "$(dirname "$0")"
COMPOSE_DIR=infra/compose
ENV_FILE="$COMPOSE_DIR/.env"
REGISTRY=ghcr.io/stackwares/casama
domain="" local=0 http_port=80 desktop=0 start=1 search=0 profiles=()
pull="" behind_proxy=0 turn_host_opt="" admin_email="" settings_file="" backups=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) domain="$2"; shift 2 ;;
    --local) local=1; shift ;;
    --http-port) http_port="$2"; shift 2 ;;
    --with-desktop) desktop=1; shift ;;
    --no-start) start=0; shift ;;
    --monitoring) profiles+=(--profile monitoring); shift ;;
    --web) profiles+=(--profile web); shift ;;
    --search) profiles+=(--profile search); search=1; shift ;;
    --pull)
      if [[ $# -gt 1 && "$2" != --* ]]; then pull="$2"; shift 2; else pull=latest; shift; fi ;;
    --behind-proxy) behind_proxy=1; shift ;;
    --turn-host) turn_host_opt="$2"; shift 2 ;;
    --admin-email) admin_email="$2"; shift 2 ;;
    --settings) settings_file="$2"; shift 2 ;;
    --backups) backups=1; shift ;;
    -h | --help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }
[[ "$behind_proxy" -eq 1 && -z "$domain" && ! -f "$ENV_FILE" ]] && die "--behind-proxy needs --domain (the public name the proxy serves)"

# ---------------------------------------------------------------- checks
command -v docker >/dev/null || die "Docker is not installed. See https://docs.docker.com/engine/install/"
docker info >/dev/null 2>&1 || die "Docker is not running (or this user cannot use it)."
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is needed (docker compose)."
command -v openssl >/dev/null || die "OpenSSL is needed to generate secrets."
mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
if [[ "$mem_kb" -gt 0 && "$mem_kb" -lt 7000000 ]]; then
  echo "Warning: less than 8 GB of memory; computers may not start reliably."
fi
if [[ "$(uname -s)" == "Linux" ]] && docker info 2>/dev/null | grep -q runsc; then
  runtime=runsc
else
  runtime=""
  [[ "$(uname -s)" == "Linux" ]] && echo "Note: gVisor (runsc) not found; computers use runc. See docs-site/self-hosting/computers.md."
fi

# ---------------------------------------------------------------- secrets and .env
rand() { openssl rand -hex "$1"; }
# Supabase Auth signs SAML requests with an RSA key (base64 DER, one line).
# GoTrue wants PKCS#1 ("RSA PRIVATE KEY"); OpenSSL 3+ writes PKCS#8 unless told -traditional
# (LibreSSL, macOS's default, has no such flag and already writes PKCS#1).
rsa_trad() { openssl rsa -help 2>&1 | grep -q -- '-traditional' && echo "-traditional"; }
saml_key() { openssl genrsa 2048 2>/dev/null | openssl rsa $(rsa_trad) -outform DER 2>/dev/null | openssl base64 -A; }
# Re-encodes a stored key as PKCS#1 (fixes keys written by older installers in PKCS#8).
saml_fix() { printf '%s' "$1" | openssl base64 -d -A 2>/dev/null | openssl rsa $(rsa_trad) -inform DER -outform DER 2>/dev/null | openssl base64 -A; }
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
jwt() { # role secret
  local now exp header payload sig
  now=$(date +%s); exp=$((now + 10 * 365 * 24 * 3600))
  header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
  payload=$(printf '{"role":"%s","iss":"supabase","iat":%s,"exp":%s}' "$1" "$now" "$exp" | b64url)
  sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$2" -binary | b64url)
  printf '%s.%s.%s' "$header" "$payload" "$sig"
}

if [[ -f "$ENV_FILE" ]]; then
  say "Keeping the existing $ENV_FILE"
  # Settings added by newer releases get generated values; nothing existing is changed.
  grep -q "^COMPUTER_TOKEN_SECRET=" "$ENV_FILE" || echo "COMPUTER_TOKEN_SECRET=$(rand 32)" >>"$ENV_FILE"
  # Supabase Auth only takes https hook URLs: older installs used http://api:8787 (D-145 fix).
  if ! grep -q "^SIGNUP_HOOK_URI=" "$ENV_FILE"; then
    pub=$(grep '^CASAMA_PUBLIC_URL=' "$ENV_FILE" | cut -d= -f2-)
    echo "SIGNUP_HOOK_URI=$([[ "$pub" == https://* ]] && echo "$pub/hooks/auth/before-user-created")" >>"$ENV_FILE"
  fi
  if grep -q "^SAML_PRIVATE_KEY=" "$ENV_FILE"; then
    old_key=$(grep '^SAML_PRIVATE_KEY=' "$ENV_FILE" | head -n1 | cut -d= -f2-)
    new_key=$(saml_fix "$old_key")
    if [[ -n "$new_key" && "$new_key" != "$old_key" ]]; then
      grep -v '^SAML_PRIVATE_KEY=' "$ENV_FILE" >"$ENV_FILE.tmp" && echo "SAML_PRIVATE_KEY=$new_key" >>"$ENV_FILE.tmp" && mv "$ENV_FILE.tmp" "$ENV_FILE"
      chmod 600 "$ENV_FILE"
      say "Converted the SAML signing key to the format Supabase Auth expects"
    fi
  else
    echo "SAML_PRIVATE_KEY=$(saml_key)" >>"$ENV_FILE"
  fi
  grep -q "^WORKER_DB_PASSWORD=" "$ENV_FILE" || echo "WORKER_DB_PASSWORD=$(rand 24)" >>"$ENV_FILE"
  if ! grep -q "^APPLE_AUTH_ENABLED=" "$ENV_FILE"; then
    cat >>"$ENV_FILE" <<'EOF'

# Continue with Apple and Google. Off until set. See docs-site/self-hosting/configuration.md.
APPLE_AUTH_ENABLED=false
APPLE_AUTH_CLIENT_IDS=
APPLE_AUTH_SECRET=
GOOGLE_AUTH_ENABLED=false
GOOGLE_AUTH_CLIENT_ID=
GOOGLE_AUTH_SECRET=
EOF
  fi
  if ! grep -q "^PASSKEYS_ENABLED=" "$ENV_FILE"; then
    cat >>"$ENV_FILE" <<'EOF'

# Passkeys. Off until set. RP id is the domain without https://. Origins are the web app addresses.
PASSKEYS_ENABLED=false
PASSKEY_RP_ID=
PASSKEY_RP_ORIGINS=
EOF
  fi
else
  if [[ -z "$domain" && "$local" -eq 0 ]]; then
    if [[ -t 0 ]]; then
      read -r -p "Domain for this server (empty = local trial on this machine): " domain
    fi
    [[ -z "$domain" ]] && local=1
  fi
  if [[ "$local" -eq 1 ]]; then
    site=":80"
    public="http://localhost$([[ "$http_port" == 80 ]] || echo ":$http_port")"
    turn_host=localhost
  elif [[ "$behind_proxy" -eq 1 ]]; then
    # TLS ends at the proxy or tunnel; Caddy serves plain HTTP on HTTP_PORT.
    site=":80"
    public="https://$domain"
    turn_host="${turn_host_opt:-$domain}"
  else
    site="$domain"
    public="https://$domain"
    turn_host="$domain"
  fi
  say "Generating secrets"
  jwt_secret=$(rand 32)
  umask 077
  cat >"$ENV_FILE" <<EOF
# Casama self-host settings, generated by install.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ).
# Keep this file private and backed up: it holds every key for this installation.
CASAMA_SITE=$site
CASAMA_PUBLIC_URL=$public
SIGNUP_HOOK_URI=$([[ "$public" == https://* ]] && echo "$public/hooks/auth/before-user-created")
HTTP_PORT=$http_port
HTTPS_PORT=443
TURN_PUBLIC_HOST=$turn_host

POSTGRES_PASSWORD=$(rand 24)
WORKER_DB_PASSWORD=$(rand 24)
JWT_SECRET=$jwt_secret
ANON_KEY=$(jwt anon "$jwt_secret")
SERVICE_ROLE_KEY=$(jwt service_role "$jwt_secret")
SECRET_KEY_BASE=$(rand 32)
REALTIME_ENC_KEY=$(rand 8)

SUPERVISOR_TOKEN=$(rand 24)
COMPUTER_TOKEN_SECRET=$(rand 32)
SAML_PRIVATE_KEY=$(saml_key)
EGRESS_CONTROL_TOKEN=$(rand 24)
INTERNAL_TOKEN=$(rand 24)
TURN_SECRET=$(rand 24)
SEARXNG_SECRET=$(rand 32)
METRICS_TOKEN=$(rand 24)
GRAFANA_ADMIN_PASSWORD=$(rand 12)
SANDBOX_RUNTIME=$runtime

# Optional (see docs-site/self-hosting/configuration.md): email, error reporting, telemetry, Cloud Connect.
# Continue with Apple and Google. Off until set.
APPLE_AUTH_ENABLED=false
APPLE_AUTH_CLIENT_IDS=
APPLE_AUTH_SECRET=
GOOGLE_AUTH_ENABLED=false
GOOGLE_AUTH_CLIENT_ID=
GOOGLE_AUTH_SECRET=
# Passkeys. Off until set. RP id is the domain without https://. Origins are the web app addresses.
PASSKEYS_ENABLED=false
PASSKEY_RP_ID=
PASSKEY_RP_ORIGINS=
EMAIL_AUTOCONFIRM=true
INSTANCE_ADMIN_EMAILS=
RESEND_API_KEY=
SMTP_HOST=
TELEMETRY=off
CASAMA_CLOUD_URL=
CASAMA_CLOUD_KEY=
EOF
  say "Wrote $ENV_FILE"
fi

# Sets KEY=VALUE in the .env, replacing an existing line (values are written verbatim).
set_env() {
  local tmp="$ENV_FILE.tmp"
  { grep -v "^$1=" "$ENV_FILE" || true; printf '%s=%s\n' "$1" "$2"; } >"$tmp"
  chmod 600 "$tmp" && mv "$tmp" "$ENV_FILE"
}
env_value() { grep "^$1=" "$ENV_FILE" 2>/dev/null | tail -n1 | cut -d= -f2- || true; }

# Sign-up hook secret (Standard Webhooks, D-094): the same value on Auth and the API.
[[ -n "$(env_value AUTH_HOOK_SECRET)" ]] || set_env AUTH_HOOK_SECRET "v1,whsec_$(openssl rand -base64 32 | tr -d '\n')"
# Server key for encryption at rest (D-136), so workspace owners can turn it on. Without it the
# switch stays unavailable. Never replaced once set (losing it makes encrypted data unreadable),
# and skipped when AWS KMS wraps the keys instead.
if [[ -z "$(env_value CONTENT_ENCRYPTION_KEY)" && -z "$(env_value CONTENT_KMS_KEY_ID)" ]]; then
  set_env CONTENT_ENCRYPTION_KEY "$(openssl rand -base64 32 | tr -d '\n')"
  say "Generated CONTENT_ENCRYPTION_KEY: back it up with $ENV_FILE, encrypted data can't be read without it"
fi
[[ -n "$turn_host_opt" ]] && set_env TURN_PUBLIC_HOST "$turn_host_opt"
# Behind a tunnel or proxy on this machine, Caddy listens on loopback only: Docker's published
# ports skip ufw, so 0.0.0.0 would serve plain HTTP to the internet.
[[ "$behind_proxy" -eq 1 ]] && set_env HTTP_BIND 127.0.0.1
# A local install (--local) is for this machine only: every published port listens on loopback,
# so nothing on the network can reach the plain-HTTP server. --settings can move the ports
# (HTTP_PORT, HTTPS_PORT, PAGES_PORT with CASAMA_PAGES_URL, TURN_HOST_PORT) when they're taken.
[[ "$local" -eq 1 ]] && set_env HTTP_BIND 127.0.0.1 && set_env TURN_BIND 127.0.0.1
[[ -n "$admin_email" ]] && set_env INSTANCE_ADMIN_EMAILS "$admin_email"
if [[ -n "$settings_file" ]]; then
  [[ -f "$settings_file" ]] || die "No such settings file: $settings_file"
  say "Applying settings from $settings_file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]] || die "Bad line in $settings_file: $line"
    set_env "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  done <"$settings_file"
fi
if [[ -n "$pull" ]]; then
  set_env CASAMA_REGISTRY "$REGISTRY"
  set_env CASAMA_VERSION "$pull"
fi
[[ "$backups" -eq 1 ]] && set_env CASAMA_BACKUPS on
# Remembered on re-runs, so an upgrade never drops the backup service.
[[ "$(env_value CASAMA_BACKUPS)" == on ]] && profiles+=(--profile backup) && backups=1
registry=$(env_value CASAMA_REGISTRY)
use_published=0
[[ -n "$registry" && "$registry" != casama ]] && use_published=1

# --search (D-179): point the worker at SearXNG, also on an existing .env.
if [[ "$search" == 1 ]] && ! grep -q '^SEARXNG_URL=.' "$ENV_FILE"; then
  grep -q '^SEARXNG_SECRET=.' "$ENV_FILE" || echo "SEARXNG_SECRET=$(rand 32)" >>"$ENV_FILE"
  sed -i.bak '/^SEARXNG_URL=/d' "$ENV_FILE" && rm -f "$ENV_FILE.bak"
  echo "SEARXNG_URL=http://searxng:8080" >>"$ENV_FILE"
fi

compose() { docker compose -f "$COMPOSE_DIR/docker-compose.yml" --env-file "$ENV_FILE" ${profiles[@]+"${profiles[@]}"} "$@"; }

# ---------------------------------------------------------------- images
say "Pulling Supabase, Caddy and other images"
# Public registries (public.ecr.aws for Supabase) rate-limit anonymous pulls: a few at a time,
# retried with a growing wait.
pulled=0
for attempt in 1 2 3 4 5; do
  if COMPOSE_PARALLEL_LIMIT=2 compose pull --ignore-buildable --quiet; then pulled=1; break; fi
  say "Image pull failed (attempt $attempt of 5); retrying in $((attempt * 15))s"
  sleep $((attempt * 15))
done
[[ "$pulled" -eq 1 ]] || die "Couldn't pull the images. Check your internet connection (or registry rate limits) and run this again."
casama_services=(api supervisor egress turn)
[[ "$backups" -eq 1 ]] && casama_services+=(backup)
if [[ "$use_published" -eq 1 ]]; then
  say "Pulling Casama images ($registry, $(env_value CASAMA_VERSION))"
  compose pull --quiet "${casama_services[@]}"
  COMPOSE_PROFILES=images compose pull --quiet computer-headless
  if [[ "$desktop" -eq 1 ]]; then
    COMPOSE_PROFILES=images compose pull --quiet computer-desktop
  fi
else
  say "Building Casama images (first run takes a few minutes)"
  # CASAMA_BUILD_FLAGS=--no-cache forces clean rebuilds.
  compose build --quiet ${CASAMA_BUILD_FLAGS:-} "${casama_services[@]}"
  COMPOSE_PROFILES=images compose build --quiet ${CASAMA_BUILD_FLAGS:-} computer-headless
  if [[ "$desktop" -eq 1 ]]; then
    COMPOSE_PROFILES=images compose build --quiet ${CASAMA_BUILD_FLAGS:-} computer-desktop
  fi
fi

[[ "$start" -eq 1 ]] || { say "Images ready; start with: docker compose -f $COMPOSE_DIR/docker-compose.yml --env-file $ENV_FILE up -d"; exit 0; }

# ---------------------------------------------------------------- start
say "Starting the stack"
compose up -d --remove-orphans
public=$(grep '^CASAMA_PUBLIC_URL=' "$ENV_FILE" | cut -d= -f2-)
say "Waiting for $public/readyz"
for _ in $(seq 1 90); do
  if curl -fsS -k "$public/readyz" >/dev/null 2>&1; then
    cat <<EOF

Casama is running at $public

  1. Open the Casama app, tap Sign in or create account > More options > Server, enter
     $public, and create an account with an email and password.
     (CLI: casama config --api-url $public && casama signup --email you@example.com)
     The first account is the instance owner (admin console in Settings).
  2. Add a model key (or a local Ollama endpoint) and create your first bot.
  Docs: docs-site/self-hosting/index.md
  3. Back up $ENV_FILE and the database: casama selfhost backup

Logs: docker compose -f $COMPOSE_DIR/docker-compose.yml --env-file $ENV_FILE logs -f api worker
EOF
    exit 0
  fi
  sleep 2
done
compose ps
die "The API did not become ready; check: docker compose -f $COMPOSE_DIR/docker-compose.yml --env-file $ENV_FILE logs migrate api"
