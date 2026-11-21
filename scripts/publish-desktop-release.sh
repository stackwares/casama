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
# A new build of a version that's already published (same version, higher build number) replaces
# that release's files and notes in place: the file names and download links stay the same, and the
# feeds tell installed apps about the new build number.
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
build=$(grep '^version:' client/pubspec.yaml | awk '{print $2}' | cut -d+ -f2)
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
# A feed left over from an older build of the same version would point apps at the wrong build.
grep -q "<sparkle:version>$build</sparkle:version>" dist/appcast-macos.xml 2>/dev/null || [[ ! -f dist/appcast-macos.xml ]] ||
  { echo "dist/appcast-macos.xml isn't for build $build. Run scripts/package-macos.sh again." >&2; exit 1; }
existing=""
gh release view "$tag" --repo "$repo" > /dev/null 2>&1 && existing=1
echo "Publishing Casama $version (build $build) to $repo${existing:+, replacing the files of its existing $tag release}:"
printf '  %s\n' "${files[@]}"
read -r -p "Every installed desktop app will offer this update. Continue? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1
notes=(--notes "Casama $version (build $build)")
[[ -n "${NOTES_FILE:-}" ]] && notes=(--notes-file "$NOTES_FILE")
# Creates the release, or for a new build of a published version replaces its files and notes.
# $1 repo, $2 "latest" or "not-latest", then the files.
publish() {
  local r=$1 latest=$2; shift 2
  local flag=--latest; [[ "$latest" == latest ]] || flag=--latest=false
  if gh release view "$tag" --repo "$r" > /dev/null 2>&1; then
    gh release upload "$tag" --repo "$r" --clobber "$@" &&
      gh release edit "$tag" --repo "$r" --title "Casama $version" "$flag" "${notes[@]}" > /dev/null
  else
    # Tag the commit that was built when it's on the remote, else the default branch.
    local target=()
    [[ -n "$(git branch -r --contains HEAD 2>/dev/null)" ]] && target=(--target "$(git rev-parse HEAD)")
    gh release create "$tag" --repo "$r" --title "Casama $version" "$flag" ${target[@]+"${target[@]}"} \
      "${notes[@]}" ${DRAFT:+--draft} "$@"
  fi
}
if [[ -n "${DRAFT:-}" && -n "$existing" ]]; then
  echo "$tag is already published on $repo; a draft can't replace it. Run without DRAFT=1." >&2; exit 1
fi
# --latest: older builds read their feed from releases/latest; CLI releases use --latest=false.
# The installers go up before the feeds, so a feed never points at a file that isn't there yet.
publish "$repo" latest "${files[@]}"
[[ -n "${DRAFT:-}" ]] && { echo "Draft created; feeds left as they are."; exit 0; }
# The feeds the apps read: commit each one to the repo's main branch.
for feed in appcast-macos.xml appcast-windows.xml; do
  [[ -f "dist/$feed" ]] || continue
  sha=$(gh api "repos/$repo/contents/$feed" -q .sha 2>/dev/null || true)
  gh api -X PUT "repos/$repo/contents/$feed" -f message="Casama $version (build $build): $feed" \
    -f content="$(base64 < "dist/$feed" | tr -d '\n')" ${sha:+-f sha="$sha"} > /dev/null
  echo "Updated $feed"
done
# Homebrew: bump the cask in our tap (stackwares/homebrew-tap) to this DMG. A failure only warns:
# the feeds above are what installed apps read. Set CASAMA_TAP_REPO= (empty) to skip.
tap_repo="${CASAMA_TAP_REPO-stackwares/homebrew-tap}"
if [[ -n "$tap_repo" && -f "dist/Casama-$version-macos.dmg" ]]; then
  (
    sha=$(shasum -a 256 "dist/Casama-$version-macos.dmg" | awk '{print $1}')
    fsha=$(gh api "repos/$tap_repo/contents/Casks/casama.rb" -q .sha 2>/dev/null || true)
    b64=$(scripts/homebrew-cask.sh "$version" "$sha" | base64 | tr -d '\n')
    gh api -X PUT "repos/$tap_repo/contents/Casks/casama.rb" -f message="casama $version" \
      -f content="$b64" ${fsha:+-f sha="$fsha"} > /dev/null && echo "Updated Homebrew cask to $version"
  ) || echo "Warning: could not bump the Homebrew cask; the update feeds are fine." >&2
fi
# Mirror the installers (not the feeds) onto the source repo's Releases page. A failure here leaves the
# feeds above as they are, so it only warns.
if [[ -n "$source_repo" && "$source_repo" != "$repo" ]]; then
  installers=()
  for f in "${files[@]}"; do [[ "$f" == *appcast-* ]] || installers+=("$f"); done
  publish "$source_repo" not-latest "${installers[@]}" ||
    echo "Warning: could not publish $tag to $source_repo; the update feeds are fine." >&2
fi
