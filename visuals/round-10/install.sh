#!/bin/sh
# Installs round-10 art into the app: covers as 512 px WebP (client/assets/art/<name>.webp), the
# splash/welcome scene at 1600 px on the long side (client/assets/scene/, under ~150 KB each) and a
# light web copy for the loading screen at the raw width, 1536 px (client/web/splash/scene-*.webp, under 60 KB).
# A `<name>-v2.png` in raw/ wins over `<name>.png`. Needs sips and cwebp.
set -eu
cd "$(dirname "$0")"
art=../../client/assets/art
scene=../../client/assets/scene
web=../../client/web/splash
mkdir -p "$art" "$scene" "$web"
tmp=$(mktemp -d)
for f in raw/*.png; do
  name=$(basename "$f" .png)
  case "$name" in *-v[0-9]) continue ;; esac
  src=$f
  for v in raw/"$name"-v*.png; do [ -e "$v" ] && src=$v; done
  case "$name" in
    scene-*)
      sips -Z 1600 "$src" --out "$tmp/$name.png" >/dev/null
      q=90
      while :; do
        cwebp -quiet -q $q -m 6 -sharp_yuv "$tmp/$name.png" -o "$scene/$name.webp"
        [ "$(stat -f%z "$scene/$name.webp")" -le 150000 ] || [ $q -le 50 ] && break
        q=$((q - 5))
      done
      case "$name" in *-wide)
        # The web loading screen: smaller and softer, it only sits behind the progress bar.
        sips -Z 1536 "$src" --out "$tmp/$name-web.png" >/dev/null
        q=78
        while :; do
          cwebp -quiet -q $q -m 6 "$tmp/$name-web.png" -o "$web/$name.webp"
          [ "$(stat -f%z "$web/$name.webp")" -le 60000 ] || [ $q -le 30 ] && break
          q=$((q - 5))
        done ;;
      esac ;;
    *)
      sips -Z 512 "$src" --out "$tmp/$name.png" >/dev/null
      cwebp -quiet -q 82 -m 6 "$tmp/$name.png" -o "$art/$name.webp" ;;
  esac
done
rm -rf "$tmp"
ls -l "$art" "$scene" "$web" | awk 'NF>5{print $5, $NF}'
