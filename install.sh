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
set -euo pipefail

cd "$(dirname "$0")"
COMPOSE_DIR=infra/compose
ENV_FILE="$COMPOSE_DIR/.env"
domain="" local=0 http_port=80 desktop=0 start=1 search=0 profiles=()

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
    -h | --help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }

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
say "Building Casama images (first run takes a few minutes)"
# CASAMA_BUILD_FLAGS=--no-cache forces clean rebuilds.
compose build --quiet ${CASAMA_BUILD_FLAGS:-} api supervisor egress turn
COMPOSE_PROFILES=images compose build --quiet ${CASAMA_BUILD_FLAGS:-} computer-headless
if [[ "$desktop" -eq 1 ]]; then
  COMPOSE_PROFILES=images compose build --quiet ${CASAMA_BUILD_FLAGS:-} computer-desktop
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
