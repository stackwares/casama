#!/usr/bin/env bash
# Run a heavy command (full test suites, flutter analyze/test, pgTAP, typecheck) one at a time
# across the whole machine, in any checkout or worktree. Other callers wait in line.
#
#   scripts/heavy.sh pnpm test
#   scripts/heavy.sh pnpm --filter @casama/db test:pgtap
#   scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'
#   scripts/heavy.sh --status        # who holds the lock
#
# Also caps workers so even one run leaves room for the rest of the machine:
# VITEST_MAX_WORKERS (default 4) and `flutter test --concurrency` (default 4) unless you set them.
set -uo pipefail

LOCK_DIR="${CASAMA_HEAVY_LOCK:-/tmp/casama-heavy.lock}"
INFO="$LOCK_DIR/info"
POLL=5

holder() { cat "$INFO" 2>/dev/null || echo "(no info yet)"; }

if [[ "${1:-}" == "--status" ]]; then
  if [[ -d "$LOCK_DIR" ]]; then echo "held:"; holder; else echo "free"; fi
  exit 0
fi
if [[ $# -eq 0 ]]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

export VITEST_MAX_WORKERS="${VITEST_MAX_WORKERS:-4}"
FLUTTER_JOBS="${CASAMA_FLUTTER_JOBS:-4}"

# `flutter test` without its own -j/--concurrency gets a cap.
args=("$@")
if [[ "${args[0]:-}" == "flutter" && "${args[1]:-}" == "test" ]]; then
  has_j=0
  for a in "${args[@]}"; do [[ "$a" == -j* || "$a" == --concurrency* ]] && has_j=1; done
  [[ $has_j -eq 0 ]] && args=(flutter test "--concurrency=$FLUTTER_JOBS" "${args[@]:2}")
fi

# Already inside a heavy.sh run (a wrapped script calling it again): don't deadlock.
if [[ -n "${CASAMA_HEAVY_HELD:-}" ]]; then
  exec "${args[@]}"
fi

waited=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  pid=$(sed -n 's/^pid=//p' "$INFO" 2>/dev/null)
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    echo "heavy.sh: clearing stale lock from dead pid $pid" >&2
    rm -rf "$LOCK_DIR"
    continue
  fi
  if [[ -z "$pid" ]]; then
    # Holder is between mkdir and writing info; give it a moment, then treat as stale.
    age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || date +%s) ))
    if (( age > 30 )); then rm -rf "$LOCK_DIR"; continue; fi
  fi
  if (( waited == 0 )); then
    echo "heavy.sh: another heavy run is going, waiting in line:" >&2
    holder | sed 's/^/  /' >&2
  elif (( waited % 60 == 0 )); then
    echo "heavy.sh: still waiting (${waited}s)" >&2
  fi
  sleep "$POLL"
  waited=$(( waited + POLL ))
done

cleanup() {
  if [[ "$(sed -n 's/^pid=//p' "$INFO" 2>/dev/null)" == "$$" ]]; then rm -rf "$LOCK_DIR"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

{
  echo "pid=$$"
  echo "cwd=$PWD"
  echo "cmd=${args[*]}"
  echo "started=$(date '+%Y-%m-%d %H:%M:%S')"
} > "$INFO"

(( waited > 0 )) && echo "heavy.sh: lock acquired after ${waited}s" >&2

export CASAMA_HEAVY_HELD=1
"${args[@]}"
status=$?
exit $status
