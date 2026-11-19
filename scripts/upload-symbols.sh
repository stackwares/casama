#!/usr/bin/env bash
# Uploads debug symbols so crashes read as real functions and lines: to PostHog error tracking
# (docs/ANALYTICS-PLAN.md §8.4) and, in official builds, to Firebase Crashlytics (D-416). Never fails
# a build: with no CLI or no key it says so and moves on, and a failed upload is a warning.
#
#   scripts/upload-symbols.sh web     <build/web>                 source maps (dart2js build) of the web app
#   scripts/upload-symbols.sh apple   <folder> [ios|mac]          every dSYM under the folder (iOS archive or macOS products)
#   scripts/upload-symbols.sh android <mapping.txt> <res xml>     R8 mapping of an Android release build (Crashlytics)
#
# PostHog needs its CLI (npm i -g @posthog/cli) and POSTHOG_CLI_API_KEY, a personal API key with error
# tracking write and organization read scopes; POSTHOG_CLI_PROJECT_ID and POSTHOG_CLI_HOST are read by the CLI.
# When the key isn't in the environment, it's read from ~/.config/casama/posthog-cli.env (gitignored,
# outside the repo; copy in Vaultwarden "Casama · PostHog personal key: upload crash symbols (CLI)").
# Android to PostHog needs the PostHog Gradle plugin instead (docs/ANALYTICS-PLAN.md, Appendix C).
#
# Crashlytics runs only when CASAMA_OFFICIAL_BUILD=1, with the app ids in client/config/firebase.json:
#   dSYMs:   Crashlytics' upload-symbols tool, from the firebase-ios-sdk package the build already
#            checked out (or CRASHLYTICS_UPLOAD_SYMBOLS=/path/to/upload-symbols).
#   Android: the firebase CLI (npm i -g firebase-tools), signed in with `firebase login`.
#
# An iOS archive holds some dSYMs twice ("objective_c.framework.dSYM" and "objective_c.framework
# 1.dSYM", the same UUID: Xcode copies native-asset frameworks' dSYMs once per target that embeds
# them), and PostHog refuses a batch with a UUID in it twice (invalid_chunk_ids). So every dSYM is
# staged once per UUID set and the uploads read that copy.
set -uo pipefail
kind="${1:-}"
dir="${2:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
official="${CASAMA_OFFICIAL_BUILD:-0}"

env_file="${POSTHOG_CLI_ENV_FILE:-$HOME/.config/casama/posthog-cli.env}"
if [[ -z "${POSTHOG_CLI_API_KEY:-}" && -r "$env_file" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
fi
posthog_ready() {
  if [[ -z "${POSTHOG_CLI_API_KEY:-}" ]]; then
    echo "upload-symbols: POSTHOG_CLI_API_KEY is not set, skipping PostHog ($kind symbols)."
    return 1
  fi
  if ! command -v posthog-cli >/dev/null 2>&1; then
    echo "upload-symbols: posthog-cli is not installed (npm i -g @posthog/cli), skipping PostHog ($kind symbols)."
    return 1
  fi
}

# A value from client/config/firebase.json (empty when missing).
firebase_value() {
  local file="$root/client/config/firebase.json"
  [[ -r "$file" ]] || return 0
  node -e 'try{const d=require(process.argv[1]);for(const k of process.argv.slice(2)){if(d[k]){process.stdout.write(d[k]);break}}}catch(e){}' "$file" "$@" 2>/dev/null
}

version=$(grep '^version:' "$root/client/pubspec.yaml" | awk '{print $2}')

case "$kind" in
  web)
    if [[ -z "$dir" || ! -d "$dir" ]]; then echo "upload-symbols: '$dir' is not a folder, skipping."; exit 0; fi
    posthog_ready || exit 0
    posthog-cli sourcemap inject --directory "$dir" \
      && posthog-cli sourcemap upload --directory "$dir" --release-name casama-app --release-version "${version%%+*}" \
      || echo "upload-symbols: warning: web source maps were not uploaded."
    ;;

  apple)
    if [[ -z "$dir" || ! -d "$dir" ]]; then echo "upload-symbols: '$dir' is not a folder, skipping."; exit 0; fi
    platform="${3:-ios}"
    stage="$(mktemp -d "${TMPDIR:-/tmp}/casama-dsyms.XXXXXX")"
    trap 'rm -rf "$stage"' EXIT
    seen=" "
    kept=0
    skipped=0
    # Every dSYM bundle under the folder (not ones nested inside another bundle), first copy wins.
    while IFS= read -r -d '' dsym; do
      uuids=$(dwarfdump --uuid "$dsym" 2>/dev/null | awk '{print $2}' | sort | tr '\n' ' ')
      if [[ -z "$uuids" ]]; then continue; fi
      dupe=1
      for u in $uuids; do [[ "$seen" == *" $u "* ]] || dupe=0; done
      if [[ $dupe == 1 ]]; then skipped=$((skipped + 1)); continue; fi
      for u in $uuids; do seen+="$u "; done
      name=$(basename "$dsym")
      [[ -e "$stage/$name" ]] && name="${kept}-$name"
      # A clone on APFS (no extra space), a plain copy elsewhere.
      cp -Rc "$dsym" "$stage/$name" 2>/dev/null || cp -R "$dsym" "$stage/$name"
      kept=$((kept + 1))
    done < <(find "$dir" -name '*.dSYM' -type d -prune -print0)
    if [[ $kept == 0 ]]; then echo "upload-symbols: no dSYMs under '$dir', skipping."; exit 0; fi
    echo "upload-symbols: $kept dSYM(s) to upload ($skipped duplicate copies left out)."

    if posthog_ready; then
      posthog-cli dsym upload --directory "$stage" \
        || echo "upload-symbols: warning: dSYMs were not uploaded to PostHog."
    fi

    if [[ "$official" == "1" ]]; then
      app_id=$(firebase_value FIREBASE_IOS_APP_ID FIREBASE_APP_ID)
      tool="${CRASHLYTICS_UPLOAD_SYMBOLS:-}"
      if [[ -z "$tool" ]]; then
        tool=$(find "$root/client/build/ios/SourcePackages" "$root/client/build/macos/SourcePackages" \
          "$HOME/DerivedData" "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 \
          -path '*firebase-ios-sdk/Crashlytics/upload-symbols' -type f 2>/dev/null | head -n 1)
      fi
      if [[ -z "$app_id" ]]; then
        echo "upload-symbols: no Firebase Apple app id in client/config/firebase.json, skipping Crashlytics."
      elif [[ -z "$tool" || ! -x "$tool" ]]; then
        echo "upload-symbols: Crashlytics' upload-symbols wasn't found (set CRASHLYTICS_UPLOAD_SYMBOLS), skipping Crashlytics."
      else
        "$tool" --app-id "$app_id" --platform "$platform" -- "$stage" \
          || echo "upload-symbols: warning: dSYMs were not uploaded to Crashlytics."
      fi
    fi
    ;;

  android)
    mapping="$dir"
    resource="${3:-}"
    if [[ "$official" != "1" ]]; then exit 0; fi
    if [[ -z "$mapping" || ! -f "$mapping" ]]; then echo "upload-symbols: no R8 mapping at '$mapping', skipping Crashlytics."; exit 0; fi
    if [[ -z "$resource" || ! -f "$resource" ]]; then echo "upload-symbols: no mapping id resource at '$resource', skipping Crashlytics."; exit 0; fi
    if ! command -v firebase >/dev/null 2>&1; then
      echo "upload-symbols: the firebase CLI is not installed (npm i -g firebase-tools), skipping Crashlytics."
      exit 0
    fi
    app_id=$(firebase_value FIREBASE_ANDROID_APP_ID FIREBASE_APP_ID)
    if [[ -z "$app_id" ]]; then echo "upload-symbols: no Firebase Android app id, skipping Crashlytics."; exit 0; fi
    firebase crashlytics:mappingfile:upload --app="$app_id" --resource-file="$resource" "$mapping" \
      || echo "upload-symbols: warning: the R8 mapping was not uploaded to Crashlytics."
    ;;

  *)
    echo "usage: upload-symbols.sh web <dir> | apple <dir> [ios|mac] | android <mapping.txt> <resource.xml>" >&2
    exit 2
    ;;
esac
exit 0
