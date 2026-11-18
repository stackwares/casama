#!/usr/bin/env bash
# Release build of the Flutter web app. Always WebAssembly (D-196).
#
# CI, the self-host image (client/Dockerfile.web) and any deploy or publish of
# the web app must run this script. It is the only `flutter build web` in the
# repository outside the docs, and it refuses to finish unless the Wasm build
# is what the page will load.
#
# Extra Flutter arguments are passed through, for example:
#   scripts/build-web.sh --dart-define=CASAMA_API_URL=
# Flags that would turn Wasm off are dropped. `flutter run` is unchanged and
# stays on the debug compiler so hot reload keeps working.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

# In a checkout, fail if some other file learned to compile the web app on
# its own. The image build copies this script without the git checkout, so
# that build relies on this script being the command the Dockerfile runs.
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pattern='flutter build web'
  bad=$(git -C "$root" grep -n -e "$pattern" -- . \
    ':(exclude)docs' \
    ':(exclude)docs-site' \
    ':(exclude)client/docs' \
    ':(exclude)scripts/build-web.sh' || true)
  if [[ -n "$bad" ]]; then
    echo "Release, deploy and publish builds of the web app must run scripts/build-web.sh so they stay Wasm." >&2
    printf '%s\n' "$bad" >&2
    exit 1
  fi
  grep -q -- '--wasm' "$root/scripts/build-web.sh"
  grep -q 'build-web.sh' "$root/client/Dockerfile.web"
  grep -q 'build-web.sh' "$root/.github/workflows/ci.yml"
fi

cd "$root/client"
flutter pub get

extra=()
for arg in "$@"; do
  case "$arg" in
    --wasm|--no-wasm) ;;
    *) extra+=("$arg") ;;
  esac
done
# The MapTiler key for bots' map cards (D-310); without it maps use OpenStreetMap's own tiles.
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/maps.json ]]; then
  extra+=(--dart-define-from-file=config/maps.json)
fi
# --wasm stays last so it wins if a caller also passed a flag that turns it off.
flutter build web --release ${extra[@]+"${extra[@]}"} --wasm

boot=build/web/flutter_bootstrap.js
if [[ ! -s build/web/main.dart.wasm || ! -s build/web/main.dart.mjs ]]; then
  echo "Release web build did not produce the Wasm output." >&2
  exit 1
fi
if ! grep -q 'dart2wasm' "$boot" || ! grep -q 'main.dart.wasm' "$boot"; then
  echo "flutter_bootstrap.js does not offer the Wasm build." >&2
  exit 1
fi
# RevenueCat isn't used on the web (store purchases are App Store and Google Play only, D-297; the web
# app's store is NoStore), but purchases_flutter loads its 1 MB web SDK as soon as it registers,
# before the first frame. An empty file stands in, so the plugin's load still succeeds.
rc=build/web/assets/packages/purchases_flutter/assets/web/purchases_js_hybrid_mappings.js
if [[ -f "$rc" ]]; then
  echo '/* RevenueCat is not used on the web (scripts/build-web.sh). */' > "$rc"
fi
echo "Wasm web build is ready (build/web/main.dart.wasm)."
# Source maps to PostHog error tracking when a key is set; otherwise a note and nothing else.
"$root/scripts/upload-symbols.sh" web build/web
