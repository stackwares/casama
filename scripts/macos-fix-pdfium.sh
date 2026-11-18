#!/usr/bin/env bash
# Puts the right PDFium back into a built macOS app. Usage: macos-fix-pdfium.sh <Casama.app>
#
# On macOS two PDFium frameworks get bundled: pdfium_flutter's XCFramework (PDFium.framework,
# install name @rpath/PDFium.framework/PDFium, which the app links) and pdfium_dart's native asset
# (pdfium.framework, install name @rpath/pdfium.framework/pdfium, kept for flutter test). On a
# case-insensitive disk both land in one folder and the native asset's binary wins, so with the
# hardened runtime dyld refuses it ("leaf name must match") and the signed app dies at launch.
# Flutter on macOS reads PDFium from the process (DynamicLibrary.process), so the XCFramework's copy
# is the one the app needs. Run this after flutter build and before signing.
set -euo pipefail
app="$1"
products="$(dirname "$app")"
bundled="$app/Contents/Frameworks/PDFium.framework"
xcframework="$products/PDFium.framework"
[[ -d "$bundled" ]] || exit 0
if [[ ! -e "$xcframework/PDFium" ]]; then
  echo "macos-fix-pdfium: $xcframework is missing; can't repair $bundled." >&2
  exit 1
fi
if [[ "$(otool -D "$bundled/PDFium" 2>/dev/null | tail -1)" == "@rpath/PDFium.framework/PDFium" &&
  -e "$bundled/Versions/Current/PDFium" ]]; then
  exit 0
fi
rm -rf "$bundled"
ditto "$xcframework" "$bundled"
# Headers aren't needed at run time.
rm -rf "$bundled/Headers" "$bundled/Versions/Current/Headers"
echo "macos-fix-pdfium: replaced $bundled with the XCFramework's copy." >&2
