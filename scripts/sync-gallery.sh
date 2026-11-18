#!/usr/bin/env bash
# Copies the monorepo's gallery/ into the public catalog repo (stackwares/casama-gallery) as one
# "Sync with the Casama monorepo" commit (D-315). The monorepo is the source; pull requests merged in
# the public repo (contributors and in-app submissions) have to be brought into gallery/ first, and
# this script stops instead of overwriting them.
#   scripts/sync-gallery.sh            show what would change, then ask before pushing
#   scripts/sync-gallery.sh --yes      push without asking
#   scripts/sync-gallery.sh --pull     copy the public repo's changes since the last sync into gallery/
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="${GALLERY_REPO:-stackwares/casama-gallery}"
MODE="${1:-}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

gh repo clone "$REPO" "$WORK/repo" -- --quiet
cd "$WORK/repo"
BASE="$(git log --format=%H --grep='^Sync with the Casama monorepo' -n 1)"
[[ -n "$BASE" ]] || { echo "No earlier sync commit in $REPO; sync by hand once." >&2; exit 1; }
CHANGED="$(git diff --name-only "$BASE" HEAD)"
cd - >/dev/null

# Files the public repo changed since the last sync that gallery/ doesn't have yet.
behind=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ ! -e "$WORK/repo/$f" ]]; then
    [[ -e "gallery/$f" ]] && behind+=("$f (deleted there)")
  elif ! cmp -s "$WORK/repo/$f" "gallery/$f"; then
    behind+=("$f")
  fi
done <<<"$CHANGED"

if [[ "$MODE" == "--pull" ]]; then
  ((${#behind[@]})) || { echo "gallery/ already has everything merged in $REPO."; exit 0; }
  for f in "${behind[@]}"; do
    f="${f% (deleted there)}"
    if [[ -e "$WORK/repo/$f" ]]; then mkdir -p "gallery/$(dirname "$f")" && cp "$WORK/repo/$f" "gallery/$f"; else rm -f "gallery/$f"; fi
    echo "pulled $f"
  done
  node gallery/check.mjs
  echo "Review, commit and push gallery/, then run scripts/sync-gallery.sh."
  exit 0
fi

if ((${#behind[@]})); then
  echo "$REPO has changes since the last sync that gallery/ doesn't have:" >&2
  printf '  %s\n' "${behind[@]}" >&2
  echo "Bring them in first: scripts/sync-gallery.sh --pull" >&2
  exit 1
fi

node gallery/check.mjs --check
rsync -a --delete --exclude .git --exclude node_modules \
  --exclude /i --exclude /by --exclude /og.png --exclude /sitemap.xml --exclude /manifest.sig \
  gallery/ "$WORK/repo/"
SHA="$(git rev-parse --short HEAD)"
cd "$WORK/repo"
git add -A
if git diff --cached --quiet; then echo "$REPO is already in sync."; exit 0; fi
git diff --cached --stat | tail -n 15
if [[ "$MODE" != "--yes" ]]; then
  read -r -p "Push this to $REPO? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
fi
git commit --quiet -m "Sync with the Casama monorepo at $SHA"
git push --quiet origin HEAD
echo "Synced $REPO to monorepo $SHA."
