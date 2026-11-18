#!/usr/bin/env bash
# Builds Casama for Chrome (D-323) and zips it for the Chrome Web Store.
#
#   scripts/build-extension.sh          store build: apps/extension/dist/casama-chrome-<version>.zip
#   scripts/build-extension.sh dev      dev build (fixed id, local web app addresses), zipped as -dev
#   scripts/build-extension.sh firefox  Firefox build (Phase 5, no Act): casama-firefox-<version>.zip
#                                       plus casama-firefox-<version>-source.zip for Mozilla's review
#
# Edge Add-ons takes the store zip as it is (plan §13): there's no separate Edge build.
#
# The zip is the same bytes from the same commit: fixed timestamps, sorted entries, no extra file
# attributes. It prints the zip's SHA-256, which the publish step shows before any upload. This
# script never uploads anything; publishing needs Oliver's yes (AGENTS.md).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
target=${1:-store}
case "$target" in store | dev | firefox) ;; *) echo "usage: $0 [store|dev|firefox]" >&2; exit 2 ;; esac

cd "$root"
pnpm --filter @casama/extension exec vite build --mode "$target" --logLevel warn

dir="apps/extension/dist/$target"
version=$(node -p "require('./apps/extension/package.json').version")
if [ "$target" = firefox ]; then
  zip="$root/apps/extension/dist/casama-firefox-$version.zip"
else
  suffix=$([ "$target" = store ] && echo "" || echo "-$target")
  zip="$root/apps/extension/dist/casama-chrome-$version$suffix.zip"
fi

if [ "$target" = firefox ]; then
  # Firefox: its own id, the sidebar, a background script, Mozilla's data consent, and nothing
  # Act or the browser as a device needs (src/lib/browser.ts).
  node -e '
    const m = require(process.argv[1]);
    if (m.manifest_version !== 3) throw new Error("manifest_version must be 3");
    if (m.version !== process.argv[2]) throw new Error("manifest version " + m.version + " != package " + process.argv[2]);
    if (m.browser_specific_settings?.gecko?.id !== "casama@casama.ai") throw new Error("missing the gecko id");
    if (!m.browser_specific_settings.gecko.data_collection_permissions) throw new Error("missing Firefox data consent");
    if (!m.sidebar_action || m.side_panel) throw new Error("Firefox has the sidebar, not the side panel");
    if (!m.background?.scripts || m.background.service_worker) throw new Error("Firefox needs a background script");
    if (m.key || m.host_permissions || m.externally_connectable) throw new Error("no key, install-time hosts or externally_connectable");
    for (const p of ["debugger", "tabGroups", "tabCapture", "sidePanel", "offscreen", "gcm"])
      if ((m.permissions ?? []).includes(p)) throw new Error("Firefox build asks for " + p);
  ' "$root/$dir/manifest.json" "$version"
else
# The store refuses a manifest with a key, and shouldn't get source maps.
node -e '
  const m = require(process.argv[1]);
  const store = process.argv[2] === "store";
  if (m.manifest_version !== 3) throw new Error("manifest_version must be 3");
  if (m.version !== process.argv[3]) throw new Error("manifest version " + m.version + " != package " + process.argv[3]);
  if (store && m.key) throw new Error("the store build must not carry a key");
  if (store && JSON.stringify(m.externally_connectable) !== JSON.stringify({ matches: ["https://app.casama.ai/*"] }))
    throw new Error("the store build may only talk to https://app.casama.ai");
  // Site access is asked for at first run (plan §8), never granted at install.
  if (m.host_permissions) throw new Error("no build may ask for host permissions at install");
  // Phase 3 (Act): the debugger and tab groups, plus the managed settings schema for administrators.
  for (const p of ["debugger", "tabGroups"])
    if (!(m.permissions ?? []).includes(p)) throw new Error("missing the " + p + " permission (Act, Phase 3)");
  if (m.storage?.managed_schema !== "managed_schema.json" || !require("fs").existsSync(require("path").join(require("path").dirname(process.argv[1]), "managed_schema.json")))
    throw new Error("the managed settings schema is missing");
' "$root/$dir/manifest.json" "$target" "$version"
fi
if [ "$target" != dev ] && find "$dir" -name '*.map' | grep -q .; then
  echo "source maps in the store build" >&2
  exit 1
fi

rm -f "$zip"
# Same time stamp and modes everywhere: zip stores both, and touch reads the time in local time.
chmod -R u=rwX,go=rX "$dir"
find "$dir" -exec env TZ=UTC touch -h -t 198001020000 {} +
(cd "$dir" && find . -type f | LC_ALL=C sort | sed 's|^\./||' | TZ=UTC zip -X -D -q "$zip" -@)

size=$(wc -c <"$zip" | tr -d ' ')
echo "Built ${zip#"$root"/} ($size bytes)"
if command -v sha256sum >/dev/null; then sha256sum "$zip" | cut -d' ' -f1; else shasum -a 256 "$zip" | cut -d' ' -f1; fi

if [ "$target" = store ]; then
  echo "Edge Add-ons takes this same zip (apps/extension/store/edge/listing.md)."
fi

# Mozilla reviews bundled add-ons from their source: the committed code that builds this zip, with
# the steps in apps/extension/store/firefox/listing.md ("Notes for reviewers").
# Built from that source zip itself (no git there), the source step is skipped.
if [ "$target" = firefox ] && git -C "$root" rev-parse --verify -q HEAD >/dev/null 2>&1; then
  source_zip="$root/apps/extension/dist/casama-firefox-$version-source.zip"
  rm -f "$source_zip"
  git -C "$root" archive --format=zip -o "$source_zip" HEAD -- \
    package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json biome.json LICENSE \
    apps/extension packages/client packages/contracts packages/domain/src/browser-guard.ts \
    scripts/build-extension.sh
  echo "Source for Mozilla's review: ${source_zip#"$root"/}"
fi
