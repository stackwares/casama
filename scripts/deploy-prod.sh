#!/usr/bin/env bash
# Deploys a commit to the production server in one command, without dropping people (D-402). The
# server image is built on the server itself (native amd64, cached dependencies, a datacenter
# connection), so nothing goes through a registry and a code-only release builds in seconds.
#
#   scripts/deploy-prod.sh [--ref <commit|branch>] [--yes] [--dry-run] [--wait-runs <minutes>]
#                          [--registry-image] [--rollback]
#
# One deploy at a time: a lock on the server stops a second one while the first runs.
#
# Steps on the server, timed: check the checkout is clean and fast-forwards to the commit, say how
# many runs are going, copy .env, git merge --ff-only, build casama-local/server:<sha> (skipped
# when no server path changed), point CASAMA_SERVER_IMAGE at it, back up the database, run the
# migrations, start the new API next to the old one and wait until it answers, then hand over: the
# old API stops taking requests (Caddy sends them to the new one), finishes the ones it has and
# carries its calls until they end (up to CALL_HANDOVER_SECONDS, 10 minutes), then exits by itself.
# Then the worker and anything else that changed are recreated (the worker finishes the steps in
# flight first; runs continue on the new one), Caddy too when its config changed, and the deploy
# checks the new API and https://api.casama.ai/healthz. An API left carrying calls from the deploy
# before is stopped first; its calls resume on the current API.
#
#   --ref             the commit to deploy (default origin/main); it must be on origin/main
#   --yes             skip the confirmation prompt (only after the deploy was approved)
#   --dry-run         show what would happen and change nothing
#   --wait-runs N     wait up to N minutes for no run to be working first (default 0: don't wait;
#                     runs carry on through a deploy)
#   --registry-image  run the published ghcr image instead of building (clears the pin)
#   --rollback        put the API and worker back on the previous image; no git change, and
#                     migrations are not reverted
#
# Migrations must work with the build before them (docs-site/develop/contributing.md): the old API
# keeps answering for a few seconds after they run, and keeps carrying calls for minutes.
#
# Publishing images to ghcr for self-hosters is separate: the "Publish images" GitHub workflow
# (or scripts/publish-images.sh). Supervisor, computer and other images still come from ghcr.
set -euo pipefail

host=${DEPLOY_HOST:-casama-vps}
dir=${DEPLOY_DIR:-/opt/casama}
profiles=${DEPLOY_PROFILES:-search backup}
health_url=${DEPLOY_HEALTH_URL:-https://api.casama.ai/healthz}
ref=origin/main
yes=0
dry=0
wait_runs=0
mode=build
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) ref="$2"; shift 2 ;;
    --yes) yes=1; shift ;;
    --dry-run) dry=1; shift ;;
    --wait-runs) wait_runs="$2"; shift 2 ;;
    # Kept so older notes still work: runs no longer block a deploy.
    --force-runs) wait_runs=0; shift ;;
    --registry-image) mode=registry; shift ;;
    --rollback) mode=rollback; shift ;;
    -h | --help) sed -n '2,37p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ "$wait_runs" =~ ^[0-9]+$ ]] || { echo "--wait-runs takes whole minutes" >&2; exit 2; }

root=$(git rev-parse --show-toplevel)
sha=""
if [[ "$mode" != rollback ]]; then
  git -C "$root" fetch --quiet origin main
  sha=$(git -C "$root" rev-parse --verify "$ref^{commit}")
  git -C "$root" merge-base --is-ancestor "$sha" origin/main ||
    { echo "$(git -C "$root" rev-parse --short "$sha") is not on origin/main; push it first" >&2; exit 1; }
  echo "==> Deploying $(git -C "$root" log -1 --format='%h %s' "$sha") to $host ($mode)"
else
  echo "==> Rolling back the API and worker on $host to the previous image"
fi
if [[ "$dry" -eq 0 && "$yes" -eq 0 ]]; then
  read -r -p "This changes production. Continue? [y/N] " answer
  [[ "$answer" == y || "$answer" == Y ]] || { echo "Stopped."; exit 1; }
fi

start=$(date +%s)
# The remote half runs as one bash script, so a failure anywhere stops the deploy. ssh joins its
# arguments into one command line, so each is quoted (DEPLOY_PROFILES has a space in it).
who="$(whoami)@$(hostname -s) in ${root/#$HOME/~}"
ssh -o ConnectTimeout=15 "$host" bash -s -- \
  "$(printf '%q ' "$dir" "$sha" "$mode" "$dry" "$wait_runs" "$profiles" "$who")" <<'REMOTE'
set -euo pipefail
dir=$1 sha=$2 mode=$3 dry=$4 wait_runs=$5 profiles=$6 who=$7
cd "$dir"

# One deploy at a time. Several sessions deploy, from different checkouts and machines, so the lock
# lives here on the server. flock lets go when this script ends, even when ssh drops; a dry run only
# reports a deploy in progress. A second deploy stops rather than queues: it was approved for a
# commit that may no longer be the newest one.
lock_file=/root/casama-deploy.lock
lock_info=/root/casama-deploy.lock.info
exec 9>>"$lock_file"
if ! flock -n 9; then
  holder=$(cat "$lock_info" 2>/dev/null || echo "unknown")
  if [[ "$dry" -eq 1 ]]; then
    echo "    note: a deploy is running now ($holder); a real deploy would stop here"
  else
    echo "Another deploy is running on this server: $holder" >&2
    echo "Wait for it to finish, then run the deploy again (who holds it: $lock_info on the server)." >&2
    exit 1
  fi
elif [[ "$dry" -eq 1 ]]; then
  flock -u 9
else
  echo "$who, ${sha:0:12} ($mode), since $(date -u '+%Y-%m-%d %H:%M:%S') UTC, pid $$" > "$lock_info"
fi
env_file=infra/compose/.env
history=/root/casama-deploys.log
# APIs handed over and still carrying calls; the next deploy stops any that are left.
draining_file=/root/casama-api-draining
profile_args=()
for p in $profiles; do profile_args+=(--profile "$p"); done
dc() { docker compose -f infra/compose/docker-compose.yml --env-file "$env_file" "${profile_args[@]}" "$@"; }
t0=$(date +%s)
step() { echo "--> [$(( $(date +%s) - t0 ))s] $*"; }
run() { if [[ "$dry" -eq 1 ]]; then echo "    (dry run) $*"; else "$@"; fi; }
env_value() { sed -n "s/^$1=//p" "$env_file" | tail -1; }
set_env() {
  if grep -q "^$1=" "$env_file"; then sed -i "s|^$1=.*|$1=$2|" "$env_file"; else printf '%s=%s\n' "$1" "$2" >> "$env_file"; fi
}
sql() { docker exec casama-db-1 psql -U supabase_admin -d postgres -qtAX -c "$1"; }
# Whether an API container answers /readyz (its database is reachable), from inside it.
api_ready() {
  docker exec "$1" node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/readyz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" >/dev/null 2>&1
}
stamp=$(date -u +%Y%m%d-%H%M%S)
env_copy="/root/.env.bak-$stamp-deploy"
current_image=$(env_value CASAMA_SERVER_IMAGE)
# "registry" in the history means CASAMA_SERVER_IMAGE was empty (the ghcr image ran).
current_ref=${current_image:-registry}
[[ -s "$history" || "$dry" -eq 1 ]] || echo "$stamp $(git rev-parse --short=12 HEAD) $current_ref start" >> "$history"
api_container=""

# Runs carry on through a deploy (D-402): a working run continues at its next step on the new
# worker, and a run whose saved steps the new code changed is picked up by a new run in its chat.
report_runs() {
  local counts
  counts=$(sql "select count(*) filter (where status = 'running') || ' ' || count(*) filter (where status not in ('queued', 'running', 'completed', 'failed', 'cancelled')) from public.runs where status not in ('completed', 'failed', 'cancelled')")
  read -r working waiting <<<"$counts"
  echo "    runs: $working working, $waiting waiting on a person (both carry on through the deploy)"
}

# Only with --wait-runs: waits for a moment with no working run.
wait_for_runs() {
  [[ "$wait_runs" -gt 0 ]] || return 0
  local n deadline=$(( $(date +%s) + wait_runs * 60 ))
  while :; do
    n=$(sql "select count(*) from public.runs where status = 'running'")
    if [[ "$n" == 0 ]]; then echo "    no runs in flight"; return 0; fi
    if [[ "$dry" -eq 1 ]]; then echo "    $n run(s) in flight; a real deploy would wait up to $wait_runs min"; return 0; fi
    if (( $(date +%s) >= deadline )); then echo "$n run(s) still running after $wait_runs min; retry, or leave out --wait-runs" >&2; exit 1; fi
    echo "    waiting: $n run(s) in flight"
    sleep 10
  done
}

# .env first, before anything changes it, so a failed start can put it back.
backup_env() {
  step "Copying .env"
  run cp -p "$env_file" "$env_copy"
  if [[ "$dry" -eq 0 ]]; then
    # Keeps the newest 20 .env copies; hand-made backups are left alone.
    ls -1t /root/.env.bak-*-deploy 2>/dev/null | tail -n +21 | xargs -r rm -f
  fi
}

restore_env() {
  [[ "$dry" -eq 0 && -f "$env_copy" ]] && cp -p "$env_copy" "$env_file"
  return 0
}

# The database, right before the migrations.
backup_db() {
  step "Backing up the database"
  if [[ "$dry" -eq 0 ]]; then
    docker exec casama-db-1 pg_dump -U supabase_admin -Fc postgres > "/root/db-before-deploy-$stamp.dump"
    echo "    /root/db-before-deploy-$stamp.dump ($(du -h "/root/db-before-deploy-$stamp.dump" | cut -f1))"
    # Keeps the newest 20 deploy dumps; hand-made backups are left alone.
    ls -1t /root/db-before-deploy-*.dump 2>/dev/null | tail -n +21 | xargs -r rm -f
  else
    echo "    (dry run) pg_dump to /root/db-before-deploy-$stamp.dump"
  fi
}

validate_compose() {
  dc config -q
  # A checkout without CASAMA_SERVER_IMAGE support in compose would quietly run the registry image.
  local want images
  want=$(env_value CASAMA_SERVER_IMAGE)
  # Captured first: grep -q closing the pipe early would SIGPIPE compose and fail under pipefail.
  images=$(dc config --images)
  if [[ "$dry" -eq 0 && -n "$want" ]] && ! grep -qxF "$want" <<<"$images"; then
    echo "compose does not resolve the API image to $want; is the CASAMA_SERVER_IMAGE change pulled?" >&2
    restore_env
    exit 1
  fi
}

migrate() {
  step "Running migrations"
  if [[ "$dry" -eq 1 ]]; then echo "    (dry run) compose run --rm migrate"; return 0; fi
  # </dev/null: this script reaches bash on stdin, and `compose run` would read the rest of it.
  if ! dc run --rm --no-deps -T migrate </dev/null; then
    restore_env
    echo "Migrations failed; nothing was restarted and .env is back as it was." >&2
    exit 1
  fi
}

# An API handed over by an earlier deploy that still carries calls: stopped now (SIGTERM), so its
# calls close with "server restarting" and the app resumes them on the API that serves now.
stop_draining() {
  [[ -s "$draining_file" ]] || return 0
  local id
  while read -r id; do
    [[ -n "$id" ]] || continue
    if [[ "$(docker inspect -f '{{.State.Running}}' "$id" 2>/dev/null || true)" == true ]]; then
      step "Stopping the API the last deploy left carrying calls (${id:0:12}); its calls resume on the current one"
      run docker stop -t 45 "$id" >/dev/null || true
    fi
    run docker rm -f "$id" >/dev/null 2>&1 || true
  done < "$draining_file"
  [[ "$dry" -eq 1 ]] || : > "$draining_file"
}

# The new API starts next to the old one; the old one hands over once the new one answers.
swap_api() {
  local old new id n want have cap
  old=$(dc ps -q api)
  n=$(wc -w <<<"$old")
  if [[ "$dry" -eq 1 ]]; then
    step "Starting the new API next to the running one (when its image or config changed)"
    echo "    (dry run) compose up -d --no-deps --no-recreate --scale api=$(( n + 1 )) api, wait for /readyz, then hand over from $n old API(s)"
    return 0
  fi
  want=$(dc config --hash api | awk '{print $2}')
  have=""
  # The hash covers config and the image name, not the image itself: a pulled registry image keeps
  # its tag, so compare the image id too.
  want="$want $(docker image inspect -f '{{.Id}}' "$(dc config --images api | head -n1)" 2>/dev/null)"
  if [[ "$n" -eq 1 ]]; then have="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.config-hash"}} {{.Image}}' "$old")"; fi
  if [[ "$n" -eq 1 && "$have" == "$want" ]]; then
    echo "    the API is unchanged and keeps running"
    api_container=$old
    return 0
  fi
  step "Starting the new API next to the running one"
  dc up -d --no-deps --no-recreate --scale "api=$(( n + 1 ))" api
  new=$(comm -13 <(sort <<<"$old") <(dc ps -q api | sort) | tr -d ' ')
  if [[ $(wc -w <<<"$new") -ne 1 ]]; then
    echo "expected one new API container, found: ${new:-none}" >&2
    restore_env
    exit 1
  fi
  step "Waiting for the new API to answer"
  for _ in $(seq 1 120); do api_ready "$new" && break; sleep 1; done
  if ! api_ready "$new"; then
    echo "The new API didn't come up. Last log lines:" >&2
    docker logs --tail 40 "$new" >&2 || true
    docker rm -f "$new" >/dev/null 2>&1 || true
    restore_env
    echo "The old API is still serving and .env is back as it was (migrations stay)." >&2
    exit 1
  fi
  # The old API's calls are carried this long at most, then it is removed even if it hangs.
  cap=$(env_value CALL_HANDOVER_SECONDS)
  [[ "$cap" =~ ^[0-9]+$ ]] || cap=600
  cap=$(( cap + 120 ))
  for id in $old; do
    step "Handing over from the old API (${id:0:12}): it finishes its requests and carries its calls"
    # It exits by itself once done; it must not be started again.
    docker update --restart=no "$id" >/dev/null
    docker kill -s USR2 "$id" >/dev/null 2>&1 || true
    echo "$id" >> "$draining_file"
    # 9>&-: it outlives the deploy and must not hold the deploy lock.
    setsid sh -c "timeout $cap docker wait $id >/dev/null 2>&1; docker rm -f $id >/dev/null 2>&1" \
      </dev/null >/dev/null 2>&1 9>&- &
  done
  api_container=$new
}

# Everything else (the worker, and any service whose image or config changed); the API and the
# migrations were handled above. A recreated worker finishes the steps in flight before it stops.
recreate_rest() {
  local others
  others=$(dc config --services | grep -vxE 'api|migrate' | tr '\n' ' ')
  step "Updating the worker and anything else that changed"
  computer_services_notice
  # shellcheck disable=SC2086
  run dc up -d --no-deps $others
}

# Bots' computers keep running through any deploy, but recreating the supervisor, egress proxy or
# TURN relay cuts the commands bots are running on them and drops every live view (D-360). Says so
# before it happens, from compose's own plan (`up --dry-run`). After the fast-forward it reflects
# this commit; in a dry run, the checkout as it is plus a note when the compose file changes.
computer_services_notice() {
  local plan hit
  plan=$(dc up -d --dry-run 2>&1 || true)
  hit=$(grep -E 'Recreat' <<<"$plan" | grep -oE 'casama-(supervisor|egress|turn)\b' | sort -u | tr '\n' ' ' || true)
  if [[ -n "$hit" ]]; then
    echo "    NOTE: recreating ${hit}: commands running on computers are cut and live views reconnect."
  fi
  if [[ "$dry" -eq 1 ]] && printf '%s\n' "${changed:-}" | grep -q '^infra/compose/docker-compose.yml$'; then
    echo "    NOTE: the compose file changes; if the supervisor, egress or TURN section did, they are recreated too."
  fi
  return 0
}

check_running() {
  [[ "$dry" -eq 1 ]] && return 0
  step "Checking the API and worker"
  local worker
  if [[ -z "$api_container" ]] || ! api_ready "$api_container"; then
    echo "The API isn't answering. Last log lines:" >&2
    [[ -n "$api_container" ]] && docker logs --tail 40 "$api_container" >&2 || true
    echo "Roll back with: scripts/deploy-prod.sh --rollback" >&2
    exit 1
  fi
  worker=$(dc ps -q worker)
  [[ -n "$worker" ]] && docker inspect -f '{{.State.Running}}' "$worker" | grep -q true ||
    { echo "worker is not running" >&2; exit 1; }
  echo "    api $(docker inspect -f '{{.Config.Image}}' "$api_container"), worker $(docker inspect -f '{{.Config.Image}}' "$worker")"
}

if [[ "$mode" == rollback ]]; then
  previous=$(awk -v cur="$current_ref" '$3 != "" && $3 != cur {p=$3} END {print p}' "$history" 2>/dev/null || true)
  [[ -n "$previous" ]] || { echo "No earlier image in $history to roll back to" >&2; exit 1; }
  if [[ "$previous" != registry ]] && ! docker image inspect "$previous" >/dev/null 2>&1; then
    echo "$previous is no longer on this machine" >&2; exit 1
  fi
  step "Rolling back: $current_ref -> $previous"
  report_runs
  wait_for_runs
  backup_env
  if [[ "$previous" == registry ]]; then run set_env CASAMA_SERVER_IMAGE ""; else run set_env CASAMA_SERVER_IMAGE "$previous"; fi
  validate_compose
  backup_db
  stop_draining
  swap_api
  recreate_rest
  check_running
  [[ "$dry" -eq 1 ]] || echo "$stamp $(git rev-parse --short=12 HEAD) $previous rollback" >> "$history"
  exit 0
fi

step "Checking the checkout"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || { echo "$dir has local changes:" >&2; git status --short >&2; exit 1; }
git fetch --quiet origin main
old=$(git rev-parse HEAD)
git merge-base --is-ancestor "$old" "$sha" || { echo "$sha does not fast-forward from $(git rev-parse --short "$old")" >&2; exit 1; }
short=$(git rev-parse --short=12 "$sha")
changed=$(git diff --name-only "$old" "$sha")
echo "    $(git rev-parse --short "$old") -> $short, $(printf '%s' "$changed" | grep -c . || true) file(s) changed"
new_migrations=$(printf '%s\n' "$changed" | grep -c '^supabase/migrations/.*\.sql$' || true)
if [[ "$new_migrations" -gt 0 ]]; then echo "    $new_migrations migration file(s) will run"; fi
report_runs

# Paths that end up in the server image (apps/server/Dockerfile copies these).
server_paths='^(apps/server/|packages/|ee/|docs-site/|supabase/migrations/|pnpm-lock\.yaml|pnpm-workspace\.yaml|package\.json)'
image=casama-local/server:$short
need_build=0
if [[ "$mode" == build ]]; then
  if [[ -z "$current_image" || "$current_image" != casama-local/* ]]; then need_build=1
  elif printf '%s\n' "$changed" | grep -Eq "$server_paths"; then need_build=1
  fi
  if [[ "$need_build" -eq 0 ]]; then image=$current_image; fi
fi

wait_for_runs
backup_env

step "Fast-forwarding to $short"
run git merge --ff-only --quiet "$sha"

if [[ "$mode" == registry ]]; then
  step "Using the registry image (clearing CASAMA_SERVER_IMAGE) and pulling it"
  image=""
  run set_env CASAMA_SERVER_IMAGE ""
  run dc pull api worker
elif [[ "$need_build" -eq 1 ]]; then
  step "Building $image"
  if [[ "$dry" -eq 1 ]]; then echo "    (dry run) docker build -f apps/server/Dockerfile -t $image ."
  else
    DOCKER_BUILDKIT=1 docker build --quiet -f apps/server/Dockerfile -t "$image" \
      --label "org.opencontainers.image.revision=$sha" . >/dev/null
  fi
  run set_env CASAMA_SERVER_IMAGE "$image"
else
  step "No server path changed; keeping $image"
fi

validate_compose
backup_db
migrate
stop_draining
swap_api
recreate_rest
if printf '%s\n' "$changed" | grep -Eq '^infra/compose/selfhost/(Caddyfile|sites-edge-(true|false)\.caddy)$'; then
  step "Caddy's config changed: recreating Caddy (single-file bind mounts; a second or two)"
  run dc up -d --no-deps --force-recreate caddy
fi
check_running

if [[ "$dry" -eq 0 ]]; then
  echo "$stamp $short ${image:-registry} deploy" >> "$history"
  # Keeps the five newest local server builds plus whatever is running.
  docker images casama-local/server --format '{{.Repository}}:{{.Tag}}' | tail -n +6 |
    grep -vxF "${image:-none}" | xargs -r docker image rm >/dev/null 2>&1 || true
fi
step "Done on the server"
REMOTE

if [[ "$dry" -eq 0 ]]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$health_url" || true)
  [[ "$code" == 200 ]] || { echo "$health_url answered $code" >&2; exit 1; }
  echo "==> $health_url 200. Deployed in $(( $(date +%s) - start ))s."
fi
