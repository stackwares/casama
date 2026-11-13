#!/usr/bin/env bash
# Builds the macOS app (direct download) and a DMG. With SIGN_IDENTITY ("Developer ID Application:
# ...") it signs with the hardened runtime; with NOTARY_PROFILE (xcrun notarytool store-credentials)
# it notarizes and staples. Without them it produces an unsigned DMG for local testing.
# Passkeys need PROVISIONING_PROFILE too: the Developer ID profile for ai.casama.app ("Casama Mac
# Developer ID"), which grants Associated Domains. macOS refuses to launch an app that claims that
# entitlement without the profile, so without it the build leaves it out. Apple doesn't grant Sign
# in with Apple to Developer ID apps, so this build's Continue with Apple always uses the browser;
# only the Mac App Store build (package-macos-appstore.sh) gets Apple's own sheet.
# Then it signs the DMG for Sparkle (the key in the login Keychain, account "casama", or
# SPARKLE_KEY_FILE) and writes dist/appcast-macos.xml for scripts/publish-desktop-release.sh.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
# A signed build with the profile carries the passkey entitlement (added below), so the app offers
# passkeys (D-184).
signed=()
[[ -n "${SIGN_IDENTITY:-}" && -n "${PROVISIONING_PROFILE:-}" ]] && signed=(--dart-define=CASAMA_SIGNED_MAC=true)
defines=()
if [[ -f config/firebase.json ]]; then
  defines+=(--dart-define-from-file=config/firebase.json)
fi
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  defines+=(--dart-define-from-file=config/telemetry.json)
fi
flutter build macos --release --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" "${defines[@]}" "${signed[@]}"
# dSYMs to PostHog error tracking when a key is set (never fails the build).
../scripts/upload-symbols.sh apple build/macos/Build/Products/Release
app="build/macos/Build/Products/Release/casama_app.app"
out="../dist/Casama-$version-macos.dmg"
mkdir -p ../dist
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  # Passkeys (associated domains), and Sign in with Apple should Apple ever grant it to Developer ID,
  # are added only on this signed build, and only when the profile grants them. Release.entitlements is also what an unsigned local
  # build is signed with, and these entitlements keep those builds from launching.
  entitlements=$(mktemp)
  cp macos/Runner/Release.entitlements "$entitlements"
  if [[ -n "${PROVISIONING_PROFILE:-}" ]]; then
    profile=$(mktemp)
    security cms -D -i "$PROVISIONING_PROFILE" >"$profile"
    team=$(plutil -extract TeamIdentifier.0 raw "$profile")
    app_id=$(plutil -extract 'Entitlements.com\.apple\.application-identifier' raw "$profile")
    grants() { plutil -extract "Entitlements.$1" raw "$profile" >/dev/null 2>&1 || plutil -extract "Entitlements.$1" xml1 -o /dev/null "$profile" 2>/dev/null; }
    apple=0 domains=0
    grants 'com\.apple\.developer\.applesignin' && apple=1
    grants 'com\.apple\.developer\.associated-domains' && domains=1
    rm -f "$profile"
    if [[ "$app_id" != "$team.ai.casama.app" ]]; then
      echo "PROVISIONING_PROFILE is for $app_id, not $team.ai.casama.app." >&2
      exit 1
    fi
    cp "$PROVISIONING_PROFILE" "$app/Contents/embedded.provisionprofile"
    /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $app_id" "$entitlements"
    /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team" "$entitlements"
    if ((apple)); then
      /usr/libexec/PlistBuddy -c "Add :com.apple.developer.applesignin array" "$entitlements"
      /usr/libexec/PlistBuddy -c "Add :com.apple.developer.applesignin:0 string Default" "$entitlements"
    fi
    if ((domains)); then
      /usr/libexec/PlistBuddy -c "Add :com.apple.developer.associated-domains array" "$entitlements"
      /usr/libexec/PlistBuddy -c "Add :com.apple.developer.associated-domains:0 string webcredentials:casama.ai" "$entitlements"
    fi
  else
    echo "No PROVISIONING_PROFILE: signing without passkeys." >&2
  fi
  # Inside out: frameworks and their helpers (Sparkle's) without the app's entitlements, then the app.
  find "$app/Contents/Frameworks" -maxdepth 1 \( -name '*.framework' -o -name '*.dylib' \) -print0 |
    while IFS= read -r -d '' item; do
      codesign --deep --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$item"
    done
  codesign --force --options runtime --timestamp --entitlements "$entitlements" \
    --sign "$SIGN_IDENTITY" "$app"
  codesign --verify --deep --strict "$app"
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
