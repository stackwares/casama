#!/usr/bin/env bash
# Keeps the CLIs on bot computers current (D-251). They are pinned in the computer images
# (Dockerfile.headless, Dockerfile.desktop), so a computer gets them from its image the next time it
# starts from a fresh container: on waking from idle sleep, or on a restart.
#
#   scripts/computer-tools.sh check              pinned vs latest on npm; exits 10 when one is behind
#   scripts/computer-tools.sh bump [--no-build] [--no-pr]
#       In a separate checkout of origin/main: raises the pins, builds both images for this machine
#       and checks each CLI runs in them, then pushes a branch and opens a pull request. Skips when
#       nothing is behind or a computer-tools pull request is already open. --no-build skips the
#       image check (the PR says so); --no-pr leaves the commit in the checkout and prints its path.
#   scripts/computer-tools.sh prod-pull --yes
#       PRODUCTION: after scripts/publish-images.sh has pushed new computer images, pulls both on the
#       VPS (its supervisor creates containers from the local copy of :latest) and removes the old
#       layers. New computers and wake-ups use the new image right away; the warm pool replaces its
#       members within a minute. Ask Oliver first (AGENTS.md).
#
# Weekly: ~/Library/LaunchAgents/ai.casama.computer-tools.plist runs `bump` on Mondays.
set -euo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
# ARG name | npm package | Dockerfile
tools=(
  "AGENT_BROWSER_VERSION|agent-browser|infra/images/computer/Dockerfile.headless"
  "PLAYWRIGHT_VERSION|playwright|infra/images/computer/Dockerfile.headless"
  "AGENT_DESKTOP_VERSION|agent-desktop|infra/images/computer/Dockerfile.desktop"
)
images=(computer-headless computer-desktop)
registry=ghcr.io/stackwares/casama
branch_prefix=computer-tools/

pinned() { sed -nE "s/^ARG $1=([^[:space:]]+).*/\1/p" "$2" | head -1; }
latest() { npm view "$1" version 2>/dev/null; }

# Prints "ARG|package|file|pinned|latest" for every tool, reading the Dockerfiles under $1.
versions() {
  local dir=$1 t arg pkg file have want
  for t in "${tools[@]}"; do
    IFS='|' read -r arg pkg file <<<"$t"
    have=$(pinned "$arg" "$dir/$file")
    want=$(latest "$pkg")
    [[ -n "$have" && -n "$want" ]] || { echo "Couldn't read $arg ($have) or npm's $pkg ($want)" >&2; exit 1; }
    echo "$arg|$pkg|$file|$have|$want"
  done
}

check() {
  local behind=0 arg pkg file have want
  while IFS='|' read -r arg pkg file have want; do
    if [[ "$have" == "$want" ]]; then
      printf '  %-15s %-10s current\n' "$pkg" "$have"
    else
      printf '  %-15s %-10s -> %s\n' "$pkg" "$have" "$want"
      behind=1
    fi
  done < <(versions "$root")
  [[ $behind -eq 0 ]] || exit 10
}

# Builds both images from $1 for this machine and checks each CLI starts. Prints a summary line.
smoke() {
  local dir=$1 tag=tools-check-$$ out
  docker info >/dev/null 2>&1 || { echo "Docker isn't running; images not built"; return 1; }
  trap 'docker rmi -f "casama/computer-headless:$tag" "casama/computer-desktop:$tag" >/dev/null 2>&1 || true' RETURN
  docker build -q -f "$dir/infra/images/computer/Dockerfile.headless" -t "casama/computer-headless:$tag" "$dir" >/dev/null
  docker build -q -f "$dir/infra/images/computer/Dockerfile.desktop" --build-arg "BASE=casama/computer-headless:$tag" \
    -t "casama/computer-desktop:$tag" "$dir" >/dev/null
  out=$(docker run --rm --entrypoint sh "casama/computer-desktop:$tag" -c \
    'agent-browser --version && playwright --version && chrome --version && agent-desktop version' 2>&1) || {
    echo "A CLI didn't start in the new desktop image:"; echo "$out"; return 1; }
  echo "Built both images on $(uname -m) and each CLI started:"
  echo "$out" | sed 's/^/    /'
}

bump() {
  local build=1 pr=1
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-build) build=0; shift ;;
      --no-pr) pr=0; shift ;;
      *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
  done
  if [[ $pr -eq 1 ]]; then
    local open
    open=$(gh pr list --repo stackwares/casama --state open --json headRefName,url \
      --jq "map(select(.headRefName | startswith(\"$branch_prefix\"))) | .[0].url // empty")
    [[ -z "$open" ]] || { echo "A computer-tools pull request is already open: $open"; exit 0; }
  fi

  git -C "$root" fetch --quiet origin main
  local changes="" arg pkg file have want
  # Not local: the EXIT trap reads them after this function has returned.
  dir=$(mktemp -d "${TMPDIR:-/tmp}/casama-tools.XXXXXX")
  branch="${branch_prefix}$(date +%Y-%m-%d)"
  # A separate checkout: other work in the main tree is never touched or swept into the commit.
  git -C "$root" worktree add --quiet -b "$branch" "$dir" origin/main
  keep=0
  cleanup() { [[ $keep -eq 1 ]] || { git -C "$root" worktree remove --force "$dir" >/dev/null 2>&1; git -C "$root" branch -D "$branch" >/dev/null 2>&1 || true; }; }
  trap cleanup EXIT

  while IFS='|' read -r arg pkg file have want; do
    [[ "$have" == "$want" ]] && continue
    sed -i.bak -E "s/^ARG $arg=.*/ARG $arg=$want/" "$dir/$file" && rm "$dir/$file.bak"
    changes+="- \`$pkg\` $have → $want ([release](https://www.npmjs.com/package/$pkg/v/$want))"$'\n'
  done < <(versions "$dir")
  [[ -n "$changes" ]] || { echo "Every computer CLI is current."; exit 0; }
  echo "Raising:"; echo "$changes"

  local verified
  if [[ $build -eq 1 ]]; then
    verified=$(smoke "$dir") || { echo "$verified" >&2; echo "Not opening a pull request." >&2; exit 1; }
  else
    verified="Images not built (--no-build): build them before merging."
  fi
  echo "$verified"

  git -C "$dir" add infra/images/computer/Dockerfile.headless infra/images/computer/Dockerfile.desktop
  git -C "$dir" commit --quiet -m "Bot computers get newer CLIs

${changes}
Made by scripts/computer-tools.sh bump."
  if [[ $pr -eq 0 ]]; then
    keep=1
    echo "Committed on $branch in $dir (no pull request)."
    return
  fi
  git -C "$dir" push --quiet -u origin "$branch"
  gh pr create --repo stackwares/casama --head "$branch" --base main \
    --title "Bot computers get newer CLIs ($(date +%Y-%m-%d))" \
    --body "Raises the CLI versions pinned in the computer images.

${changes}
${verified}

After merging:
1. \`scripts/publish-images.sh --only computer-headless,computer-desktop\`
2. \`scripts/computer-tools.sh prod-pull --yes\` (production: ask first)

Each computer picks the new tools up the next time it starts from a fresh container (waking from idle sleep, or a restart); its home folder is restored as before. The warm pool replaces older members within a minute (D-251).

Made by \`scripts/computer-tools.sh bump\`."
}

prod_pull() {
  [[ "${1:-}" == "--yes" ]] || { echo "This changes production. Rerun with --yes once Oliver has agreed." >&2; exit 2; }
  local pulls="" i
  for i in "${images[@]}"; do pulls+="docker pull -q $registry/$i:latest && "; done
  # shellcheck disable=SC2029 # expands here on purpose
  ssh casama-vps "set -e; ${pulls} docker image prune -f >/dev/null && docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.CreatedSince}}' | grep computer-"
}

case "${1:-}" in
  check) check ;;
  bump) shift; bump "$@" ;;
  prod-pull) shift; prod_pull "$@" ;;
  *) sed -n '2,19p' "$0"; exit 2 ;;
esac
