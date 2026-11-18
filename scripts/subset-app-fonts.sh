#!/usr/bin/env bash
# Trims Google Sans in client/assets/fonts to Latin, Greek, Cyrillic and Vietnamese, plus
# punctuation, symbols and combining marks: 1.9 MB to about 0.3 MB a weight. The full files mostly
# hold Indic, Thai, Ethiopic, Khmer and other scripts; text in those falls back to the system font,
# as it already does for the app's other bundled fonts. Outlines and layout features for the kept
# scripts are unchanged.
# Run again after replacing a font with a fresh download. Needs fonttools (pip install fonttools).
set -euo pipefail
cd "$(dirname "$0")/../client/assets/fonts"

unicodes='U+0000-036F,U+0370-03FF,U+0400-052F,U+1C80-1C8F,U+1D00-1EFF,U+1F00-1FFF,U+2000-2BFF,U+2C60-2C7F,U+2DE0-2E7F,U+A640-A69F,U+A720-A7FF,U+FB00-FB06,U+FE00-FE0F,U+FE20-FE2F,U+FFFC-FFFD'

for f in GoogleSans-Regular.ttf GoogleSans-Medium.ttf GoogleSans-Bold.ttf; do
  before=$(wc -c <"$f" | tr -d ' ')
  pyftsubset "$f" --output-file="$f.tmp" --unicodes="$unicodes" \
    --layout-features='*' --name-IDs='*' --name-languages='*' --notdef-outline --glyph-names
  mv "$f.tmp" "$f"
  echo "$f: $before -> $(wc -c <"$f" | tr -d ' ') bytes"
done
