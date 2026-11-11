#!/usr/bin/env bash
# Publishes a desktop release (D-159) to the public releases repo, where the apps look for updates:
# https://github.com/$CASAMA_RELEASES_REPO/releases/latest/download/appcast-{macos,windows}.xml
#
# Run after the packaging scripts have filled dist/ for this version: package-macos.sh (DMG +
# appcast-macos.xml), package-windows.ps1 (MSIX + appcast-windows.xml), package-linux.sh (tar.gz).
# Publishing makes the release public and every installed app offers it, so this asks first.
#
#   NOTES_FILE    release notes (Markdown); default: a one-line note
#   DRAFT=1       create a draft instead (nothing is offered until it's published on GitHub)
set -euo pipefail
cd "$(dirname "$0")/.."
repo="${CASAMA_RELEASES_REPO:-stackwares/casama-releases}"
version=$(grep '^version:' client/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
tag="v$version"
gh repo view "$repo" --json visibility -q .visibility 2>/dev/null | grep -qx PUBLIC ||
  { echo "$repo must exist and be public (apps download updates without signing in)." >&2; exit 1; }
files=()
for f in dist/Casama-"$version"-macos.dmg dist/appcast-macos.xml dist/*"$version"*.msix dist/appcast-windows.xml \
  dist/casama-"$version"-linux-x64.tar.gz dist/casama-"$version"-windows-x64.zip; do
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
gh release create "$tag" --repo "$repo" --title "Casama $version" "${notes[@]}" ${DRAFT:+--draft} "${files[@]}"
