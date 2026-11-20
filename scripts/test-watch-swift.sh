#!/bin/sh
# The Apple Watch app's pure Swift, checked on this Mac without Xcode builds or a simulator (D-410):
# compiles the shared model files with client/ios/CasamaWatchTests/ModelTests.swift for macOS and
# runs it against every sample answer in packages/contracts/fixtures/watch.
#
#   scripts/test-watch-swift.sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SHARED=$ROOT/client/ios/Shared
OUT=$(mktemp -d "${TMPDIR:-/tmp}/watch-swift.XXXXXX")
trap 'rm -rf "$OUT"' EXIT

xcrun --sdk macosx swiftc -parse-as-library -swift-version 5 -target "$(uname -m)-apple-macos14.0" \
  -o "$OUT/model-tests" \
  "$SHARED/WatchStrings.swift" \
  "$SHARED/WatchModels.swift" \
  "$SHARED/WatchLogic.swift" \
  "$SHARED/WatchLinks.swift" \
  "$SHARED/WatchSSE.swift" \
  "$SHARED/WatchStore.swift" \
  "$SHARED/BotPictureStore.swift" \
  "$ROOT/client/ios/CasamaWatchTests/ModelTests.swift"

"$OUT/model-tests" "$ROOT/packages/contracts/fixtures/watch" "$ROOT/packages/domain/test/fixtures/bot-avatar-vectors.json"
