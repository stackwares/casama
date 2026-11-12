#!/usr/bin/env bash
# Builds the Linux desktop app as a tar.gz bundle (run on Linux with Flutter's Linux toolchain).
set -euo pipefail
cd "$(dirname "$0")/../client"
defines=()
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  defines+=(--dart-define-from-file=config/telemetry.json)
fi
flutter build linux --release --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" "${defines[@]}"
mkdir -p ../dist
tar -C build/linux/x64/release -czf "../dist/casama-$version-linux-x64.tar.gz" bundle
echo "../dist/casama-$version-linux-x64.tar.gz"
