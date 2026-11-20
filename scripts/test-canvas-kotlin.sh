#!/bin/sh
# Compiles and checks the Android Canvas widget's pure Kotlin (client/android/app/src/main/kotlin/
# ai/casama/app/canvas: the CanvasList model, its decoder and the widget's decisions) with kotlinc,
# without Gradle or the Android SDK (docs/BOT-WIDGET-PLAN.md §10.2, §14). It decodes every shared
# sample in packages/contracts/fixtures/canvases.
#
#   scripts/test-canvas-kotlin.sh
#
# Uses kotlinc from PATH (or $KOTLINC), else the copy scripts/test-wear-kotlin.sh downloads into
# $CASAMA_WEAR_CACHE (default ~/.cache/casama-wear-kotlin), downloading it there first if needed.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CORE="$ROOT/client/android/app/src/main/kotlin/ai/casama/app/canvas"
TEST="$ROOT/client/android/app/src/test/kotlin/ai/casama/app/canvas"
FIXTURES="$ROOT/packages/contracts/fixtures/canvases"
CACHE=${CASAMA_WEAR_CACHE:-$HOME/.cache/casama-wear-kotlin}
KOTLIN_VERSION=2.4.0
mkdir -p "$CACHE"

# The model must stay free of Android so it can be checked here.
if grep -l -E '^import (android|androidx|com\.google|org\.json)\.' "$CORE"/*.kt; then
  echo "error: the files above import Android; move that code out of canvas/" >&2
  exit 1
fi

if [ -n "${KOTLINC:-}" ]; then
  :
elif command -v kotlinc >/dev/null 2>&1; then
  KOTLINC=$(command -v kotlinc)
else
  KOTLINC="$CACHE/kotlinc/bin/kotlinc"
  if [ ! -x "$KOTLINC" ]; then
    echo "Downloading Kotlin $KOTLIN_VERSION compiler…"
    curl -fsSL -o "$CACHE/kotlin-compiler.zip" \
      "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-compiler-$KOTLIN_VERSION.zip"
    unzip -q -o "$CACHE/kotlin-compiler.zip" -d "$CACHE"
    rm -f "$CACHE/kotlin-compiler.zip"
  fi
fi
KOTLIN_HOME=$(cd "$(dirname "$KOTLINC")/.." && pwd)
STDLIB="$KOTLIN_HOME/lib/kotlin-stdlib.jar"

OUT=$(mktemp -d "${TMPDIR:-/tmp}/casama-canvas-test.XXXXXX")
trap 'rm -rf "$OUT"' EXIT

echo "Compiling $(ls "$CORE"/*.kt | wc -l | tr -d ' ') model files and the check with $("$KOTLINC" -version 2>&1 | tail -1)…"
"$KOTLINC" -jvm-target 17 -d "$OUT" "$CORE"/*.kt "$TEST"/*.kt 2>&1 | grep -v '^warning: unable to find kotlin-stdlib' || true
if [ ! -f "$OUT/ai/casama/app/canvas/CanvasModelCheckKt.class" ]; then
  echo "error: compile failed" >&2
  exit 1
fi

java -Dfixtures.dir="$FIXTURES" -cp "$OUT:$STDLIB" ai.casama.app.canvas.CanvasModelCheckKt
