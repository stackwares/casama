#!/usr/bin/env bash
# Builds Casama's Docker images for linux/amd64 and linux/arm64 and pushes them to the registry
# (D-197). The build uses a clean checkout of one commit, never the working tree, so uncommitted
# work cannot end up in a published image.
#
#   scripts/publish-images.sh [--ref <commit|branch>] [--only <name,...>] [--platforms <list>]
#                             [--no-latest] [--registry <prefix>] [--retag <tag>]
#
# Defaults: ref HEAD, every image, linux/amd64,linux/arm64, registry ghcr.io/stackwares/casama.
# Tags: <short sha>, edge and latest (--no-latest skips latest). With latest, the git tag
# "selfhost" moves to the commit too: the desktop app's "Run Casama on this computer" downloads
# that commit's source and pulls its <short sha> images, so the two always match (D-216).
# --retag <tag> builds nothing: it points the new tags at an already published build, for a
# commit that changes nothing inside the images (compose, install.sh, docs). With --only, the
# images left out get the new <short sha> on their current latest build, so every published
# commit names a complete set. Log in first:
#   gh auth token | docker login ghcr.io -u <github user> --password-stdin
# New organization packages start private, and GitHub has no API to change that.
# Set each one to public once, or a server cannot pull it:
#   https://github.com/orgs/stackwares/packages/container/package/casama%2F<name>/settings
set -euo pipefail

registry=ghcr.io/stackwares/casama
ref=HEAD
only=""
platforms=linux/amd64,linux/arm64
latest=1
retag=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) ref="$2"; shift 2 ;;
    --only) only="$2"; shift 2 ;;
    --platforms) platforms="$2"; shift 2 ;;
    --registry) registry="$2"; shift 2 ;;
    --no-latest) latest=0; shift ;;
    --retag) retag="$2"; shift 2 ;;
    -h | --help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

root=$(git rev-parse --show-toplevel)
sha=$(git -C "$root" rev-parse --short=12 "$ref")
full=$(git -C "$root" rev-parse "$ref")
# The selfhost tag (and the app's download) needs the commit on GitHub.
if [[ "$latest" -eq 1 ]]; then
  git -C "$root" fetch --quiet origin main
  git -C "$root" merge-base --is-ancestor "$full" origin/main || { echo "$sha is not on origin/main; push it first (or use --no-latest)" >&2; exit 1; }
fi
src=$(mktemp -d "${TMPDIR:-/tmp}/casama-images.XXXXXX")
cleanup() { git -C "$root" worktree remove --force "$src" >/dev/null 2>&1 || rm -rf "$src"; }
trap cleanup EXIT
git -C "$root" worktree add --detach --quiet "$src" "$full"
echo "==> Building $sha for $platforms into $registry"

# name|Dockerfile (relative to the repository). computer-desktop builds on computer-headless.
# The web app is not in this list. A self-host deploy builds client/Dockerfile.web, which runs
# scripts/build-web.sh, so that image is always Wasm (D-196).
images=(
  "server|apps/server/Dockerfile"
  "supervisor|apps/supervisor/Dockerfile"
  "egress-proxy|infra/egress-proxy/Dockerfile"
  "turn|infra/turn/Dockerfile"
  "backup|infra/backup/Dockerfile"
  "computer-headless|infra/images/computer/Dockerfile.headless"
  "computer-desktop|infra/images/computer/Dockerfile.desktop"
)

wanted() { [[ -z "$only" ]] || [[ ",$only," == *",$1,"* ]]; }

for entry in "${images[@]}"; do
  name=${entry%%|*}
  file=${entry#*|}
  wanted "$name" || continue
  [[ -f "$src/$file" ]] || { echo "skip $name: $file is not in $sha"; continue; }
  tags=(-t "$registry/$name:$sha" -t "$registry/$name:edge")
  [[ "$latest" -eq 1 ]] && tags+=(-t "$registry/$name:latest")
  if [[ -n "$retag" ]]; then
    echo "==> $name: $retag -> $sha"
    docker buildx imagetools create "${tags[@]}" "$registry/$name:$retag"
    continue
  fi
  args=()
  [[ "$name" == computer-desktop ]] && args+=(--build-arg "BASE=$registry/computer-headless:$sha")
  echo "==> $name"
  # An array, not ${arr[@]+...}: bash 3.2 (macOS) mishandles that form once it is non-empty.
  build=(docker buildx build "$src" -f "$src/$file" --platform "$platforms" --push
    --label "org.opencontainers.image.revision=$full"
    --label "org.opencontainers.image.licenses=Apache-2.0"
    --label "org.opencontainers.image.title=casama-$name")
  if [[ ${#args[@]} -gt 0 ]]; then
    build+=("${args[@]}")
  fi
  build+=("${tags[@]}")
  "${build[@]}"
done

if [[ "$latest" -eq 1 && -n "$only" ]]; then
  # Every image carries every published <short sha>, so one tag pins a whole install: the images
  # left out of --only get this commit's tags on their current latest build.
  for entry in "${images[@]}"; do
    name=${entry%%|*}
    wanted "$name" && continue
    echo "==> $name: latest -> $sha"
    docker buildx imagetools create -t "$registry/$name:$sha" -t "$registry/$name:edge" "$registry/$name:latest"
  done
fi
if [[ "$latest" -eq 1 ]]; then
  git -C "$root" tag -f selfhost "$full" >/dev/null
  git -C "$root" push --quiet --force origin refs/tags/selfhost
  echo "==> Moved the selfhost tag to $sha"
fi
echo "==> Published $sha. Install with: ./install.sh --pull $sha (or --pull for latest)"
