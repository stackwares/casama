#!/usr/bin/env bash
# Renders the Mac installer window background (D-379) into scripts/dmg/background.tiff (660x400 with a
# 2x copy, so it's sharp on Retina). Needs visuals/serve.py on :8740.
set -euo pipefail
cd "$(dirname "$0")/.."
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
tmp=$(mktemp -d)
for scale in 1 2; do
  "$chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=$scale --virtual-time-budget=3000 \
    --window-size=660,400 --screenshot="$tmp/bg$scale.png" "http://127.0.0.1:8740/visuals/compose/dmg.html" >/dev/null 2>&1
done
tiffutil -cathidpicheck "$tmp/bg1.png" "$tmp/bg2.png" -out scripts/dmg/background.tiff 2>/dev/null
cp "$tmp/bg2.png" visuals/round-4/dmg-preview.png 2>/dev/null || true
rm -rf "$tmp"
ls -la scripts/dmg/background.tiff
