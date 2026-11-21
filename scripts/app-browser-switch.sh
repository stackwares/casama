#!/usr/bin/env bash
# Compiles the browser inside the phone app in or out (docs/PHONE-BROWSER-PLAN.md §8.7).
#
# The feature has three parts and each needs its own switch:
#   Dart     --dart-define=CASAMA_APP_BROWSER=true          (printed by `on`; add it to the build)
#   iOS      client/ios/Flutter/AppBrowser.xcconfig         (written here; sets a Swift flag)
#   Android  client/android/app-browser.on                  (written here; or CASAMA_APP_BROWSER=1)
#
# Both stores forbid hidden features that are switched on later, so public store builds stay
# `off` until the release that describes the feature (plan §6, Stage 2). Test builds use `on`.
#
#   scripts/app-browser-switch.sh on|off|status
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
ios="$root/client/ios/Flutter/AppBrowser.xcconfig"
android="$root/client/android/app-browser.on"

case "${1:-status}" in
  on)
    printf '%s\n' 'OTHER_SWIFT_FLAGS = $(inherited) -D CASAMA_APP_BROWSER' > "$ios"
    : > "$android"
    echo "Phone browser: ON for builds from this checkout."
    echo "Add to the Flutter build:  --dart-define=CASAMA_APP_BROWSER=true"
    ;;
  off)
    rm -f "$ios" "$android"
    echo "Phone browser: OFF. Builds from this checkout don't contain it."
    ;;
  status)
    if [ -f "$ios" ] || [ -f "$android" ]; then
      echo "on (ios: $([ -f "$ios" ] && echo yes || echo no), android: $([ -f "$android" ] && echo yes || echo no))"
    else
      echo "off"
    fi
    ;;
  *)
    echo "usage: $0 on|off|status" >&2
    exit 2
    ;;
esac
