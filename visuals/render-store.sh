#!/usr/bin/env bash
# Renders Casama for Chrome's Chrome Web Store promo tiles (D-379) into apps/extension/store/.
# Needs visuals/serve.py on :8740. Uploading them to the store is a manual step.
set -euo pipefail
cd "$(dirname "$0")/.."
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
shot() { # size w h out
  "$chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=3000 \
    --window-size="$2,$3" --screenshot="$PWD/$4" "http://127.0.0.1:8740/visuals/compose/store.html?size=$1" >/dev/null 2>&1
  echo "$4 $(sips -g pixelWidth -g pixelHeight "$4" | awk '/pixel/ {printf $2" "}')"
}
shot marquee 1400 560 apps/extension/store/marquee-1400x560.png
shot small 440 280 apps/extension/store/small-tile-440x280.png
