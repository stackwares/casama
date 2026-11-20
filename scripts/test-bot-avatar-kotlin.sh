#!/bin/sh
# Checks the Android bot-picture parser (client/android/app/src/main/kotlin/ai/casama/app/
# BotAvatarValue.kt, pure Kotlin) against the shared vectors in
# packages/domain/test/fixtures/bot-avatar-vectors.json, with kotlinc and no Gradle or Android SDK
# (docs/BOT-PICTURES-PLAN.md §5.1).
#
#   scripts/test-bot-avatar-kotlin.sh
#
# Uses kotlinc from PATH (or $KOTLINC), else the copy scripts/test-canvas-kotlin.sh downloads into
# $CASAMA_WEAR_CACHE (default ~/.cache/casama-wear-kotlin); run that script once to fetch it.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/client/android/app/src"
CACHE=${CASAMA_WEAR_CACHE:-$HOME/.cache/casama-wear-kotlin}

if [ -n "${KOTLINC:-}" ]; then
  :
elif command -v kotlinc >/dev/null 2>&1; then
  KOTLINC=$(command -v kotlinc)
else
  KOTLINC="$CACHE/kotlinc/bin/kotlinc"
  if [ ! -x "$KOTLINC" ]; then
    echo "error: no kotlinc; run scripts/test-canvas-kotlin.sh once to download it" >&2
    exit 1
  fi
fi
KOTLIN_HOME=$(cd "$(dirname "$KOTLINC")/.." && pwd)
STDLIB="$KOTLIN_HOME/lib/kotlin-stdlib.jar"

# The parser must stay free of Android so it can be checked here.
if grep -E '^import (android|androidx|com\.google|org\.json)\.' "$SRC/main/kotlin/ai/casama/app/BotAvatarValue.kt"; then
  echo "error: BotAvatarValue.kt imports Android" >&2
  exit 1
fi

OUT=$(mktemp -d "${TMPDIR:-/tmp}/casama-bot-avatar-test.XXXXXX")
trap 'rm -rf "$OUT"' EXIT

"$KOTLINC" -jvm-target 17 -d "$OUT" \
  "$SRC/main/kotlin/ai/casama/app/BotAvatarValue.kt" \
  "$SRC/main/kotlin/ai/casama/app/canvas/MiniJson.kt" \
  "$SRC/test/kotlin/ai/casama/app/BotAvatarCheck.kt" 2>&1 | grep -v '^warning: unable to find kotlin-stdlib' || true
if [ ! -f "$OUT/ai/casama/app/BotAvatarCheckKt.class" ]; then
  echo "error: compile failed" >&2
  exit 1
fi

java -Dvectors.file="$ROOT/packages/domain/test/fixtures/bot-avatar-vectors.json" -cp "$OUT:$STDLIB" ai.casama.app.BotAvatarCheckKt
