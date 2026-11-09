#!/usr/bin/env bash
# Starts a sandbox stack, the API and the worker for evals (CI or local). Arg 1: fixture file(s)
# for the worker, or empty for live models. Writes .env from .env.example plus Supabase values.
set -euo pipefail
cd "$(dirname "$0")/.."
fixtures="${1:-}"
[[ -f .env ]] || cp .env.example .env
[[ -f .env.supabase ]] && cat .env.supabase >> .env
(cd apps/server && node -e 'import("@kasama/sandbox/testing").then(async (m) => { const s = await m.startSandboxStack(); console.log(`SUPERVISOR_URL=${s.supervisorUrl}\nSUPERVISOR_TOKEN=${s.token}`); setInterval(() => {}, 1 << 30); })') > /tmp/evals-stack.env &
for _ in $(seq 1 60); do grep -q SUPERVISOR_TOKEN /tmp/evals-stack.env 2>/dev/null && break; sleep 2; done
MODE=api node --env-file=.env --env-file=/tmp/evals-stack.env apps/server/src/main.ts > /tmp/evals-api.log 2>&1 &
KASAMA_MODEL_FIXTURES="$fixtures" KASAMA_MAX_OUTPUT_TOKENS=2000 MODE=worker \
  node --env-file=.env --env-file=/tmp/evals-stack.env apps/server/src/main.ts > /tmp/evals-worker.log 2>&1 &
for _ in $(seq 1 30); do curl -sf http://127.0.0.1:8787/readyz >/dev/null && exit 0; sleep 2; done
echo "API did not start"; tail -50 /tmp/evals-api.log; exit 1
