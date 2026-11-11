#!/usr/bin/env bash
# Builds the Mac App Store version: sandboxed (macos/Runner/AppStore.entitlements) and with the
# features the sandbox can't host turned off (CASAMA_DISTRIBUTION=appstore). Produces a signed .pkg
# to upload with Transporter or `xcrun altool --upload-app`.
#
#   APP_SIGN_IDENTITY       "Apple Distribution: …" (or "3rd Party Mac Developer Application: …")
#   INSTALLER_SIGN_IDENTITY "3rd Party Mac Developer Installer: …"
#   PROVISIONING_PROFILE    path to the Mac App Store provisioning profile for ai.casama.app
#
# Without them it builds and stops before signing (a local check that the App Store flavor builds).
# The direct download (every feature, notarized) is scripts/package-macos.sh.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
flutter build macos --release \
  --dart-define=CASAMA_DISTRIBUTION=appstore \
  --dart-define=CASAMA_SIGNED_MAC=true \
  --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://cloud.casama.ai}" \
  --dart-define-from-file=config/firebase.json \
  --dart-define-from-file=config/telemetry.json
app="build/macos/Build/Products/Release/casama_app.app"
# The Mac App Store updates the app, so this build never starts Sparkle (D-159): mark it (the menu
# leaves out Check for Updates…) and drop Sparkle's helper programs, which aren't sandboxed and
# would fail App Store validation. The framework itself stays linked, unused.
/usr/libexec/PlistBuddy -c "Add :CasamaDistribution string appstore" "$app/Contents/Info.plist" 2>/dev/null ||
  /usr/libexec/PlistBuddy -c "Set :CasamaDistribution appstore" "$app/Contents/Info.plist"
sparkle="$app/Contents/Frameworks/Sparkle.framework"
rm -rf "$sparkle/Versions/B/Autoupdate" "$sparkle/Versions/B/Updater.app" "$sparkle/Versions/B/XPCServices" \
  "$sparkle/Autoupdate" "$sparkle/Updater.app" "$sparkle/XPCServices"
if [[ -z "${APP_SIGN_IDENTITY:-}" || -z "${INSTALLER_SIGN_IDENTITY:-}" || -z "${PROVISIONING_PROFILE:-}" ]]; then
  echo "Built $app (App Store flavor). Set APP_SIGN_IDENTITY, INSTALLER_SIGN_IDENTITY and PROVISIONING_PROFILE to sign and package." >&2
  exit 0
fi
cp "$PROVISIONING_PROFILE" "$app/Contents/embedded.provisionprofile"
# Inside out: frameworks and helpers first, then the app with the sandbox entitlements.
find "$app/Contents/Frameworks" -maxdepth 1 \( -name '*.framework' -o -name '*.dylib' \) -print0 |
  while IFS= read -r -d '' item; do codesign --force --timestamp --sign "$APP_SIGN_IDENTITY" "$item"; done
codesign --force --timestamp --options runtime --entitlements macos/Runner/AppStore.entitlements \
  --sign "$APP_SIGN_IDENTITY" "$app"
codesign --verify --deep --strict "$app"
out="../dist/Casama-$version-macappstore.pkg"
mkdir -p ../dist
productbuild --component "$app" /Applications --sign "$INSTALLER_SIGN_IDENTITY" "$out"
echo "$out"
