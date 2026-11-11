#!/usr/bin/env bash
# Headed Chromium for the desktop taskbar and menu (Playwright build, not apt Chrome).
# Docker blocks the Chromium sandbox, so --no-sandbox is required; agent-browser adds this for bots.
set -euo pipefail
export DISPLAY="${DISPLAY:-:1}"
profile="${AGENT_BROWSER_PROFILE:-$HOME/.browser-profile}"
# Through the local relay to the egress proxy (desktop-start runs it), which adds the credentials.
proxy=()
if [ -n "${AGENT_BROWSER_PROXY_USERNAME:-}" ]; then
  proxy=(--proxy-server="http://127.0.0.1:${CASAMA_PROXY_RELAY_PORT:-3130}" --proxy-bypass-list="localhost;127.0.0.1")
fi
exec chrome --no-sandbox "${proxy[@]}" \
  --user-data-dir="$profile" \
  --no-first-run --no-default-browser-check \
  --start-maximized --hide-crash-restore-bubble --test-type \
  "$@"
