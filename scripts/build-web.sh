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
# Every build also carries the JavaScript fallback for browsers without WasmGC (older Safari, and
# every Firefox before 147 by Flutter's own rule): main.dart.js with the CanvasKit renderer. A
# build without it leaves those browsers on the loading screen.
for f in main.dart.js canvaskit/canvaskit.js canvaskit/canvaskit.wasm canvaskit/chromium/canvaskit.js canvaskit/chromium/canvaskit.wasm; do
  if [[ ! -s "build/web/$f" ]]; then
    echo "Release web build is missing $f, the fallback for browsers without WasmGC." >&2
    exit 1
  fi
done
if ! grep -q '"compileTarget":"dart2js"' "$boot" || ! grep -q '"mainJsPath":"main.dart.js"' "$boot"; then
  echo "flutter_bootstrap.js does not offer the JavaScript fallback build." >&2
  exit 1
fi
# RevenueCat isn't used on the web (store purchases are App Store and Google Play only, D-297; the web
# app's store is NoStore), but purchases_flutter loads its 1 MB web SDK as soon as it registers,
# before the first frame. An empty file stands in, so the plugin's load still succeeds.
rc=build/web/assets/packages/purchases_flutter/assets/web/purchases_js_hybrid_mappings.js
if [[ -f "$rc" ]]; then
  echo '/* RevenueCat is not used on the web (scripts/build-web.sh). */' > "$rc"
fi
# The loading screen's progress bar (web/boot.js) counts bytes against the real sizes of the files
# a start can load: every main and renderer file Flutter picks between, plus the font manifest and
# the launch fonts. Dart, not Python or Node: the self-host image has only Flutter.
sizes_dir=$(mktemp -d)
sizes_tool="$sizes_dir/boot_files.dart"
cat > "$sizes_tool" <<'DART'
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final web = args.single;
  const candidates = [
    'main.dart.mjs', 'main.dart.wasm', 'main.dart.js',
    'canvaskit/skwasm.js', 'canvaskit/skwasm.wasm',
    'canvaskit/skwasm_heavy.js', 'canvaskit/skwasm_heavy.wasm',
    'canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm',
    'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm',
  ];
  final always = <String>['assets/FontManifest.json'];
  final manifest = jsonDecode(File('$web/assets/FontManifest.json').readAsStringSync()) as List;
  for (final family in manifest) {
    for (final font in (family as Map)['fonts'] as List) {
      always.add('assets/${(font as Map)['asset']}');
    }
  }
  final sizes = <String, int>{};
  for (final path in [...candidates, ...always]) {
    final file = File('$web/$path');
    if (file.existsSync()) sizes[path] = file.lengthSync();
  }
  stdout.write(jsonEncode({'sizes': sizes, 'always': always}));
}
DART
boot_files=$(dart "$sizes_tool" build/web)
rm -rf "$sizes_dir"
marker='/* casama-boot-files */'
if ! grep -qF "$marker" "$boot"; then
  echo "web/flutter_bootstrap.js lost its '$marker' line; the loading screen needs it." >&2
  exit 1
fi
BOOT_FILES="window.casamaBoot && casamaBoot.files($boot_files);" MARKER="$marker" \
  perl -0pi -e 's/\Q$ENV{MARKER}\E/$ENV{BOOT_FILES}/' "$boot"
grep -q 'casamaBoot.files({"sizes"' "$boot"
# The page's own error reports (web/errors.js, D-416) go to the app's Sentry project in official
# builds only; a self-host build keeps data-dsn empty and the script does nothing.
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  dsn=$(node -e 'try{process.stdout.write(require(process.argv[1]).SENTRY_DSN||"")}catch(e){}' "$PWD/config/telemetry.json")
  if [[ "$dsn" =~ ^https://[A-Za-z0-9]+@[A-Za-z0-9.-]+/[0-9]+$ ]]; then
    version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
    sed -i.bak "s#<script src=\"errors.js\" data-dsn=\"\" data-surface=\"app\">#<script src=\"errors.js\" data-dsn=\"$dsn\" data-surface=\"app\" data-release=\"casama-app@${version%%+*}\">#" build/web/index.html
    rm -f build/web/index.html.bak
    grep -q "data-dsn=\"$dsn\"" build/web/index.html || echo "build-web: warning: couldn't turn on the page's error reports." >&2
  fi
fi
echo "Wasm web build is ready (build/web/main.dart.wasm)."
# Source maps to PostHog error tracking when a key is set; otherwise a note and nothing else.
"$root/scripts/upload-symbols.sh" web build/web
