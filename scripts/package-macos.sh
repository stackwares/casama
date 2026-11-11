#!/usr/bin/env bash
# Builds the macOS app (direct download) and a DMG. With SIGN_IDENTITY ("Developer ID Application:
# ...") it signs with the hardened runtime; with NOTARY_PROFILE (xcrun notarytool store-credentials)
# it notarizes and staples. Without them it produces an unsigned DMG for local testing.
# Then it signs the DMG for Sparkle (the key in the login Keychain, account "casama", or
# SPARKLE_KEY_FILE) and writes dist/appcast-macos.xml for scripts/publish-desktop-release.sh.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
# A signed build carries the passkey entitlement (added below), so the app offers passkeys (D-184).
signed=()
[[ -n "${SIGN_IDENTITY:-}" ]] && signed=(--dart-define=CASAMA_SIGNED_MAC=true)
flutter build macos --release --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://cloud.casama.ai}" --dart-define-from-file=config/firebase.json --dart-define-from-file=config/telemetry.json "${signed[@]}"
app="build/macos/Build/Products/Release/casama_app.app"
out="../dist/Casama-$version-macos.dmg"
mkdir -p ../dist
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  # Sign in with Apple and passkeys (associated domains) are added only on this signed build.
  # Release.entitlements is also what an unsigned local build is signed with, and these
  # entitlements keep those builds from launching.
  entitlements=$(mktemp)
  cp macos/Runner/Release.entitlements "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.applesignin array" "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.applesignin:0 string Default" "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.associated-domains array" "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.associated-domains:0 string webcredentials:casama.ai" "$entitlements"
  codesign --deep --force --options runtime --timestamp --entitlements "$entitlements" \
    --sign "$SIGN_IDENTITY" "$app"
  rm -f "$entitlements"
fi
rm -f "$out"
staging=$(mktemp -d)
cp -R "$app" "$staging/Casama.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "Casama" -srcfolder "$staging" -ov -format UDZO "$out" >/dev/null
rm -rf "$staging"
if [[ -n "${SIGN_IDENTITY:-}" ]]; then codesign --sign "$SIGN_IDENTITY" --timestamp "$out"; fi
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$out" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$out"
fi

# Sparkle update feed (D-159): one item, the release just built, signed with the update key.
build=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f2)
repo="${CASAMA_RELEASES_REPO:-stackwares/casama-releases}"
sign=(macos/Pods/Sparkle/bin/sign_update)
if [[ -n "${SPARKLE_KEY_FILE:-}" ]]; then sign+=(--ed-key-file "$SPARKLE_KEY_FILE"); else sign+=(--account casama); fi
if attrs=$("${sign[@]}" "$out" 2>/dev/null); then
  cat > ../dist/appcast-macos.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Casama</title>
    <item>
      <title>Casama $version</title>
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
  echo "No Sparkle signing key (login Keychain account \"casama\" or SPARKLE_KEY_FILE): no update feed written." >&2
fi
echo "$out"
