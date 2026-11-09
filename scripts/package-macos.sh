#!/usr/bin/env bash
# Builds the macOS app and a DMG. With SIGN_IDENTITY ("Developer ID Application: ...") it signs
# with the hardened runtime; with NOTARY_PROFILE (xcrun notarytool store-credentials) it notarizes
# and staples. Without them it produces an unsigned DMG for local testing.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
flutter build macos --release --dart-define=KASAMA_API_URL="${KASAMA_API_URL:-https://cloud.kasama.dev}"
app="build/macos/Build/Products/Release/kasama_app.app"
out="../dist/Kasama-$version-macos.dmg"
mkdir -p ../dist
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --deep --force --options runtime --timestamp --entitlements macos/Runner/Release.entitlements \
    --sign "$SIGN_IDENTITY" "$app"
fi
rm -f "$out"
staging=$(mktemp -d)
cp -R "$app" "$staging/Kasama.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "Kasama" -srcfolder "$staging" -ov -format UDZO "$out" >/dev/null
rm -rf "$staging"
if [[ -n "${SIGN_IDENTITY:-}" ]]; then codesign --sign "$SIGN_IDENTITY" --timestamp "$out"; fi
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$out" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$out"
fi
echo "$out"
