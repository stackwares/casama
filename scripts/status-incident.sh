#!/usr/bin/env bash
# Sets or clears the incident note on status.casama.ai (D-304).
#   scripts/status-incident.sh set "Title" "What's happening and what we're doing" [minor|major]
#   scripts/status-incident.sh clear
# Production infrastructure: get Oliver's yes before using it (AGENTS.md).
set -euo pipefail
cd "$(dirname "$0")/../infra/uptime"
case "${1:-}" in
  set)
    title="${2:?title}"; body="${3:-}"; severity="${4:-minor}"
    json=$(python3 -c 'import json,sys,time; print(json.dumps({"title": sys.argv[1], "body": sys.argv[2], "severity": sys.argv[3], "started": int(time.time()*1000)}))' "$title" "$body" "$severity")
    wrangler kv key put --remote --binding STATE incident "$json"
    echo "Incident shown on https://status.casama.ai" ;;
  clear)
    wrangler kv key delete --remote --binding STATE incident
    echo "Incident cleared" ;;
  *) echo "usage: $0 set <title> [body] [minor|major] | clear" >&2; exit 1 ;;
esac
