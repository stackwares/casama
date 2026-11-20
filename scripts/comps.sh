#!/usr/bin/env bash
# Free plans for friends (docs/COMP-PLANS-PLAN.md), from a terminal.
#
#   scripts/comps.sh settings                         the switch, allowed plans and caps
#   scripts/comps.sh on | off                         switch free plans on or off
#   scripts/comps.sh list [--all]                     running free plans (--all: ended ones too)
#   scripts/comps.sh grant EMAIL PLAN MONTHS [NOTE]   give someone a plan free, e.g. grant a@b.com pro 3 "Beta friend"
#   scripts/comps.sh extend COMP_ID MONTHS            make a running free plan longer
#   scripts/comps.sh revoke COMP_ID                   end a free plan now (credits already given stay)
#   scripts/comps.sh codes                            gift codes and how often they were used
#   scripts/comps.sh code PLAN MONTHS [--uses N] [--until YYYY-MM-DD] [NOTE]
#                                                     make a gift code; it is printed once, never again
#   scripts/comps.sh disable CODE_ID                  stop a gift code from being redeemed
#
# Who you are: CASAMA_TOKEN (an instance owner's access token), or the casama CLI signed in as the
# owner. Which server: CASAMA_API_URL, else the CLI's, else https://api.casama.ai. The token goes to
# curl through a 0600 file, never on the command line.
#
# Against production, every command but settings, list and codes changes real accounts: get Oliver's
# yes first (AGENTS.md, "Production").
set -euo pipefail

die() { echo "comps: $*" >&2; exit 1; }
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

API="$(api_url)"
CURLCFG=""
cleanup() { [[ -n "$CURLCFG" ]] && rm -f "$CURLCFG"; return 0; }
trap cleanup EXIT HUP INT TERM

auth() {
  CURLCFG="$(mktemp)"
  chmod 600 "$CURLCFG"
  if [[ -n "${CASAMA_TOKEN:-}" ]]; then
    TOKEN_SOURCE=env python3 - "$CURLCFG" <<'PY'
import os, pathlib, sys
v = os.environ["CASAMA_TOKEN"].strip()
if not v or any(c in v for c in '\r\n"\\'):
    raise SystemExit("comps: invalid CASAMA_TOKEN")
pathlib.Path(sys.argv[1]).write_text('header = "Authorization: Bearer ' + v + '"\n')
PY
    return
  fi
  command -v casama >/dev/null || die "set CASAMA_TOKEN, or install the casama CLI and run: casama login"
  casama --api "$API" whoami >/dev/null 2>&1 || die "not signed in: run casama login as the instance owner"
  python3 - "$CONFIG_DIR/session.json" "$CURLCFG" <<'PY' || die "couldn't read the CLI's session"
import json, pathlib, sys
v = json.load(open(sys.argv[1]))["access_token"].strip()
if not v or any(c in v for c in '\r\n"\\'):
    raise SystemExit(1)
pathlib.Path(sys.argv[2]).write_text('header = "Authorization: Bearer ' + v + '"\n')
PY
}

# call METHOD PATH [JSON] -> prints the response body; exits on an error status.
call() {
  local method="$1" path="$2" body="${3:-}" out status
  out="$(mktemp)"
  if [[ -n "$body" ]]; then
    status=$(curl -sS --config "$CURLCFG" -o "$out" -w '%{http_code}' -X "$method" "$API$path" \
      -H 'content-type: application/json' --data-binary "$body")
  else
    status=$(curl -sS --config "$CURLCFG" -o "$out" -w '%{http_code}' -X "$method" "$API$path")
  fi
  if [[ "$status" -ge 400 ]]; then
    python3 - "$out" "$status" <<'PY' >&2
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(f"comps: {sys.argv[2]} {d.get('code', '')}: {d.get('detail') or d.get('title') or ''}")
except Exception:
    print(f"comps: {sys.argv[2]} " + open(sys.argv[1]).read()[:300])
PY
    rm -f "$out"; exit 1
  fi
  cat "$out"; rm -f "$out"
}

json() { python3 -c 'import json,sys; print(json.dumps(dict(zip(sys.argv[1::2], [json.loads(v) for v in sys.argv[2::2]]))))' "$@"; }
str() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }
# Checked in the main shell (a failed check inside $(...) wouldn't stop the script).
need_int() { [[ "$1" =~ ^[0-9]+$ ]] || die "$2 must be a whole number"; }
need_uuid() { [[ "$1" =~ ^[0-9a-fA-F-]{36}$ ]] || die "$2 must be an id"; }

PRINT_COMPS=$(cat <<'PY'
import json, sys
rows = json.load(sys.stdin)
rows = rows if isinstance(rows, list) else [rows]
if not rows:
    print("No free plans.")
for c in rows:
    state = "running" if not c["ended_at"] else c["end_reason"]
    line = "{}  {:<5} {:>2} mo  until {}  {:<20} {}  {}  [{}]".format(
        c["id"], c["plan_code"], c["months"], c["ends_at"][:10], state,
        c.get("email") or "-", c.get("org_name") or "", c["from"])
    if c.get("note"):
        line += "  " + c["note"]
    print(line)
PY
)
PRINT_CODES=$(cat <<'PY'
import json, sys
rows = json.load(sys.stdin)
rows = rows if isinstance(rows, list) else [rows]
if not rows:
    print("No gift codes.")
for c in rows:
    until = (c.get("redeem_by") or "")[:10] or "no end"
    line = "{}  {:<6} {:<5} {:>2} mo  used {}/{}  redeem by {}  {}".format(
        c["id"], c["hint"], c["plan_code"], c["months"], c["redeemed_count"],
        c["max_redemptions"], until, "disabled" if c["disabled"] else "active")
    if c.get("note"):
        line += "  " + c["note"]
    print(line)
PY
)
PRINT_NEW_CODE=$(cat <<'PY'
import json, sys
c = json.load(sys.stdin)
print("Gift code (shown once): " + c["code"])
print("Link: " + c["link"])
print("{} for {} months, {} use(s), id {}".format(c["plan_code"], c["months"], c["max_redemptions"], c["id"]))
print("Friends redeem it on the web (app.casama.ai or the link), never in the store apps.")
PY
)
print_comps() { python3 -c "$PRINT_COMPS"; }
print_codes() { python3 -c "$PRINT_CODES"; }

cmd="${1:-list}"; shift || true
case "$cmd" in
  settings)
    auth; call GET /v1/admin/comp-settings | python3 -m json.tool ;;
  on|off)
    auth
    cur="$(call GET /v1/admin/comp-settings)"
    body="$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); d["enabled"]=sys.argv[2]=="on"; print(json.dumps(d))' "$cur" "$cmd")"
    call PUT /v1/admin/comp-settings "$body" | python3 -m json.tool ;;
  list)
    auth
    if [[ "${1:-}" == "--all" ]]; then call GET "/v1/admin/comps?limit=500" | print_comps
    else call GET "/v1/admin/comps?running=true&limit=500" | print_comps; fi ;;
  grant)
    [[ $# -ge 3 ]] || die "usage: comps.sh grant EMAIL PLAN MONTHS [NOTE]"
    need_int "$3" MONTHS
    auth
    if [[ -n "${4:-}" ]]; then body="$(json email "$(str "$1")" plan_code "$(str "$2")" months "$3" note "$(str "$4")")"
    else body="$(json email "$(str "$1")" plan_code "$(str "$2")" months "$3")"; fi
    call POST /v1/admin/comps "$body" | print_comps ;;
  extend)
    [[ $# -eq 2 ]] || die "usage: comps.sh extend COMP_ID MONTHS"
    need_uuid "$1" COMP_ID; need_int "$2" MONTHS
    auth
    call PATCH "/v1/admin/comps/$1" "$(json extend_months "$2")" | print_comps ;;
  revoke)
    [[ $# -eq 1 ]] || die "usage: comps.sh revoke COMP_ID"
    need_uuid "$1" COMP_ID
    auth
    call PATCH "/v1/admin/comps/$1" '{"revoke": true}' | print_comps ;;
  codes)
    auth; call GET /v1/admin/comp-codes | print_codes ;;
  code)
    [[ $# -ge 2 ]] || die "usage: comps.sh code PLAN MONTHS [--uses N] [--until YYYY-MM-DD] [NOTE]"
    need_int "$2" MONTHS
    plan="$1"; months="$2"; shift 2
    uses=1; until=""; note=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --uses) need_int "${2:-}" --uses; uses="$2"; shift 2 ;;
        --until) [[ "${2:-}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "--until takes YYYY-MM-DD"; until="${2}T23:59:59Z"; shift 2 ;;
        *) note="$1"; shift ;;
      esac
    done
    auth
    body="$(python3 -c '
import json, sys
plan, months, uses, until, note = sys.argv[1:]
d = {"plan_code": plan, "months": int(months), "max_redemptions": int(uses)}
if until: d["redeem_by"] = until
if note: d["note"] = note
print(json.dumps(d))' "$plan" "$months" "$uses" "$until" "$note")"
    call POST /v1/admin/comp-codes "$body" | python3 -c "$PRINT_NEW_CODE" ;;
  disable)
    [[ $# -eq 1 ]] || die "usage: comps.sh disable CODE_ID"
    need_uuid "$1" CODE_ID
    auth
    call PATCH "/v1/admin/comp-codes/$1" '{"disabled": true}' | print_codes ;;
  -h|--help|help) sed -n '2,20p' "$0" ;;
  *) die "unknown command: $cmd (see scripts/comps.sh help)" ;;
esac
