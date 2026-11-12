#!/usr/bin/env bash
# Starts the whole local backend that the Flutter apps (and api-dev.casama.ai) talk to:
#   1. Docker Desktop, if it is not running
#   2. Supabase (`supabase start`): Postgres :54322, Auth/API :54321
#   3. Computer services from infra/compose/docker-compose.dev.yml: supervisor :8788,
#      egress proxy, TURN relay, SearXNG :18080 (the computer images are built on first run)
#   4. The API (:8787) and the worker on the host, reading ../.env, until Ctrl-C
#
# The API and worker run on the host, not in the compose file's `api`/`worker` containers,
# because they hand clients SUPABASE_URL from .env (https://auth-dev.casama.ai), which phones and
# the Mac app can reach. The containers would hand out http://host.docker.internal:54321.
#
# The Cloudflare Tunnel (api-dev -> :8787, auth-dev -> :54321) is the launchd agent
# ai.casama.tunnel and is always on; this script only checks it.
#
# Usage:
#   scripts/dev-up.sh          start everything; Ctrl-C stops the API and worker
#   scripts/dev-up.sh --down   also stop the compose services and Supabase
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
compose=(docker compose -f infra/compose/docker-compose.dev.yml --profile search)

if [[ "${1:-}" == "--down" ]]; then
  "${compose[@]}" stop supervisor egress turn searxng || true
  supabase stop || true
  echo "Stopped the compose services and Supabase."
  exit 0
fi

[[ -f .env ]] || { echo "No .env at the repo root. Run: cp .env.example .env and fill it in." >&2; exit 1; }

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

say "Docker"
if ! docker info >/dev/null 2>&1; then
  open -a Docker
  printf 'Waiting for Docker Desktop'
  for _ in $(seq 1 90); do
    docker info >/dev/null 2>&1 && break
    printf '.'; sleep 2
  done
  echo
  docker info >/dev/null 2>&1 || { echo "Docker did not start." >&2; exit 1; }
fi
echo "Docker is running."

say "Supabase"
# Docker Desktop restarts Supabase's containers by itself, and `supabase start` refuses while
# they are still coming up, so wait for them before deciding whether to start Supabase.
project_id=$(sed -nE 's/^project_id *= *"([^"]+)".*/\1/p' supabase/config.toml | head -1)
if docker ps -q --filter "name=^supabase_db_${project_id}$" | grep -q .; then
  printf 'Supabase containers are up, waiting until they are ready'
  for _ in $(seq 1 90); do
    supabase status >/dev/null 2>&1 && break
    printf '.'; sleep 2
  done
  echo
fi
if supabase status >/dev/null 2>&1; then
  echo "Supabase is running."
else
  supabase start
fi

say "Computer images"
if docker image inspect casama/computer-desktop:dev >/dev/null 2>&1; then
  echo "Already built (rebuild with: ${compose[*]} --profile images build)."
else
  "${compose[@]}" --profile images build computer-headless computer-desktop
fi

say "Supervisor, egress proxy, TURN, SearXNG"
"${compose[@]}" up --build -d supervisor egress turn searxng

say "Dependencies"
[[ -d node_modules ]] || pnpm install

if lsof -nP -iTCP:8787 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port 8787 is already in use (another API?). Stop it first:" >&2
  lsof -nP -iTCP:8787 -sTCP:LISTEN >&2
  exit 1
fi

say "API and worker (Ctrl-C stops both)"
pids=()
# pnpm starts node, and node --watch starts another node, so stop the whole tree.
kill_tree() {
  local child
  for child in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$child"; done
  kill "$1" 2>/dev/null || true
}
cleanup() {
  trap - INT TERM EXIT
  echo
  echo "Stopping the API and worker. Supabase and the compose services keep running (scripts/dev-up.sh --down stops them)."
  for pid in "${pids[@]}"; do kill_tree "$pid"; done
  wait 2>/dev/null || true
}
trap cleanup INT TERM EXIT

pnpm --filter @casama/server dev > >(sed -u 's/^/[api]    /') 2>&1 &
pids+=($!)
pnpm --filter @casama/server dev:worker > >(sed -u 's/^/[worker] /') 2>&1 &
pids+=($!)

for _ in $(seq 1 60); do
  curl -sf http://localhost:8787/readyz >/dev/null 2>&1 && break
  sleep 1
done
if curl -sf http://localhost:8787/readyz >/dev/null 2>&1; then
  tunnel="not reachable (check: launchctl list | grep ai.casama.tunnel)"
  curl -sf -m 10 https://api-dev.casama.ai/readyz >/dev/null 2>&1 && tunnel="ok"
  cat <<EOF

  Local stack is up.
    API          http://localhost:8787   (reference at /docs)
    Tunnel       https://api-dev.casama.ai  $tunnel
    Studio       http://localhost:54323

    Apps:        flutter run --dart-define=CASAMA_API_URL=https://api-dev.casama.ai
                 (no tunnel: http://localhost:8787 works for the Mac app and web only)
    Web app:     flutter run -d web-server --web-port 8099   (https://app-dev.casama.ai,
                 where invite, join and sign-in consent links open)

EOF
else
  echo "The API did not answer /readyz within 60 s; see the [api] lines above." >&2
fi

wait
