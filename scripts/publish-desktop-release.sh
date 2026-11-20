#!/usr/bin/env bash
# Publishes a desktop release (D-159) to the public releases repo, where the apps look for updates:
# https://raw.githubusercontent.com/$CASAMA_RELEASES_REPO/main/appcast-{macos,windows}.xml
# (files on the repo's main branch, not release assets: CLI releases share the repo, so
# releases/latest isn't always a desktop release).
#
# Run after the packaging scripts have filled dist/ for this version: package-macos.sh (DMG +
# appcast-macos.xml), package-windows.ps1 (MSIX + appcast-windows.xml), package-linux.sh (tar.gz).
# Publishing makes the release public and every installed app offers it, so this asks first.
#
#   NOTES_FILE    release notes (Markdown); default: a one-line note
#   DRAFT=1       create a draft instead (nothing is offered until it's published on GitHub)
#
# The installers are also attached to a release on the source repo ($CASAMA_SOURCE_REPO, default
# stackwares/casama, public since D-406) so the project's Releases page shows the apps next to the
# CLI. The feeds still live on the releases repo; the source-repo release is never "latest", so CLI
# releases keep that slot there. Set CASAMA_SOURCE_REPO= (empty) to skip it.
set -euo pipefail
cd "$(dirname "$0")/.."
repo="${CASAMA_RELEASES_REPO:-stackwares/casama-releases}"
source_repo="${CASAMA_SOURCE_REPO-stackwares/casama}"
version=$(grep '^version:' client/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
tag="v$version"
gh repo view "$repo" --json visibility -q .visibility 2>/dev/null | grep -qx PUBLIC ||
  { echo "$repo must exist and be public (apps download updates without signing in)." >&2; exit 1; }
files=()
for f in dist/Casama-"$version"-macos.dmg dist/appcast-macos.xml dist/*"$version"*.msix dist/appcast-windows.xml \
  dist/casama-"$version"-linux-x64.tar.gz dist/casama-"$version"-linux-arm64.tar.gz dist/casama-"$version"-windows-x64.zip; do
  [[ -f "$f" ]] && files+=("$f")
done
(( ${#files[@]} )) || { echo "Nothing in dist/ for $version. Run the packaging scripts first." >&2; exit 1; }
grep -q "v$version/" dist/appcast-macos.xml 2>/dev/null || [[ ! -f dist/appcast-macos.xml ]] ||
  { echo "dist/appcast-macos.xml is for another version." >&2; exit 1; }
echo "Publishing Casama $version to $repo:"
printf '  %s\n' "${files[@]}"
read -r -p "Every installed desktop app will offer this update. Continue? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1
notes=(--notes "Casama $version")
[[ -n "${NOTES_FILE:-}" ]] && notes=(--notes-file "$NOTES_FILE")
# --latest: older builds read their feed from releases/latest; CLI releases use --latest=false.
gh release create "$tag" --repo "$repo" --title "Casama $version" --latest "${notes[@]}" ${DRAFT:+--draft} "${files[@]}"
[[ -n "${DRAFT:-}" ]] && { echo "Draft created; feeds left as they are."; exit 0; }
# The feeds the apps read: commit each one to the repo's main branch.
for feed in appcast-macos.xml appcast-windows.xml; do
  [[ -f "dist/$feed" ]] || continue
  sha=$(gh api "repos/$repo/contents/$feed" -q .sha 2>/dev/null || true)
  gh api -X PUT "repos/$repo/contents/$feed" -f message="Casama $version: $feed" \
    -f content="$(base64 < "dist/$feed" | tr -d '\n')" ${sha:+-f sha="$sha"} > /dev/null
  echo "Updated $feed"
done
# Mirror the installers (not the feeds) onto the source repo's Releases page. A failure here leaves the
# feeds above as they are, so it only warns.
if [[ -n "$source_repo" && "$source_repo" != "$repo" ]]; then
  installers=()
  for f in "${files[@]}"; do [[ "$f" == *appcast-* ]] || installers+=("$f"); done
  if gh release view "$tag" --repo "$source_repo" > /dev/null 2>&1; then
    echo "$source_repo already has $tag; left alone."
  else
    # Tag the commit that was built when it's on the remote, else the default branch.
    target=()
    [[ -n "$(git branch -r --contains HEAD 2>/dev/null)" ]] && target=(--target "$(git rev-parse HEAD)")
    gh release create "$tag" --repo "$source_repo" --title "Casama $version" --latest=false ${target[@]+"${target[@]}"} "${notes[@]}" "${installers[@]}" ||
      echo "Warning: could not publish $tag to $source_repo; the update feeds are fine." >&2
  fi
fi
