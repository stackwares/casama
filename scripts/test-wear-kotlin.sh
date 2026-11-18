#!/bin/sh
# Compiles and tests the Wear OS app's pure Kotlin (client/wear/app/src/main/kotlin/ai/casama/wear/core:
# models, decoding, the key's fingerprint, formatting, the offline queue, screen decisions) with
# kotlinc, without Gradle or the Android SDK (D-410). It decodes every shared sample answer in
# packages/contracts/fixtures/watch. Gradle runs the same test as testDebugUnitTest.
#
#   scripts/test-wear-kotlin.sh
#
# Uses kotlinc from PATH (or $KOTLINC), else downloads Kotlin 2.4.0 (the app's version) once into
# $CASAMA_WEAR_CACHE (default ~/.cache/casama-wear-kotlin), with the test libraries from Maven Central.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CORE="$ROOT/client/wear/app/src/main/kotlin/ai/casama/wear/core"
TEST="$ROOT/client/wear/app/src/test/kotlin/ai/casama/wear/core"
FIXTURES="$ROOT/packages/contracts/fixtures/watch"
CACHE=${CASAMA_WEAR_CACHE:-$HOME/.cache/casama-wear-kotlin}
KOTLIN_VERSION=2.4.0
mkdir -p "$CACHE"

# The core must stay free of Android so it can be tested here.
if grep -l -E '^import (android|androidx|com\.google)\.' "$CORE"/*.kt; then
  echo "error: the files above import Android; move that code out of core/" >&2
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

# name group/path artifact version
fetch() {
  dest="$CACHE/$3-$4.jar"
  if [ ! -f "$dest" ]; then
    url="https://repo1.maven.org/maven2/$2/$3/$4/$3-$4.jar"
    curl -fsSL -o "$dest.part" "$url"
    want=$(curl -fsSL "$url.sha1" | cut -c1-40)
    got=$(shasum -a 1 "$dest.part" | cut -c1-40)
    if [ "$want" != "$got" ]; then
      echo "error: checksum mismatch for $url" >&2
      rm -f "$dest.part"
      exit 1
    fi
    mv "$dest.part" "$dest"
  fi
  printf '%s' "$dest"
}
SER_CORE=$(fetch x org/jetbrains/kotlinx kotlinx-serialization-core-jvm 1.13.0)
SER_JSON=$(fetch x org/jetbrains/kotlinx kotlinx-serialization-json-jvm 1.13.0)
JUNIT=$(fetch x junit junit 4.13.2)
HAMCREST=$(fetch x org/hamcrest hamcrest-core 1.3)
KTEST="$KOTLIN_HOME/lib/kotlin-test.jar"
KTEST_JUNIT="$KOTLIN_HOME/lib/kotlin-test-junit.jar"
STDLIB="$KOTLIN_HOME/lib/kotlin-stdlib.jar"

OUT=$(mktemp -d "${TMPDIR:-/tmp}/casama-wear-test.XXXXXX")
trap 'rm -rf "$OUT"' EXIT

CP="$SER_CORE:$SER_JSON:$JUNIT:$HAMCREST:$KTEST:$KTEST_JUNIT"
echo "Compiling $(ls "$CORE"/*.kt | wc -l | tr -d ' ') core files and the tests with $("$KOTLINC" -version 2>&1 | tail -1)…"
"$KOTLINC" -jvm-target 17 -cp "$CP" -d "$OUT" "$CORE"/*.kt "$TEST"/*.kt 2>&1 | grep -v '^warning: unable to find kotlin-stdlib' || true
if [ ! -f "$OUT/ai/casama/wear/core/CoreTest.class" ]; then
  echo "error: compile failed" >&2
  exit 1
fi

java -Dfixtures.dir="$FIXTURES" -cp "$OUT:$CP:$STDLIB" org.junit.runner.JUnitCore ai.casama.wear.core.CoreTest
