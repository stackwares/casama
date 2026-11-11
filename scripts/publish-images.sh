#!/usr/bin/env bash
# Builds Casama's Docker images for linux/amd64 and linux/arm64 and pushes them to the registry
# (D-197). The build uses a clean checkout of one commit, never the working tree, so uncommitted
# work cannot end up in a published image.
#
#   scripts/publish-images.sh [--ref <commit|branch>] [--only <name,...>] [--platforms <list>]
#                             [--no-latest] [--registry <prefix>]
#
# Defaults: ref HEAD, every image, linux/amd64,linux/arm64, registry ghcr.io/stackwares/casama.
# Tags: <short sha>, edge and latest (--no-latest skips latest). Log in first:
#   gh auth token | docker login ghcr.io -u <github user> --password-stdin
# New GHCR packages start private: make each one public once in its package settings.
set -euo pipefail

registry=ghcr.io/stackwares/casama
ref=HEAD
only=""
platforms=linux/amd64,linux/arm64
latest=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) ref="$2"; shift 2 ;;
    --only) only="$2"; shift 2 ;;
    --platforms) platforms="$2"; shift 2 ;;
    --registry) registry="$2"; shift 2 ;;
    --no-latest) latest=0; shift ;;
    -h | --help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

root=$(git rev-parse --show-toplevel)
sha=$(git -C "$root" rev-parse --short=12 "$ref")
full=$(git -C "$root" rev-parse "$ref")
src=$(mktemp -d "${TMPDIR:-/tmp}/casama-images.XXXXXX")
cleanup() { git -C "$root" worktree remove --force "$src" >/dev/null 2>&1 || rm -rf "$src"; }
trap cleanup EXIT
git -C "$root" worktree add --detach --quiet "$src" "$full"
echo "==> Building $sha for $platforms into $registry"

# name|Dockerfile (relative to the repository). computer-desktop builds on computer-headless.
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
  args=()
  [[ "$name" == computer-desktop ]] && args+=(--build-arg "BASE=$registry/computer-headless:$sha")
  echo "==> $name"
  docker buildx build "$src" -f "$src/$file" --platform "$platforms" --push \
    --label "org.opencontainers.image.revision=$full" \
    --label "org.opencontainers.image.licenses=Apache-2.0" \
    --label "org.opencontainers.image.title=casama-$name" \
    ${args[@]+"${args[@]}"} "${tags[@]}"
done

echo "==> Published $sha. Install with: ./install.sh --pull $sha (or --pull for latest)"
