#!/usr/bin/env bash
# Packs the Linux desktop app as a snap (D-392) from the bundle scripts/package-linux.sh made.
# Run on Ubuntu 24.04 (core24), x64 or arm64:
#   scripts/package-linux.sh && scripts/package-snap.sh            # in an LXD container
#   scripts/package-snap.sh --destructive-mode                    # on a throwaway machine (CI)
# Writes dist/casama_<version>_<arch>.snap. Uploading it to the Snap Store is a release: ask first.
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(grep '^version:' client/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
case "$(uname -m)" in aarch64|arm64) arch=arm64 ;; *) arch=x64 ;; esac
tarball="dist/casama-$version-linux-$arch.tar.gz"
[ -f "$tarball" ] || { echo "No $tarball: run scripts/package-linux.sh first." >&2; exit 1; }
rm -rf build/snap-bundle && mkdir -p build/snap-bundle
tar -xzf "$tarball" -C build/snap-bundle --strip-components=1
echo "$version" > build/snap-bundle/VERSION
snapcraft pack "$@" --output "dist/"
ls dist/casama_*.snap
