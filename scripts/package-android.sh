#!/usr/bin/env bash
# Builds the Android App Bundle (aab) or APK.
# Official builds pass telemetry credentials when CASAMA_OFFICIAL_BUILD=1.
set -euo pipefail
cd "$(dirname "$0")/../client"

defines=()
if [[ -f config/firebase.json ]]; then
  defines+=(--dart-define-from-file=config/firebase.json)
fi
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  defines+=(--dart-define-from-file=config/telemetry.json)
fi

target="${1:-appbundle}"
shift || true

flutter build "$target" --release \
  --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" \
  "${defines[@]}" \
  "$@"
