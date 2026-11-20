#!/bin/sh
# Uses the caller's instance-owner bearer token. Never echoes credentials.
set -eu
: "${CASAMA_API_URL:?Set the API URL}"
: "${CASAMA_ACCESS_TOKEN_FILE:?Set a file containing an instance-owner access token}"
method=${1:-GET}
route=${2:-/v1/admin/limit-resets}
case "$route" in /v1/admin/limit-resets|/v1/admin/limit-resets/*) ;; *) printf '%s\n' 'Only admin saved-reset routes are supported' >&2; exit 2;; esac
# Keep the token out of process arguments as well as shell tracing.
config=$(mktemp)
chmod 600 "$config"
trap 'rm -f "$config"' EXIT HUP INT TERM
python3 - "$CASAMA_ACCESS_TOKEN_FILE" "$config" <<'PY'
import pathlib,sys
value=pathlib.Path(sys.argv[1]).read_text().strip()
if not value or any(c in value for c in '\r\n"\\'):
    raise SystemExit('Invalid token file')
pathlib.Path(sys.argv[2]).write_text('header = "Authorization: Bearer '+value+'"\n')
PY
if [ "$#" -ge 3 ]; then
  curl --fail-with-body --silent --show-error --config "$config" -X "$method" -H 'Content-Type: application/json' --data-binary "@$3" "${CASAMA_API_URL%/}$route"
else
  curl --fail-with-body --silent --show-error --config "$config" -X "$method" "${CASAMA_API_URL%/}$route"
fi
