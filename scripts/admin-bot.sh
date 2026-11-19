#!/usr/bin/env bash
# The admin bot (D-435, docs/ADMIN-BOT-PLAN.md), from a terminal.
#
#   scripts/admin-bot.sh status          which bot it is, and whether it's on
#   scripts/admin-bot.sh on BOT_ID       let this bot propose admin actions in the owner's chat
#   scripts/admin-bot.sh off             turn it off (running chats lose the tools at once)
#
# Every admin action the bot proposes still waits for the owner's approval in the app.
# Who you are: CASAMA_TOKEN (an owner's access token), or the casama CLI signed in as the owner.
# Which server: CASAMA_API_URL, else the CLI's, else https://api.casama.ai.
#
# "on" and "off" change production: get Oliver's yes first (AGENTS.md, "Ask before any production
# deploy").
set -euo pipefail

die() { echo "admin-bot: $*" >&2; exit 1; }
CONFIG_DIR="${CASAMA_CONFIG_DIR:-$HOME/.config/casama}"

api_url() {
  if [[ -n "${CASAMA_API_URL:-}" ]]; then echo "${CASAMA_API_URL%/}"; return; fi
  python3 - "$CONFIG_DIR/config.json" <<'PY'
import json, sys
try:
    print((json.load(open(sys.argv[1])).get("api_url") or "https://api.casama.ai").rstrip("/"))
except Exception:
    print("https://api.casama.ai")
PY
}

token() {
  if [[ -n "${CASAMA_TOKEN:-}" ]]; then echo "$CASAMA_TOKEN"; return; fi
  command -v casama >/dev/null || die "set CASAMA_TOKEN, or install the casama CLI and run: casama login"
  casama --api "$API" whoami >/dev/null 2>&1 || die "not signed in: run casama login as the instance owner"
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["access_token"])' "$CONFIG_DIR/session.json" \
    || die "couldn't read the CLI's session"
}

API="$(api_url)"

call() {
  local method="$1" body="${2:-}" out status
  out="$(mktemp)"
  if [[ -n "$body" ]]; then
    status=$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$API/v1/admin/admin-bot" \
      -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' --data "$body")
  else
    status=$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$API/v1/admin/admin-bot" \
      -H "authorization: Bearer $TOKEN")
  fi
  if [[ "$status" -ge 400 ]]; then
    echo "admin-bot: $status $(head -c 300 "$out")" >&2
    rm -f "$out"; exit 1
  fi
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
state = "ON" if d["enabled"] else "OFF"
print(f"{state} · bot {d[\"bot_id\"] or \"-\"}" + ("" if d["available"] else " · INSTANCE_ADMIN_EMAILS not set: unavailable"))
' "$out"
  rm -f "$out"
}

case "${1:-status}" in
  status) TOKEN="$(token)"; call GET ;;
  on)
    [[ -n "${2:-}" ]] || die "usage: admin-bot.sh on BOT_ID"
    [[ "$2" =~ ^[0-9a-fA-F-]{36}$ ]] || die "BOT_ID must be a bot's id"
    TOKEN="$(token)"; call PUT "{\"enabled\": true, \"bot_id\": \"$2\"}" ;;
  off) TOKEN="$(token)"; call PUT '{"enabled": false}' ;;
  *) die "unknown command: $1 (status | on BOT_ID | off)" ;;
esac
