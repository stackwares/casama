#!/usr/bin/env bash
# Phase 6 gate: an external app (examples/sdk_sample) streams a run with kasama_sdk against the
# local stack (API on :8787, worker with fixtures).
set -euo pipefail
cd "$(dirname "$0")/../examples/sdk_sample"
dart pub get >/dev/null
out=$(dart run bin/sample.dart --email "sdk-sample-$RANDOM$RANDOM@example.com" --password pw-123456 \
  --key sk-or-v1-sample-fixture --model fixture-main --message "Please note: my favorite color is teal.")
echo "$out"
grep -q "run completed" <<<"$out"
grep -q "I'll remember that" <<<"$out"
echo "SDK sample: OK"
