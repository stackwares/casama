#!/usr/bin/env bash
# Phase 0 gate through the real CLI against a local stack (no Docker needed).
# With KASAMA_E2E_API already set (for example CI with `supabase start` + the API), uses that instead.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${KASAMA_E2E_API:-}" ]]; then
  log=$(mktemp)
  node apps/server/scripts/e2e-stack.ts >"$log" 2>&1 &
  pid=$!
  trap 'kill $pid 2>/dev/null || true; wait $pid 2>/dev/null || true; rm -f "$log"' EXIT
  for _ in $(seq 1 100); do
    if grep -q '^KASAMA_API_URL=' "$log"; then break; fi
    if ! kill -0 $pid 2>/dev/null; then cat "$log"; exit 1; fi
    sleep 0.2
  done
  export KASAMA_E2E_API=$(grep '^KASAMA_API_URL=' "$log" | head -1 | cut -d= -f2)
fi
echo "Using API $KASAMA_E2E_API"
(cd dart && dart test cli/test/e2e_test.dart --reporter expanded)
