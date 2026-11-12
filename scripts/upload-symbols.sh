#!/usr/bin/env bash
# Uploads debug symbols to PostHog error tracking so crashes read as real functions and lines
# (docs/ANALYTICS-PLAN.md §8.4). Never fails a build: with no CLI or no key it says so and moves on,
# and a failed upload is a warning.
#
#   scripts/upload-symbols.sh web   <build/web>          source maps (dart2js build) of the web app
#   scripts/upload-symbols.sh apple <dSYMs folder>       dSYMs of an iOS or macOS build
#
# Needs the PostHog CLI (npm i -g @posthog/cli) and POSTHOG_CLI_API_KEY, a personal API key with error
# tracking write and organization read scopes; POSTHOG_CLI_PROJECT_ID and POSTHOG_CLI_HOST are read by the CLI.
# Android needs the PostHog Gradle plugin instead (docs/ANALYTICS-PLAN.md, Appendix C).
set -uo pipefail
kind="${1:-}"
dir="${2:-}"
if [[ -z "${POSTHOG_CLI_API_KEY:-}" ]]; then
  echo "upload-symbols: POSTHOG_CLI_API_KEY is not set, skipping ($kind symbols)."
  exit 0
fi
if ! command -v posthog-cli >/dev/null 2>&1; then
  echo "upload-symbols: posthog-cli is not installed (npm i -g @posthog/cli), skipping ($kind symbols)."
  exit 0
fi
if [[ -z "$dir" || ! -d "$dir" ]]; then
  echo "upload-symbols: '$dir' is not a folder, skipping."
  exit 0
fi
version=$(grep '^version:' "$(dirname "$0")/../client/pubspec.yaml" | awk '{print $2}')
case "$kind" in
  web)
    posthog-cli sourcemap inject --directory "$dir" \
      && posthog-cli sourcemap upload --directory "$dir" --release-name casama-app --release-version "${version%%+*}" \
      || echo "upload-symbols: warning: web source maps were not uploaded."
    ;;
  apple)
    posthog-cli dsym upload --directory "$dir" \
      || echo "upload-symbols: warning: dSYMs were not uploaded."
    ;;
  *)
    echo "usage: upload-symbols.sh web <dir> | apple <dir>" >&2
    exit 2
    ;;
esac
exit 0
