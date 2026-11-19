#!/usr/bin/env bash
# Builds the Wear OS app (D-410): client/wear, its own Gradle project with the phone's
# applicationId (ai.casama.app), so Play lists it with the phone app under the Wear OS form factor.
#
#   scripts/package-wear.sh            release App Bundle (bundleRelease) for Play's Wear OS track
#   scripts/package-wear.sh apk        release APK, to sideload on a watch or emulator
#   scripts/package-wear.sh debug      debug APK
#   scripts/package-wear.sh debug -PdefaultServer=https://api-dev.casama.ai
#                                      debug APK whose code sign-in goes to a dev stack (debug only:
#                                      a bundle or apk refuses it and always uses Casama Cloud)
#
# versionName comes from client/pubspec.yaml; versionCode is 1,000,000,000 + pubspec's build number,
# so the watch build never collides with the phone's codes on the same listing. BUILD_NUMBER=<n>
# overrides it. Signing reads client/android/key.properties, as the phone does; without it a
# release is signed with the debug key and Play will refuse it. Firebase options come from
# client/config/firebase.json when present (pushes stay off without it).
#
# This is a build: ask before running it (AGENTS.md).
set -euo pipefail
cd "$(dirname "$0")/../client/wear"

target="${1:-bundle}"
shift || true

args=()
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  args+=("-PbuildNumber=${BUILD_NUMBER}")
fi

case "$target" in
  bundle) task=":app:bundleRelease"; out="app/build/outputs/bundle/release" ;;
  apk) task=":app:assembleRelease"; out="app/build/outputs/apk/release" ;;
  debug) task=":app:assembleDebug"; out="app/build/outputs/apk/debug" ;;
  *) echo "usage: $0 [bundle|apk|debug] [gradle args]" >&2; exit 64 ;;
esac

# Code sign-in's server can only be changed in a debug build (app/build.gradle.kts refuses it too).
if [[ "$target" != "debug" ]]; then
  case " $* " in
    *defaultServer*)
      echo "error: -PdefaultServer is for 'debug' builds only; a $target must use Casama Cloud" >&2
      exit 64
      ;;
  esac
  if [[ -n "${ORG_GRADLE_PROJECT_defaultServer:-}" ]]; then
    echo "error: ORG_GRADLE_PROJECT_defaultServer is set; unset it to build a $target" >&2
    exit 64
  fi
fi

if [[ ! -f ../android/key.properties && "$target" != "debug" ]]; then
  echo "warning: client/android/key.properties is missing; the release is signed with the debug key" >&2
fi

./gradlew --no-daemon "$task" ${args[@]+"${args[@]}"} "$@"
echo "Built: client/wear/$out"
ls -la "$out"
