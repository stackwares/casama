#!/usr/bin/env bash
# Builds the Mac App Store version: sandboxed (macos/Runner/AppStore.entitlements) and with the
# features the sandbox can't host turned off (CASAMA_DISTRIBUTION=appstore). Produces a signed .pkg
# to upload with Transporter or `xcrun altool --upload-app`.
#
#   APP_SIGN_IDENTITY       "Apple Distribution: …" (or "3rd Party Mac Developer Application: …")
#   INSTALLER_SIGN_IDENTITY "3rd Party Mac Developer Installer: …"
#   PROVISIONING_PROFILE    path to the Mac App Store provisioning profile for ai.casama.app
#   WIDGET_PROVISIONING_PROFILE  the Mac App Store profile for ai.casama.app.CasamaWidgetsMac (the
#                           widget extension, D-405); App Store Connect refuses the build without it
#
# Without them it builds and stops before signing (a local check that the App Store flavor builds).
# The direct download (every feature, notarized) is scripts/package-macos.sh.
set -euo pipefail
cd "$(dirname "$0")/../client"
version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
defines=()
if [[ -f config/firebase.json ]]; then
  defines+=(--dart-define-from-file=config/firebase.json)
fi
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/telemetry.json ]]; then
  defines+=(--dart-define-from-file=config/telemetry.json)
fi
# The MapTiler key for bots' map cards (D-310); without it maps use OpenStreetMap's own tiles.
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" && -f config/maps.json ]]; then
  defines+=(--dart-define-from-file=config/maps.json)
fi
# No Sparkle in this build (App Store 2.4.5(vii)): auto_updater is swapped for a stub with no
# native plugin, so neither its pod nor Sparkle.framework is linked. The lock files are put back after.
tmp=$(mktemp -d)
cp pubspec.lock "$tmp/pubspec.lock"
cp macos/Podfile.lock "$tmp/Podfile.lock"
restore() {
  rm -f pubspec_overrides.yaml
  cp "$tmp/pubspec.lock" pubspec.lock
  cp "$tmp/Podfile.lock" macos/Podfile.lock
  flutter pub get >/dev/null || true
  rm -rf "$tmp"
}
trap restore EXIT
printf 'dependency_overrides:\n  auto_updater:\n    path: tool/appstore/auto_updater_stub\n' >pubspec_overrides.yaml
flutter pub get
flutter build macos --release \
  --dart-define=CASAMA_DISTRIBUTION=appstore \
  --dart-define=CASAMA_SIGNED_MAC=true \
  --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" \
  "${defines[@]}"
app="build/macos/Build/Products/Release/Casama.app"
../scripts/macos-fix-pdfium.sh "$app"
# The Mac App Store updates the app (D-159): mark the build (the menu leaves out Check for
# Updates…), drop Sparkle's Info.plist keys, and fail if Sparkle got in anyway.
/usr/libexec/PlistBuddy -c "Add :CasamaDistribution string appstore" "$app/Contents/Info.plist" 2>/dev/null ||
  /usr/libexec/PlistBuddy -c "Set :CasamaDistribution appstore" "$app/Contents/Info.plist"
for key in SUPublicEDKey SUEnableAutomaticChecks SUAutomaticallyUpdate SUScheduledCheckInterval SUFeedURL; do
  /usr/libexec/PlistBuddy -c "Delete :$key" "$app/Contents/Info.plist" 2>/dev/null || true
done
if [[ -e "$app/Contents/Frameworks/Sparkle.framework" ]] ||
  [[ -e "$app/Contents/Frameworks/auto_updater_macos.framework" ]]; then
  echo "Sparkle is in the App Store build; the auto_updater stub didn't apply." >&2
  exit 1
fi
if [[ -z "${APP_SIGN_IDENTITY:-}" || -z "${INSTALLER_SIGN_IDENTITY:-}" || -z "${PROVISIONING_PROFILE:-}" ]]; then
  echo "Built $app (App Store flavor). Set APP_SIGN_IDENTITY, INSTALLER_SIGN_IDENTITY and PROVISIONING_PROFILE to sign and package." >&2
  exit 0
fi
cp "$PROVISIONING_PROFILE" "$app/Contents/embedded.provisionprofile"
# Inside out: frameworks and helpers first, then the app with the sandbox entitlements.
find "$app/Contents/Frameworks" -maxdepth 1 \( -name '*.framework' -o -name '*.dylib' \) -print0 |
  while IFS= read -r -d '' item; do codesign --force --timestamp --sign "$APP_SIGN_IDENTITY" "$item"; done
# codesign doesn't expand Xcode's $(AppIdentifierPrefix) (Google sign-in's keychain group, D-217):
# fill in the team prefix from the provisioning profile.
prefix=$(security cms -D -i "$PROVISIONING_PROFILE" | plutil -extract ApplicationIdentifierPrefix.0 raw -)
entitlements=$(mktemp)
sed "s/\$(AppIdentifierPrefix)/$prefix./g" macos/Runner/AppStore.entitlements >"$entitlements"
# Xcode signs these in for us; codesign doesn't. Without the application identifier App Store
# Connect takes the build but TestFlight refuses it (warning 90886, PROCESSING_EXCEPTION).
team=$(security cms -D -i "$PROVISIONING_PROFILE" | plutil -extract TeamIdentifier.0 raw -)
bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist")
# The widget extension (D-405 §8.8) is signed first, with its own sandbox entitlements and its own
# Mac App Store profile for ai.casama.app.CasamaWidgetsMac (WIDGET_PROVISIONING_PROFILE). App Store
# Connect refuses an extension without one, so this build needs it.
widgets="$app/Contents/PlugIns/CasamaWidgetsMac.appex"
if [[ -d "$widgets" ]]; then
  if [[ -z "${WIDGET_PROVISIONING_PROFILE:-}" ]]; then
    echo "Warning: no WIDGET_PROVISIONING_PROFILE: App Store Connect will refuse the widget extension." >&2
  else
    cp "$WIDGET_PROVISIONING_PROFILE" "$widgets/Contents/embedded.provisionprofile"
  fi
  went=$(mktemp)
  sed "s/[$](AppIdentifierPrefix)/$prefix./g; s/[$](TeamIdentifierPrefix)/$team./g" \
    macos/CasamaWidgetsMac/CasamaWidgetsMac.entitlements >"$went"
  /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $prefix.$bundle_id.CasamaWidgetsMac" "$went"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team" "$went"
  if [[ -n "${WIDGET_PROVISIONING_PROFILE:-}" ]]; then
    aps=$(security cms -D -i "$WIDGET_PROVISIONING_PROFILE" | plutil -extract 'Entitlements.com\.apple\.developer\.aps-environment' raw - 2>/dev/null || true)
    [[ -n "$aps" ]] && /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string $aps" "$went"
  fi
  codesign --force --timestamp --options runtime --entitlements "$went" \
    --sign "$APP_SIGN_IDENTITY" "$widgets"
  rm -f "$went"
fi
/usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $prefix.$bundle_id" "$entitlements"
/usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team" "$entitlements"
# Push (D-312, D-325) needs aps-environment, which only the provisioning profile can grant.
aps=$(security cms -D -i "$PROVISIONING_PROFILE" | plutil -extract 'Entitlements.com\.apple\.developer\.aps-environment' raw - 2>/dev/null || true)
[[ -n "$aps" ]] && /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string $aps" "$entitlements"
codesign --force --timestamp --options runtime --entitlements "$entitlements" \
  --sign "$APP_SIGN_IDENTITY" "$app"
rm -f "$entitlements"
codesign --verify --deep --strict "$app"
out="../dist/Casama-$version-macappstore.pkg"
mkdir -p ../dist
productbuild --component "$app" /Applications --sign "$INSTALLER_SIGN_IDENTITY" "$out"
echo "$out"
