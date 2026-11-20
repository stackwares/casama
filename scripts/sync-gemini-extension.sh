#!/usr/bin/env bash
# Builds the Gemini CLI extension (stackwares/casama-gemini) from packaging/gemini-cli and the
# agent kit's skills. The Gemini extension gallery only indexes a repository with
# gemini-extension.json at its root, so the extension lives in its own small repository.
#
#   scripts/sync-gemini-extension.sh <checkout of stackwares/casama-gemini>
#
# It replaces the checkout's files (not .git) and validates the result. Commit and push there.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:?usage: $0 <checkout of stackwares/casama-gemini>}"
[ -d "$out" ] || { echo "No such folder: $out" >&2; exit 1; }
out="$(cd "$out" && pwd)"
[ "$out" != "$root" ] || { echo "Give the extension's checkout, not this repository" >&2; exit 1; }

find "$out" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R "$root/packaging/gemini-cli/." "$out/"
mkdir -p "$out/skills"
cp -R "$root/agent-kit/skills/." "$out/skills/"

if command -v gemini >/dev/null; then
  gemini extensions validate "$out"
else
  echo "gemini not installed: skipped validation" >&2
fi
echo "Built the extension in $out. Commit and push it there."
