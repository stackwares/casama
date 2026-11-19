#!/usr/bin/env bash
# Publishes the Flutter web app in client/build/web to app.casama.ai (D-193, D-316). Production:
# ask Oliver first (AGENTS.md). Needs `wrangler login` on the Stackwares account.
#
# It does not build. Build first with scripts/build-web.sh (Wasm, D-196); that build is a separate
# yes. Files of 25 MiB or more (Cloudflare's per-asset limit, usually main.dart.wasm or
# main.dart.js) go to the R2 bucket casama-app-large and the casama-app Worker serves them from
# there; everything else stays static assets. Source maps are never published.
#
#   scripts/deploy-app-web.sh --dry-run   show what goes where, change nothing
#   scripts/deploy-app-web.sh             same, then ask before publishing
#   scripts/deploy-app-web.sh --yes       publish without asking
set -euo pipefail
cd "$(dirname "$0")/../client"

BUCKET=casama-app-large
URL=https://app.casama.ai
mode=ask
case "${1:-}" in
  --dry-run) mode=dry ;;
  --yes) mode=yes ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run|--yes]" >&2; exit 2 ;;
esac

if [[ ! -s build/web/main.dart.wasm || ! -s build/web/index.html ]]; then
  echo "No web build in client/build/web. Run scripts/build-web.sh first." >&2
  exit 1
fi
# Both builds ship, always: Wasm for current browsers and the JavaScript fallback (main.dart.js +
# CanvasKit) for browsers without WasmGC, such as older Safari and Firefox before 147.
FILES_WASM=(main.dart.wasm main.dart.mjs canvaskit/skwasm.js canvaskit/skwasm.wasm canvaskit/skwasm_heavy.js canvaskit/skwasm_heavy.wasm)
FILES_FALLBACK=(main.dart.js canvaskit/canvaskit.js canvaskit/canvaskit.wasm canvaskit/chromium/canvaskit.js canvaskit/chromium/canvaskit.wasm)
for f in "${FILES_WASM[@]}" "${FILES_FALLBACK[@]}"; do
  [[ -s "build/web/$f" ]] || { echo "This build is missing $f; rebuild with scripts/build-web.sh." >&2; exit 1; }
done
grep -q '"compileTarget":"dart2js"' build/web/flutter_bootstrap.js || {
  echo "This build's flutter_bootstrap.js doesn't offer the JavaScript fallback; rebuild with scripts/build-web.sh." >&2
  exit 1
}
# app.casama.ai must talk to Casama Cloud. A build without CASAMA_API_URL falls back to
# http://localhost:8787 and shows "Can't reach your Casama server" to everyone (2026-11-16), and
# one without the official config has no analytics or web push. Build it with:
#   CASAMA_OFFICIAL_BUILD=1 scripts/build-web.sh --dart-define=CASAMA_API_URL=https://api.casama.ai \
#     --dart-define-from-file=config/firebase.json --dart-define-from-file=config/telemetry.json
missing=()
# The fallback address is only compiled in when CASAMA_API_URL wasn't given.
LC_ALL=C grep -qaF 'http://localhost:8787' build/web/main.dart.wasm && missing+=("CASAMA_API_URL=https://api.casama.ai")
for f in firebase.json telemetry.json; do
  first=$(node -e "const v=Object.values(require('./config/$f'))[0]; console.log(String(v))" 2>/dev/null || true)
  [[ -n "$first" ]] && ! LC_ALL=C grep -qaF -- "$first" build/web/main.dart.wasm && missing+=("config/$f")
done
if (( ${#missing[@]} )); then
  echo "This web build isn't the official one; it lacks: ${missing[*]}." >&2
  echo "Rebuild with: CASAMA_OFFICIAL_BUILD=1 scripts/build-web.sh --dart-define=CASAMA_API_URL=https://api.casama.ai --dart-define-from-file=config/firebase.json --dart-define-from-file=config/telemetry.json" >&2
  exit 1
fi
version=$(sed -n 's/.*"version":"\([^"]*\)".*"build_number":"\([^"]*\)".*/\1+\2/p' build/web/version.json)
echo "Build: ${version:-unknown}, made $(date -r build/web/main.dart.wasm '+%Y-%m-%d %H:%M')"
# Build numbers only go up, shared by every platform (pass --build-number, or keep the pubspec
# current). A rollback is `wrangler rollback` in client/, not an older build.
build=${version##*+}
live=$(curl -fsS --max-time 10 https://app.casama.ai/version.json 2>/dev/null | sed -n 's/.*"build_number":"\([0-9]*\)".*/\1/p')
echo "Live: build ${live:-unknown}"
if [[ -n "$live" && "$build" =~ ^[0-9]+$ ]] && (( build <= live )); then
  echo "Build $build isn't newer than the live build $live. Rebuild with the next build number shared by all platforms (at least $((live + 1)))." >&2
  exit 1
fi

node cloudflare/prepare.mjs
echo "Static assets: $(cd build/web && find . -type f ! -name '*.map' ! -name .assetsignore | grep -cvxFf <(sed 's|^|./|' .assetsignore)) files"

[[ "$mode" == dry ]] && { echo "Dry run: nothing published."; exit 0; }
if [[ "$mode" == ask ]]; then
  read -r -p "Publish ${version:-this build} to $URL now? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
fi

# Upload before deploying so the new Worker never names an object that isn't there yet. Keys are
# content-named, so old ones stay for rollbacks (about 0.1 GB a deploy; R2 storage only).
if [[ -s build/web-host/uploads.tsv ]]; then
  wrangler r2 bucket info "$BUCKET" >/dev/null 2>&1 || wrangler r2 bucket create "$BUCKET"
  while IFS=$'\t' read -r key file type; do
    wrangler r2 object put "$BUCKET/$key" --file "$file" --content-type "$type" --remote
  done < build/web-host/uploads.tsv
fi
wrangler deploy

# Check that every large file now answers from R2 with the right type.
fail=0
for path in $(node -e 'console.log(Object.keys(require("./build/web-host/large-files.json")).join(" "))'); do
  want=$(node -e "console.log(require('./build/web-host/large-files.json')['$path'].type)")
  got=$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -H 'Accept-Encoding: br' "$URL$path")
  if [[ "$got" == "200 $want"* ]]; then echo "OK $path ($got)"; else echo "FAILED $path: $got" >&2; fail=1; fi
done
# Both builds answer live, whether from static assets or R2.
for f in "${FILES_WASM[@]}" "${FILES_FALLBACK[@]}"; do
  case "$f" in *.wasm) want=application/wasm ;; *) want=text/javascript ;; esac
  got=$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -H 'Accept-Encoding: br' "$URL/$f")
  if [[ "$got" == "200 $want"* ]]; then echo "OK /$f"; else echo "FAILED /$f: $got" >&2; fail=1; fi
done
curl -fsS "$URL/flutter_bootstrap.js" | grep -q '"compileTarget":"dart2js"' || {
  echo "FAILED: the live flutter_bootstrap.js doesn't offer the JavaScript fallback." >&2
  fail=1
}
live=$(curl -s "$URL/version.json")
echo "Live version.json: $live"
[[ $fail == 0 ]] || { echo "A large file isn't served right. Roll back with: (cd client && wrangler rollback)" >&2; exit 1; }
echo "Published: $URL"
