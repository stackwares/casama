#!/usr/bin/env bash
# Builds the Linux desktop app as a tar.gz bundle (run on Linux with Flutter's Linux toolchain).
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
flutter build linux --release --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://cloud.casama.ai}"
mkdir -p ../dist
tar -C build/linux/x64/release -czf "../dist/casama-$version-linux-x64.tar.gz" bundle
echo "../dist/casama-$version-linux-x64.tar.gz"
