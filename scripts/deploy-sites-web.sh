#!/usr/bin/env bash
# Publishes the sites zone's own page (sites-site/, docs/SITES-AND-DOMAINS-PLAN.md §7.11) to the
# bare zone and www. Production: ask Oliver first (AGENTS.md). Needs `wrangler login` on the
# Stackwares account with the sites zone on it, and the zone's name:
#
#   CASAMA_SITES_ZONE=<zone> scripts/deploy-sites-web.sh --dry-run   build and show what would be published
#   CASAMA_SITES_ZONE=<zone> scripts/deploy-sites-web.sh             same, then ask before publishing
#   CASAMA_SITES_ZONE=<zone> scripts/deploy-sites-web.sh --yes       publish without asking
#
# CASAMA_SITES_API (default https://api.casama.ai) is where the report form posts.
# The page shares casama.link's look: link.css and the brand assets are copied from link-site/.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
zone="${CASAMA_SITES_ZONE:-}"
api="${CASAMA_SITES_API:-https://api.casama.ai}"
mode=ask
case "${1:-}" in
  --dry-run) mode=dry ;;
  --yes) mode=yes ;;
  "") ;;
  *) echo "Usage: CASAMA_SITES_ZONE=<zone> $0 [--dry-run|--yes]" >&2; exit 2 ;;
esac
[[ "$zone" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]] || {
  echo "Set CASAMA_SITES_ZONE to the sites zone (a domain of its own, never casama.ai)." >&2
  exit 2
}
[[ "$zone" == "casama.ai" || "$zone" == *.casama.ai || "$zone" == "casama.link" ]] && {
  echo "The sites zone must be a domain of its own, never casama.ai or casama.link." >&2
  exit 2
}

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
cp -R "$root/sites-site/." "$build/"
cp "$root/link-site/link.css" "$build/link.css"
mkdir -p "$build/assets"
cp -R "$root/link-site/assets/." "$build/assets/"
# The zone and API address go into every text file.
while IFS= read -r -d '' f; do
  sed -i.bak -e "s|{{ZONE}}|$zone|g" -e "s|{{API}}|$api|g" "$f" && rm -f "$f.bak"
done < <(find "$build" -type f \( -name '*.html' -o -name '*.txt' -o -name '*.jsonc' -o -name '_headers' \) -print0)
mv "$build/wrangler.template.jsonc" "$build/wrangler.jsonc"

cd "$build"
node --check worker.js
node --check sites.js
for f in index.html 404.html link.css sites.js robots.txt .well-known/security.txt assets/brand/casama-mark.js; do
  [[ -s "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done
if grep -rl '{{' --include='*.html' --include='*.txt' --include='_headers' . >/dev/null; then
  echo "A placeholder was left unfilled." >&2
  exit 1
fi
expires=$(sed -n 's/^Expires: \(.\{10\}\).*/\1/p' .well-known/security.txt)
if [[ "$(date -u -v+30d +%F 2>/dev/null || date -u -d '+30 days' +%F)" > "$expires" ]]; then
  echo "sites-site/.well-known/security.txt expires $expires: move Expires forward." >&2
  exit 1
fi
echo "Files: $(find . -type f ! -path './.wrangler/*' | wc -l | tr -d ' ') (worker: worker.js)"
wrangler deploy --dry-run --outdir "$(mktemp -d)" >/dev/null
echo "Worker casama-sites-site → $zone, www.$zone (reports post to $api)"

[[ "$mode" == dry ]] && { echo "Dry run: nothing published."; exit 0; }
if [[ "$mode" == ask ]]; then
  read -r -p "Publish sites-site/ to https://$zone now? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
fi

wrangler deploy

fail=0
check() { # url, wanted "code" prefix
  local got; got=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$1" || true)
  if [[ "$got" == "$2"* ]]; then echo "OK $1 ($got)"; else echo "FAILED $1: $got" >&2; fail=1; fi
}
check "https://$zone/" "200"
check "https://$zone/.well-known/security.txt" "200"
check "https://www.$zone/x" "301 https://$zone/x"
exit $fail
