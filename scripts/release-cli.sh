#!/usr/bin/env bash
# Builds the casama CLI as a native binary for this machine into dist/ (CI builds every platform,
# see .github/workflows/release.yml). Usage: scripts/release-cli.sh
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(grep '^version:' dart/cli/pubspec.yaml | awk '{print $2}')
grep -q "cliVersion = '$version'" dart/cli/lib/src/runner.dart || { echo "cliVersion in runner.dart must be $version"; exit 1; }
os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m); [[ "$arch" == "x86_64" ]] && arch=x64
mkdir -p dist
out="dist/casama-$version-$os-$arch"
mkdir -p "$out"
(cd dart/cli && dart compile exe bin/casama.dart -o "../../$out/casama" >/dev/null)
tar -C "$out" -czf "$out.tar.gz" casama
shasum -a 256 "$out.tar.gz" | tee "$out.tar.gz.sha256"
"$out/casama" --version
