#!/usr/bin/env bash
# The web error reporter (D-416) ships as four copies, one per site; they must stay equal.
#   site/errors.js is the one to edit; then: scripts/check-web-errors.sh --fix
set -euo pipefail
cd "$(dirname "$0")/.."
src=site/errors.js
copies=(docs-site/public/errors.js gallery/errors.js client/web/errors.js)
status=0
for c in "${copies[@]}"; do
  if ! cmp -s "$src" "$c"; then
    if [[ "${1:-}" == "--fix" ]]; then cp "$src" "$c"; echo "updated $c"; else echo "$c differs from $src" >&2; status=1; fi
  fi
done
exit $status
