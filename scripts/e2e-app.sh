#!/usr/bin/env bash
# Runs the Flutter app's end-to-end test against a local stack:
#   supabase start            (real Auth, Realtime, Storage)
#   API + worker              (node --env-file=.env apps/server/src/main.ts, MODE=api and MODE=worker,
#                              with KASAMA_MODEL_FIXTURES so no model key is needed)
# Usage: scripts/e2e-app.sh [device]   (default: macos; also an iOS simulator id, emulator-5554, or "web")
# E2E_LIVE=1 also runs the live-view test; the API then needs SUPERVISOR_URL/TOKEN and TURN_* set and
# the desktop computer image built (WebRTC needs the TURN port reachable from the device: macOS and
# the iOS Simulator use 127.0.0.1; the Android emulator would need TURN_PUBLIC_HOST=10.0.2.2).
set -euo pipefail
cd "$(dirname "$0")/../client"
device="${1:-macos}"
curl -sf http://localhost:8787/readyz >/dev/null || { echo "API not running on :8787"; exit 1; }
if [[ "$device" == emulator-* ]]; then
  adb -s "$device" reverse tcp:8787 tcp:8787
  adb -s "$device" reverse tcp:54321 tcp:54321
fi
if [[ "$device" == "web" ]]; then
  : "${CHROMEDRIVER:?set CHROMEDRIVER to a chromedriver binary}" "${CHROME_BINARY:?set CHROME_BINARY to a Chrome for Testing binary}"
  "$CHROMEDRIVER" --port=4444 >/dev/null 2>&1 &
  driver=$!
  trap 'kill $driver' EXIT
  sleep 2
  flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart \
    -d web-server --browser-name=chrome --chrome-binary="$CHROME_BINARY" --headless --web-port=3000
else
  flutter test integration_test/app_flow_test.dart -d "$device"
  if [[ "${E2E_LIVE:-0}" == "1" ]]; then
    flutter test integration_test/live_flow_test.dart -d "$device"
  fi
fi
