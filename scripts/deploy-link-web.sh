#!/usr/bin/env bash
# Publishes casama.link's own page (link-site/, D-317) to the bare casama.link and www.casama.link.
# Production: ask Oliver first (AGENTS.md). Needs `wrangler login` on the Stackwares account, and the
# casama.link zone on that account (wrangler makes the two custom domains and their DNS records).
#
# The worker answers only those two names. Every <label>.casama.link is a Casama Link address, a
# DNS record the API makes per server, and never passes through this worker.
#
#   scripts/deploy-link-web.sh --dry-run   check the files and show what would be published
#   scripts/deploy-link-web.sh             same, then ask before publishing
#   scripts/deploy-link-web.sh --yes       publish without asking
set -euo pipefail
cd "$(dirname "$0")/../link-site"

URL=https://casama.link
mode=ask
case "${1:-}" in
  --dry-run) mode=dry ;;
  --yes) mode=yes ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run|--yes]" >&2; exit 2 ;;
esac

node --check worker.js
node --check link.js
for f in index.html 404.html link.css link.js favicon.png robots.txt .well-known/security.txt assets/brand/casama-mark.js; do
  [[ -s "$f" ]] || { echo "Missing link-site/$f" >&2; exit 1; }
done
# security.txt must not expire (RFC 9116): warn a month ahead.
expires=$(sed -n 's/^Expires: \(.\{10\}\).*/\1/p' .well-known/security.txt)
if [[ "$(date -u -v+30d +%F 2>/dev/null || date -u -d '+30 days' +%F)" > "$expires" ]]; then
  echo "link-site/.well-known/security.txt expires $expires: move Expires forward." >&2
  exit 1
fi
echo "Files: $(find . -type f ! -path './.wrangler/*' | grep -cvxFf <(sed 's|^|./|' .assetsignore)) (worker: worker.js)"
wrangler deploy --dry-run --outdir "$(mktemp -d)" >/dev/null
echo "Worker casama-link-site → casama.link, www.casama.link"

[[ "$mode" == dry ]] && { echo "Dry run: nothing published."; exit 0; }
if [[ "$mode" == ask ]]; then
  read -r -p "Publish link-site/ to $URL now? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
fi

wrangler deploy

# The page, security.txt and the www redirect.
fail=0
check() { # url, wanted "code" prefix
  local got; got=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$1" || true)
  if [[ "$got" == "$2"* ]]; then echo "OK $1 ($got)"; else echo "FAILED $1: $got" >&2; fail=1; fi
}
check "$URL/" "200"
check "$URL/.well-known/security.txt" "200"
check "https://www.casama.link/x" "301 https://casama.link/x"
exit $fail
