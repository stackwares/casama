#!/usr/bin/env bash
# Builds the Linux desktop app as a tar.gz bundle (run on Linux with Flutter's Linux toolchain).
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
defines=()
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  defines+=(--dart-define-from-file=config/telemetry.json)
fi
# The MapTiler key for bots' map cards (D-310); without it maps use OpenStreetMap's own tiles.
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/maps.json ]]; then
  defines+=(--dart-define-from-file=config/maps.json)
fi
flutter build linux --release --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" "${defines[@]}"
case "$(uname -m)" in aarch64|arm64) arch=arm64 ;; *) arch=x64 ;; esac
mkdir -p ../dist
tar -C "build/linux/$arch/release" -czf "../dist/casama-$version-linux-$arch.tar.gz" bundle
echo "../dist/casama-$version-linux-$arch.tar.gz"
