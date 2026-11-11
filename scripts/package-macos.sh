#!/usr/bin/env bash
# Builds the macOS app (direct download) and a DMG. With SIGN_IDENTITY ("Developer ID Application:
# ...") it signs with the hardened runtime; with NOTARY_PROFILE (xcrun notarytool store-credentials)
# it notarizes and staples. Without them it produces an unsigned DMG for local testing.
# Then it signs the DMG for Sparkle (the key in the login Keychain, account "kasama", or
# SPARKLE_KEY_FILE) and writes dist/appcast-macos.xml for scripts/publish-desktop-release.sh.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
flutter build macos --release --dart-define=KASAMA_API_URL="${KASAMA_API_URL:-https://cloud.kasama.dev}" --dart-define-from-file=config/firebase.json
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

# Sparkle update feed (D-159): one item, the release just built, signed with the update key.
build=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f2)
repo="${KASAMA_RELEASES_REPO:-stackwares/kasama-releases}"
sign=(macos/Pods/Sparkle/bin/sign_update)
if [[ -n "${SPARKLE_KEY_FILE:-}" ]]; then sign+=(--ed-key-file "$SPARKLE_KEY_FILE"); else sign+=(--account kasama); fi
if attrs=$("${sign[@]}" "$out" 2>/dev/null); then
  cat > ../dist/appcast-macos.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Kasama</title>
    <item>
      <title>Kasama $version</title>
      <sparkle:releaseNotesLink>https://github.com/$repo/releases/tag/v$version</sparkle:releaseNotesLink>
      <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>12.0</sparkle:minimumSystemVersion>
      <enclosure url="https://github.com/$repo/releases/download/v$version/$(basename "$out")" $attrs type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
  echo "../dist/appcast-macos.xml"
else
  echo "No Sparkle signing key (login Keychain account \"kasama\" or SPARKLE_KEY_FILE): no update feed written." >&2
fi
echo "$out"
