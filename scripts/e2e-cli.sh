#!/usr/bin/env bash
# Phase gates through the real CLI against a local stack. Set E2E_SANDBOX=1 (needs Docker) for the computer gate.
# With CASAMA_E2E_API already set (for example CI with `supabase start` + the API), uses that instead.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${CASAMA_E2E_API:-}" ]]; then
  log=$(mktemp)
  node apps/server/scripts/e2e-stack.ts >"$log" 2>&1 &
  pid=$!
  trap 'kill $pid 2>/dev/null || true; wait $pid 2>/dev/null || true; rm -f "$log"' EXIT
  for _ in $(seq 1 600); do
    if grep -q '^CASAMA_API_URL=' "$log"; then break; fi
    if ! kill -0 $pid 2>/dev/null; then cat "$log"; exit 1; fi
    sleep 0.2
  done
  export CASAMA_E2E_API=$(grep '^CASAMA_API_URL=' "$log" | head -1 | cut -d= -f2)
fi
echo "Using API $CASAMA_E2E_API"
(cd dart && dart test cli/test/e2e_test.dart --reporter expanded)
