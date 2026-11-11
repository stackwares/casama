#!/usr/bin/env bash
# Publishes the marketing page (casama.ai, www) and the docs (docs.casama.ai) to Cloudflare
# Workers static assets. Needs `wrangler login` on the Stackwares account. Custom domains and
# their DNS records are created by `wrangler deploy` from each wrangler.jsonc.
set -euo pipefail
cd "$(dirname "$0")/.."
read -r -p "Publish casama.ai and docs.casama.ai now? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
(cd docs-site && npm run build)
(cd site && wrangler deploy)
(cd docs-site && wrangler deploy)
echo "Published: https://casama.ai and https://docs.casama.ai"
