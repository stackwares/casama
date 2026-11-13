#!/usr/bin/env bash
# Builds the Android App Bundle (aab) or APK.
# An APK is built per ABI (--split-per-abi): one universal APK carries three copies of every
# native library (about 330 MB). Pass `apk --no-split` for the universal one.
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

extra=()
if [[ "$target" == "apk" ]]; then
  if [[ "${1:-}" == "--no-split" ]]; then
    shift
  else
    extra+=(--split-per-abi)
  fi
fi

flutter build "$target" --release \
  --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" \
  ${defines[@]+"${defines[@]}"} \
  ${extra[@]+"${extra[@]}"} \
  "$@"
