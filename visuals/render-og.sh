#!/usr/bin/env bash
# Renders the picked share cards to PNG with headless Chrome (needs visuals/serve.py on :8740).
# Usage: visuals/render-og.sh   → visuals/round-1/final/og-*.png
set -euo pipefail
cd "$(dirname "$0")/.."
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
out=visuals/round-1/final; mkdir -p "$out"
card() { # name bg title sub
  local url="http://127.0.0.1:8740/visuals/compose/og.html?bg=$(python3 -c 'import sys,urllib.parse as u;print(u.quote(sys.argv[1]))' "$2")&title=$(python3 -c 'import sys,urllib.parse as u;print(u.quote(sys.argv[1]))' "$3")&sub=$(python3 -c 'import sys,urllib.parse as u;print(u.quote(sys.argv[1]))' "$4")"
  "$chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=3000 \
    --window-size=1200,630 --screenshot="$PWD/$out/$1.png" "$url" >/dev/null 2>&1
  echo "$out/$1.png"
}
card og-home og-bg-home-v2.png "AI teammates with their own computers." "Open source. On your phone, computer and the web."
card og-docs og-bg-docs-v2.png "Casama docs" "Guides for using, hosting and building on Casama."
card og-link og-bg-link-v2.png "Addresses for Casama servers people run at home." ""
card og-page og-bg-page-v1.png "Websites people made with Casama." ""
