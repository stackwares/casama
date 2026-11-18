#!/usr/bin/env bash
# Casama on CasaOS: the first-run step. CasaOS cannot generate secrets, so this does what
# install.sh does for a normal install: it generates every secret with OpenSSL, copies the config
# files the stack mounts, and writes a filled-in docker-compose.yml to import in CasaOS.
# It starts nothing. Run it on the CasaOS machine, from a copy of the Casama repository:
#
#   sudo deploy/casaos/setup.sh
#
# Options:
#   --url <address>       the address the apps use (default http://<this machine's IP>:8480)
#   --pages-url <address> the address of bots' web pages (default http://<IP>:8790)
#   --turn-host <name|IP> a name or IP that reaches this machine, for live view (default: the IP)
#   --http-port <port>    the port Casama listens on (default 8480; CasaOS itself uses 80)
#   --pages-port <port>   the port for bots' web pages (default 8790)
#   --data-dir <folder>   where secrets and config go (default /DATA/AppData/casama)
#   --version <tag>       the Casama image tag (default latest; a short commit id pins a release)
#
# Running it again keeps every secret and only updates the settings you pass.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
data_dir=/DATA/AppData/casama
url="" pages_url="" turn_host="" http_port="" pages_port="" version=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) url="$2"; shift 2 ;;
    --pages-url) pages_url="$2"; shift 2 ;;
    --turn-host) turn_host="$2"; shift 2 ;;
    --http-port) http_port="$2"; shift 2 ;;
    --pages-port) pages_port="$2"; shift 2 ;;
    --data-dir) data_dir="$2"; shift 2 ;;
    --version) version="$2"; shift 2 ;;
    -h | --help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }

command -v openssl >/dev/null || die "OpenSSL is needed to generate secrets (apt install openssl)."
selfhost="$root/infra/compose/selfhost"
[[ -f "$selfhost/kong.yml" && -d "$root/supabase/templates" && -f "$here/docker-compose.yml" ]] ||
  die "Run this from a copy of the Casama repository (it needs infra/compose/selfhost and supabase/templates)."

env_file="$data_dir/casama.env"
out_file="$data_dir/docker-compose.yml"
umask 077
mkdir -p "$data_dir/config/db" "$data_dir/config/email-templates"

# ---------------------------------------------------------------- secrets (as in install.sh)
rand() { openssl rand -hex "$1"; }
rsa_trad() { openssl rsa -help 2>&1 | grep -q -- '-traditional' && echo "-traditional"; }
saml_key() { openssl genrsa 2048 2>/dev/null | openssl rsa $(rsa_trad) -outform DER 2>/dev/null | openssl base64 -A; }
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
jwt() { # role secret
  local now exp header payload sig
  now=$(date +%s); exp=$((now + 10 * 365 * 24 * 3600))
  header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
  payload=$(printf '{"role":"%s","iss":"supabase","iat":%s,"exp":%s}' "$1" "$now" "$exp" | b64url)
  sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$2" -binary | b64url)
  printf '%s.%s.%s' "$header" "$payload" "$sig"
}

touch "$env_file"
env_value() { grep "^$1=" "$env_file" 2>/dev/null | tail -n1 | cut -d= -f2- || true; }
set_env() {
  local tmp="$env_file.tmp"
  { grep -v "^$1=" "$env_file" || true; printf '%s=%s\n' "$1" "$2"; } >"$tmp"
  mv "$tmp" "$env_file"
}
# Sets KEY to a new value only when it has none yet, so a re-run never replaces a secret.
once() { [[ -n "$(env_value "$1")" ]] || set_env "$1" "$2"; }

if [[ -z "$(env_value JWT_SECRET)" ]]; then
  say "Generating secrets"
  jwt_secret=$(rand 32)
  set_env JWT_SECRET "$jwt_secret"
  set_env ANON_KEY "$(jwt anon "$jwt_secret")"
  set_env SERVICE_ROLE_KEY "$(jwt service_role "$jwt_secret")"
else
  say "Keeping the secrets in $env_file"
fi
once POSTGRES_PASSWORD "$(rand 24)"
once WORKER_DB_PASSWORD "$(rand 24)"
once SECRET_KEY_BASE "$(rand 32)"
once REALTIME_ENC_KEY "$(rand 8)"
once SUPERVISOR_TOKEN "$(rand 24)"
once COMPUTER_TOKEN_SECRET "$(rand 32)"
once SAML_PRIVATE_KEY "$(saml_key)"
once EGRESS_CONTROL_TOKEN "$(rand 24)"
once INTERNAL_TOKEN "$(rand 24)"
once TURN_SECRET "$(rand 24)"
once METRICS_TOKEN "$(rand 24)"
once AUTH_HOOK_SECRET "v1,whsec_$(openssl rand -base64 32 | tr -d '\n')"
# Encrypted data cannot be read without this key: back it up.
once CONTENT_ENCRYPTION_KEY "$(openssl rand -base64 32 | tr -d '\n')"
[[ -n "$(env_value SAML_PRIVATE_KEY)" ]] || die "Could not generate the SAML signing key with this OpenSSL."

# ---------------------------------------------------------------- settings
ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
[[ -n "$ip" ]] || ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1)}' || true)
[[ -n "$ip" ]] || ip=127.0.0.1

[[ -n "$http_port" ]] && set_env CASAMA_HTTP_PORT "$http_port"
once CASAMA_HTTP_PORT 8480
[[ -n "$pages_port" ]] && set_env CASAMA_PAGES_PORT "$pages_port"
once CASAMA_PAGES_PORT 8790
[[ -n "$url" ]] && set_env CASAMA_PUBLIC_URL "${url%/}"
once CASAMA_PUBLIC_URL "http://$ip:$(env_value CASAMA_HTTP_PORT)"
[[ -n "$pages_url" ]] && set_env CASAMA_PAGES_URL "${pages_url%/}"
once CASAMA_PAGES_URL "http://$ip:$(env_value CASAMA_PAGES_PORT)"
[[ -n "$turn_host" ]] && set_env TURN_PUBLIC_HOST "$turn_host"
once TURN_PUBLIC_HOST "$ip"
[[ -n "$version" ]] && set_env CASAMA_VERSION "$version"
once CASAMA_VERSION latest
set_env CASAMA_DATA_DIR "$data_dir"

public=$(env_value CASAMA_PUBLIC_URL)
# Supabase Auth only takes an https hook address, and does not start with an http one.
if [[ "$public" == https://* ]]; then
  set_env SIGNUP_HOOK_URI "$public/hooks/auth/before-user-created"
else
  set_env SIGNUP_HOOK_URI ""
fi
# gVisor for computers, when Docker lists it.
if command -v docker >/dev/null && docker info 2>/dev/null | grep -q runsc; then
  set_env SANDBOX_RUNTIME runsc
else
  set_env SANDBOX_RUNTIME ""
fi
# Room for bot computers: the machine's memory less 4 GB for Casama itself, at least 2 GB.
if [[ -z "$(env_value COMPUTER_HOST_MEMORY_GB)" ]]; then
  total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)
  [[ -n "$total_kb" ]] || total_kb=8388608
  room=$((total_kb / 1048576 - 4))
  ((room < 2)) && room=2
  set_env COMPUTER_HOST_MEMORY_GB "$room"
  [[ "$total_kb" -lt 7000000 ]] && echo "Warning: less than 8 GB of memory; computers may not start reliably."
fi
chmod 600 "$env_file"

# ---------------------------------------------------------------- config files
say "Copying config files to $data_dir/config"
cp "$selfhost/db/realtime.sql" "$selfhost/db/roles.sql" "$selfhost/db/jwt.sql" "$data_dir/config/db/"
cp "$selfhost/kong.yml" "$selfhost/migrate.sh" "$selfhost/Caddyfile" \
  "$selfhost/sites-edge-true.caddy" "$selfhost/sites-edge-false.caddy" "$data_dir/config/"
cp "$root"/supabase/templates/*.html "$data_dir/config/email-templates/"
# The containers read these as other users (postgres, kong, caddy). They hold no secrets.
chmod 755 "$data_dir" "$data_dir/config" "$data_dir/config/db" "$data_dir/config/email-templates"
chmod 644 "$data_dir"/config/db/*.sql "$data_dir"/config/email-templates/*.html \
  "$data_dir/config/kong.yml" "$data_dir/config/migrate.sh" "$data_dir/config/Caddyfile" \
  "$data_dir"/config/sites-edge-*.caddy

# ---------------------------------------------------------------- the file to import
# Bash 5.2 treats & in a replacement as "the match"; the values here must go in as they are.
shopt -u patsub_replacement 2>/dev/null || true
compose=$(sed -n '/^name: casama$/,$p' "$here/docker-compose.yml")
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]] || continue
  key=${BASH_REMATCH[1]} value=${BASH_REMATCH[2]}
  compose=${compose//"\${$key}"/$value}
done <"$env_file"
if left=$(printf '%s\n' "$compose" | grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*\}' | sort -u) && [[ -n "$left" ]]; then
  die "These settings have no value: $(echo $left)"
fi
{
  echo "# Casama for CasaOS, written by deploy/casaos/setup.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)."
  echo "# Keep this file private: it holds every key for this installation."
  printf '%s\n' "$compose"
} >"$out_file"
chmod 600 "$out_file"

cat <<EOF

Done. Nothing was started.

  1. In CasaOS, open App Store > Custom Install, choose Import, and paste the contents of
     $out_file
  2. Install it. The first start downloads about 10 GB of images.
  3. Point the Casama app or CLI at $public and create an account.
     The first account is the instance owner.
  4. Back up $env_file somewhere safe. It holds every key for this installation.
EOF
