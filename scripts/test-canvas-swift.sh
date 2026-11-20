#!/bin/sh
# The Canvas widget's pure Swift (docs/BOT-WIDGET-PLAN.md §10.1, §14), checked on this Mac without
# Xcode builds or a simulator: compiles the canvas model, store, fetch helpers and timeline logic
# (with the glance files they lean on) together with client/ios/CasamaWidgetsTests/CanvasTests.swift
# for macOS, and runs it against every sample answer in packages/contracts/fixtures/canvases.
#
#   scripts/test-canvas-swift.sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
W=$ROOT/client/ios/CasamaWidgets
OUT=$(mktemp -d "${TMPDIR:-/tmp}/canvas-swift.XXXXXX")
trap 'rm -rf "$OUT"' EXIT

xcrun --sdk macosx swiftc -parse-as-library -swift-version 5 -target "$(uname -m)-apple-macos14.0" \
  -o "$OUT/canvas-tests" \
  "$W/Glance.swift" \
  "$W/WidgetKey.swift" \
  "$W/GlanceFetch.swift" \
  "$W/Canvas.swift" \
  "$W/CanvasIntents.swift" \
  "$W/CanvasTimeline.swift" \
  "$ROOT/client/ios/CasamaWidgetsTests/CanvasTests.swift"

"$OUT/canvas-tests" "$ROOT/packages/contracts/fixtures/canvases"
