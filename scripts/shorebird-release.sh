#!/usr/bin/env bash
# Shorebird release flow: `release` for each store build, `patch` for urgent Dart-only fixes.
#   scripts/shorebird-release.sh release ios|android
#   scripts/shorebird-release.sh patch ios|android
set -euo pipefail
cd "$(dirname "$0")/../client"
command -v shorebird >/dev/null || { echo "Install the Shorebird CLI: https://docs.shorebird.dev"; exit 1; }
grep -q REPLACE_WITH shorebird.yaml && { echo "Run 'shorebird init' first to set app_id"; exit 1; }
action="${1:?release or patch}"; platform="${2:?ios or android}"
api="${CASAMA_API_URL:-https://cloud.casama.ai}"
shorebird "$action" "$platform" -- --dart-define=CASAMA_API_URL="$api"
