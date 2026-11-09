#!/usr/bin/env bash
# Live checks against a real model (D-064), outside CI. Needs a real OpenRouter key in
# ~/.config/kasama/openrouter.env (OPENROUTER_API_KEY=..., mode 600) or in the environment.
#   1. server: the key works with the default model; a live tool call drives a real Docker computer
#   2. app (optional, LIVE_APP=1): onboarding and a live chat in the macOS app against the local stack
# The key is never written into the repo, logs or test output. Output tokens are capped.
set -euo pipefail
cd "$(dirname "$0")/.."
KEY_FILE="${KASAMA_KEY_FILE:-$HOME/.config/kasama/openrouter.env}"
if [[ -z "${OPENROUTER_API_KEY:-}" && -f "$KEY_FILE" ]]; then
  set -a; . "$KEY_FILE"; set +a
fi
: "${OPENROUTER_API_KEY:?no OpenRouter key (set it or create $KEY_FILE)}"
redact() { sed -E 's/sk-or-[A-Za-z0-9_-]+/[redacted]/g'; }

echo "== server live checks"
(cd apps/server && KASAMA_LIVE=1 npx vitest run test/live-model.test.ts --reporter=verbose 2>&1 | redact | grep -E "✓|×|live run|Error|Tests ")

if [[ "${LIVE_APP:-0}" == "1" ]]; then
  echo "== app live chat (local API on :8787 with a live worker)"
  # The worker must call the real provider: run one without fixtures while this test runs.
  pkill -f "apps/server/src/main.ts" || true
  sleep 1
  extra=(); [[ -f "${STACK_ENV:-}" ]] && extra=(--env-file="$STACK_ENV")
  MODE=api nohup node --env-file=.env "${extra[@]}" apps/server/src/main.ts >/dev/null 2>&1 &
  KASAMA_MODEL_FIXTURES= KASAMA_MAX_OUTPUT_TOKENS=1500 MODE=worker nohup node --env-file=.env "${extra[@]}" apps/server/src/main.ts >/dev/null 2>&1 &
  sleep 6
  dir="$(mktemp -d)"; chmod 700 "$dir"
  trap 'rm -rf "$dir"' EXIT
  ( umask 077; printf '{"KASAMA_LIVE_OPENROUTER_KEY":"%s"}' "$OPENROUTER_API_KEY" > "$dir/defines.json" )
  (cd client && flutter test integration_test/live_model_test.dart -d macos --dart-define-from-file="$dir/defines.json" 2>&1 | redact | grep -E "All tests passed|Some tests failed|Timed out|Expected|Actual")
  rm -rf "$dir"
  echo "Restart your fixture worker afterwards (KASAMA_MODEL_FIXTURES in .env)."
fi
