#!/usr/bin/env bash
# Builds the kasama CLI as a native binary for this machine into dist/ (CI builds every platform,
# see .github/workflows/release.yml). Usage: scripts/release-cli.sh
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(grep '^version:' dart/cli/pubspec.yaml | awk '{print $2}')
grep -q "cliVersion = '$version'" dart/cli/lib/src/runner.dart || { echo "cliVersion in runner.dart must be $version"; exit 1; }
os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m); [[ "$arch" == "x86_64" ]] && arch=x64
mkdir -p dist
out="dist/kasama-$version-$os-$arch"
mkdir -p "$out"
(cd dart/cli && dart compile exe bin/kasama.dart -o "../../$out/kasama" >/dev/null)
tar -C "$out" -czf "$out.tar.gz" kasama
shasum -a 256 "$out.tar.gz" | tee "$out.tar.gz.sha256"
"$out/kasama" --version
