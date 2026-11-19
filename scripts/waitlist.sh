#!/usr/bin/env bash
# The waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md), from a terminal.
# It calls the owner-only routes as the signed-in instance owner.
#
#   scripts/waitlist.sh stats                         the funnel, today and in total
#   scripts/waitlist.sh list [waiting|queued|admitted|joined] [--source S] [--self-hosting] [--q TEXT] [--limit N]
#   scripts/waitlist.sh admit N [--source S] [--ref R] [--self-hosting]
#                                                     choose the next N for a "You're in" email
#   scripts/waitlist.sh admit-ids ID...               choose these entries
#   scripts/waitlist.sh add EMAIL... [--notify]       let addresses in by hand (--notify: email them)
#   scripts/waitlist.sh remove ID                     remove an entry (its address is shut out again)
#   scripts/waitlist.sh code list
#   scripts/waitlist.sh code create CODE "Label" MAX [--per-day N] [--starts ISO] [--expires ISO]
#   scripts/waitlist.sh code set CODE [--max N] [--per-day N|none] [--starts ISO|none] [--expires ISO|none] [--on|--off]
#   scripts/waitlist.sh gate                          show the gate
#   scripts/waitlist.sh on                            new accounts by invitation only
#   scripts/waitlist.sh open                          open sign-up to everyone
#   scripts/waitlist.sh opens-at ISO|none             open by itself at this time
#   scripts/waitlist.sh set invites_per_person|daily_admit|daily_emails_max N
#
# Who you are: CASAMA_TOKEN (an owner's access token), or the casama CLI signed in as the owner
# (casama login). Which server: CASAMA_API_URL, else the CLI's, else https://api.casama.ai.
#
# Everything except stats, list, gate and "code list" changes production: get Oliver's yes first
# (AGENTS.md, "Ask before any production deploy").
set -euo pipefail

die() { echo "waitlist: $*" >&2; exit 1; }
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
  # Any signed-in call refreshes a session that ran out.
  casama --api "$API" whoami >/dev/null 2>&1 || die "not signed in: run casama login as the instance owner"
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["access_token"])' "$CONFIG_DIR/session.json" \
    || die "couldn't read the CLI's session"
}

API="$(api_url)"

# call METHOD PATH [JSON]: prints the body; fails with the server's own words on an error.
call() {
  local method="$1" path="$2" body="${3:-}" out status
  out="$(mktemp)"
  if [[ -n "$body" ]]; then
    status=$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$API$path" \
      -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' --data "$body")
  else
    status=$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$API$path" -H "authorization: Bearer $TOKEN")
  fi
  if [[ "$status" -ge 400 ]]; then
    python3 - "$out" "$status" <<'PY' >&2
import json, sys
raw = open(sys.argv[1]).read()
try:
    p = json.loads(raw)
    print(f"waitlist: {sys.argv[2]} {p.get('code', '')}: {p.get('detail') or p.get('title') or raw}")
except Exception:
    print(f"waitlist: {sys.argv[2]}: {raw[:300]}")
PY
    rm -f "$out"; exit 1
  fi
  cat "$out"; rm -f "$out"
}

# json KEY=VALUE...: a JSON object. VALUE is taken as JSON when it parses (numbers, true, null,
# arrays), else as a string.
json() {
  python3 - "$@" <<'PY'
import json, sys
o = {}
for a in sys.argv[1:]:
    k, v = a.split("=", 1)
    try:
        o[k] = json.loads(v)
    except Exception:
        o[k] = v
print(json.dumps(o))
PY
}

none_or() { [[ "$1" == "none" ]] && echo null || echo "\"$1\""; }

# show KIND: prints the JSON on stdin for people.
read -r -d '' SHOW <<'PY' || true
import json, sys

kind = sys.argv[1]
raw = sys.stdin.read()
if not raw.strip():  # the call failed and already said why
    sys.exit(1)
d = json.loads(raw)


def gate_lines(g):
    gate = g["gate"]
    print("INVITE-ONLY: new accounts by invitation" if g["closed"] else "OPEN: anyone can sign up")
    print(f"  mode {gate['mode']} · opens at {gate['opens_at'] or '-'}")
    print(
        f"  invites per member {gate['invites_per_person']} · daily batch {gate['daily_admit']}"
        f" · emails a day at most {gate['daily_emails_max']}"
    )


def table(title, rows):
    if not rows:
        return
    print()
    print(f"{title:<28}{'listed':>8}{'let in':>8}{'signed up':>11}{'first chat':>12}")
    for r in rows:
        print(f"{r['key'][:27]:<28}{r['listed']:>8}{r['admitted']:>8}{r['joined']:>11}{r['first_chat']:>12}")


def campaign(c):
    extra = [
        f"{c['per_day']} a day" if c["per_day"] else "",
        f"from {c['starts_at'][:16]}" if c["starts_at"] else "",
        f"until {c['expires_at'][:16]}" if c["expires_at"] else "",
        "OFF" if c["disabled"] else "",
    ]
    print(f"{c['code']:<24}{c['used']:>6} of {c['max_uses']:<8}{c['label']}  {' '.join(x for x in extra if x)}")
    print(f"    {c['link']}")


if kind == "stats":
    s = d["stats"]
    gate_lines(d["gate"])
    print()
    print(
        f"Waiting {s['waiting']} · chosen, email on its way {s['queued']} · let in {s['admitted']}"
        f" · signed up {s['joined']} · first chat {s['first_chat']}"
    )
    print(
        f"Today: joined the list {s['listed_today']} · let in {s['admitted_today']}"
        f" · \"You're in\" emails {s['emails_today']}"
    )
    table("Where they joined from", s["by_source"])
    table("How they got in", s["by_via"])
elif kind == "entries":
    for e in d["items"]:
        flags = [
            "self-hosting" if e["self_hosting"] else "",
            f"code {e['invite_code']}" if e["invite_code"] else "",
            e["admitted_via"] or "",
        ]
        print(
            f"{e['id']}  {e['status']:<9}{e['email']:<36}{(e['source'] or '-'):<12}"
            f"{e['created_at'][:10]}  {' '.join(x for x in flags if x)}"
        )
        if e["note"]:
            print(f"    \"{e['note']}\"")
elif kind == "campaigns":
    for c in d["items"] if "items" in d else [d]:
        campaign(c)
elif kind == "gate":
    gate_lines(d)
elif kind == "chosen":
    print(f"Chosen: {d['count']}. They are let in as their emails go out, a few a minute.")
elif kind == "added":
    skipped = f" Not addresses: {', '.join(d['skipped'])}" if d.get("skipped") else ""
    print(f"Let in: {d['count']}.{skipped}")
PY
show() { python3 -c "$SHOW" "$1"; }

cmd="${1:-}"; shift || true
case "$cmd" in ""|-h|--help|help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; esac
TOKEN="$(token)"

case "$cmd" in
  stats) call GET "/v1/admin/waitlist?limit=1" | show stats ;;
  list)
    q="limit=50"
    case "${1:-}" in waiting|queued|admitted|joined) q="$q&status=$1"; shift ;; esac
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --source) q="$q&source=$2"; shift 2 ;;
        --self-hosting) q="$q&self_hosting=true"; shift ;;
        --q) q="$q&q=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$2")"; shift 2 ;;
        --limit) q="${q/limit=50/limit=$2}"; shift 2 ;;
        *) die "unknown option $1" ;;
      esac
    done
    call GET "/v1/admin/waitlist?$q" | show entries ;;
  admit)
    n="${1:?how many}"; shift; args=("count=$n")
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --source) args+=("source=\"$2\""); shift 2 ;;
        --ref) args+=("ref=\"$2\""); shift 2 ;;
        --self-hosting) args+=("self_hosting=true"); shift ;;
        *) die "unknown option $1" ;;
      esac
    done
    call POST /v1/admin/waitlist/admit "$(json "${args[@]}")" | show chosen ;;
  admit-ids)
    [[ $# -gt 0 ]] || die "give the entry ids"
    ids=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "$@")
    call POST /v1/admin/waitlist/admit "{\"ids\": $ids}" | show chosen ;;
  add)
    notify=false; emails=()
    for a in "$@"; do if [[ "$a" == "--notify" ]]; then notify=true; else emails+=("$a"); fi; done
    [[ ${#emails[@]} -gt 0 ]] || die "give at least one address"
    list=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${emails[@]}")
    call POST /v1/admin/waitlist/entries "{\"emails\": $list, \"notify\": $notify}" | show added ;;
  remove) call DELETE "/v1/admin/waitlist/entries/${1:?entry id}" >/dev/null; echo "Removed." ;;
  code)
    sub="${1:-list}"; shift || true
    case "$sub" in
      list) call GET /v1/admin/invite-campaigns | show campaigns ;;
      create)
        code="${1:?code}"; label="${2:?label}"; max="${3:?total}"; shift 3
        args=("code=\"$code\"" "label=\"$label\"" "max_uses=$max")
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --per-day) args+=("per_day=$2"); shift 2 ;;
            --starts) args+=("starts_at=\"$2\""); shift 2 ;;
            --expires) args+=("expires_at=\"$2\""); shift 2 ;;
            *) die "unknown option $1" ;;
          esac
        done
        call POST /v1/admin/invite-campaigns "$(json "${args[@]}")" | show campaigns ;;
      set)
        code="${1:?code}"; shift; args=()
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --max) args+=("max_uses=$2"); shift 2 ;;
            --per-day) args+=("per_day=$([[ "$2" == none ]] && echo null || echo "$2")"); shift 2 ;;
            --starts) args+=("starts_at=$(none_or "$2")"); shift 2 ;;
            --expires) args+=("expires_at=$(none_or "$2")"); shift 2 ;;
            --on) args+=("disabled=false"); shift ;;
            --off) args+=("disabled=true"); shift ;;
            *) die "unknown option $1" ;;
          esac
        done
        [[ ${#args[@]} -gt 0 ]] || die "nothing to change"
        call PATCH "/v1/admin/invite-campaigns/$code" "$(json "${args[@]}")" | show campaigns ;;
      *) die "code list | create | set" ;;
    esac ;;
  gate) call GET /v1/admin/signup-gate | show gate ;;
  on) call PUT /v1/admin/signup-gate '{"mode":"invite_only"}' | show gate ;;
  open) call PUT /v1/admin/signup-gate '{"mode":"open","opens_at":null}' | show gate ;;
  opens-at) call PUT /v1/admin/signup-gate "{\"opens_at\": $(none_or "${1:?a time, or none}")}" | show gate ;;
  set)
    case "${1:-}" in invites_per_person|daily_admit|daily_emails_max) ;; *) die "set invites_per_person|daily_admit|daily_emails_max N" ;; esac
    call PUT /v1/admin/signup-gate "{\"$1\": ${2:?a number}}" | show gate ;;
  *) die "unknown command: $cmd (try: scripts/waitlist.sh help)" ;;
esac
