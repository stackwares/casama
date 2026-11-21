#!/usr/bin/env bash
# Builds the Android App Bundle (aab) or APK.
# Usage: scripts/package-android.sh [appbundle|apk] [--no-split] [--distribution play|apk|galaxy] [flutter args]
# --distribution (docs/ANDROID-STORES-PLAN.md) says which store the build is for, and picks how it
# takes payment: play (the default) buys through Google Play; apk (GitHub Releases, Obtainium,
# IzzyOnDroid, Aptoide, APKPure, Uptodown) and galaxy (Samsung Galaxy Store) use web checkout. Every
# distribution is signed with the same upload key. A non-Play build is copied to dist/ as
# casama-<version>-android-<abi>.apk (or -universal.apk).
# An APK is built per ABI (--split-per-abi): one universal APK carries three copies of every
# native library (about 330 MB). Pass `apk --no-split` for the universal one. Every APK keeps
# pubspec's build number (no +1000 per ABI): see force-version-code-ignoring-abi in
# android/gradle.properties.
# Official builds pass telemetry credentials when CASAMA_OFFICIAL_BUILD=1.
set -euo pipefail
cd "$(dirname "$0")/../client"

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

target="appbundle"
if [[ "${1:-}" == "appbundle" || "${1:-}" == "apk" ]]; then
  target="$1"
  shift
fi

distribution="${CASAMA_DISTRIBUTION:-play}"
split=1
passthrough=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-split) split=0; shift ;;
    --distribution) distribution="${2:?--distribution needs a value}"; shift 2 ;;
    --distribution=*) distribution="${1#--distribution=}"; shift ;;
    *) passthrough+=("$1"); shift ;;
  esac
done
case "$distribution" in
  play|apk|galaxy) ;;
  *) echo "package-android: unknown distribution '$distribution' (play, apk or galaxy)." >&2; exit 2 ;;
esac
if [[ "$distribution" != "play" && "$target" != "apk" ]]; then
  echo "package-android: the $distribution distribution ships as an APK: run \`package-android.sh apk --distribution $distribution\`." >&2
  exit 2
fi

extra=()
if [[ "$target" == "apk" && "$split" == "1" ]]; then
  extra+=(--split-per-abi)
fi

# Crashlytics (D-416): a fresh mapping file id goes into the build, and the R8 mapping is uploaded
# under it afterwards, so Java/Kotlin frames in crash reports read as real names. Official builds only;
# a missing firebase CLI or sign-in just skips it.
mapping_id=android/app/src/main/res/values/crashlytics_mapping_id.xml
rm -f "$mapping_id"
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" ]] && command -v firebase >/dev/null 2>&1; then
  firebase crashlytics:mappingfile:generateid --resource-file="$mapping_id" >/dev/null 2>&1 \
    || { echo "package-android: couldn't make a Crashlytics mapping file id (firebase login?)."; rm -f "$mapping_id"; }
fi

# Sentry (D-417): a fresh ProGuard UUID in the app's assets, which the Sentry SDK reads, and the
# same mapping uploaded under it, so a remote switch to Sentry still gets readable Java/Kotlin frames.
# Only with SENTRY_AUTH_TOKEN (in the environment or ~/.config/casama/sentry-cli.env).
sentry_meta=android/app/src/main/assets/sentry-debug-meta.properties
rm -f "$sentry_meta"
sentry_env="${SENTRY_CLI_ENV_FILE:-$HOME/.config/casama/sentry-cli.env}"
if [[ "${CASAMA_OFFICIAL_BUILD:-0}" == "1" ]] && { [[ -n "${SENTRY_AUTH_TOKEN:-}" ]] || grep -qs '^SENTRY_AUTH_TOKEN=.' "$sentry_env"; }; then
  mkdir -p "$(dirname "$sentry_meta")"
  printf 'io.sentry.ProguardUuids=%s\n' "$(uuidgen | tr '[:upper:]' '[:lower:]')" > "$sentry_meta"
fi

flutter build "$target" --release \
  --dart-define=CASAMA_API_URL="${CASAMA_API_URL:-https://api.casama.ai}" \
  --dart-define=CASAMA_DISTRIBUTION="$distribution" \
  ${defines[@]+"${defines[@]}"} \
  ${extra[@]+"${extra[@]}"} \
  ${passthrough[@]+"${passthrough[@]}"}
# The R8 mapping to Crashlytics and Sentry (never fails the build).
../scripts/upload-symbols.sh android build/app/outputs/mapping/release/mapping.txt "$mapping_id" "$sentry_meta"

# Store builds other than Play: versioned copies in dist/, next to the desktop downloads.
if [[ "$distribution" != "play" ]]; then
  version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
  mkdir -p ../dist
  out=build/app/outputs/flutter-apk
  if [[ "$split" == "1" ]]; then
    for abi in arm64-v8a armeabi-v7a x86_64; do
      [[ -f "$out/app-$abi-release.apk" ]] || continue
      dest="../dist/casama-$version-android-$abi.apk"
      cp "$out/app-$abi-release.apk" "$dest"
      echo "$dest"
    done
  else
    dest="../dist/casama-$version-android-universal.apk"
    cp "$out/app-release.apk" "$dest"
    echo "$dest"
  fi
fi
