#!/usr/bin/env bash
# Headed Chromium for the desktop taskbar and menu (Playwright build, not apt Chrome).
# Docker blocks the Chromium sandbox, so --no-sandbox is required; agent-browser adds this for bots.
set -euo pipefail
export DISPLAY="${DISPLAY:-:1}"
profile="${AGENT_BROWSER_PROFILE:-$HOME/.browser-profile}"
exec chrome --no-sandbox \
  --user-data-dir="$profile" \
  --no-first-run --no-default-browser-check \
  --start-maximized --hide-crash-restore-bubble --test-type \
  "$@"
