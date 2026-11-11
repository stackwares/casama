#!/usr/bin/env bash
# Publishes the marketing page (casama.ai, www), the docs (docs.casama.ai) and the gallery
# (gallery.casama.ai) to Cloudflare Workers static assets. Needs `wrangler login` on the
# Stackwares account. Custom domains and their DNS records are created by `wrangler deploy`.
set -euo pipefail
cd "$(dirname "$0")/.."
read -r -p "Publish casama.ai, docs.casama.ai and gallery.casama.ai now? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
(cd docs-site && npm run build)
(cd site && wrangler deploy)
(cd docs-site && wrangler deploy)
(cd gallery && wrangler deploy)
echo "Published: https://casama.ai, https://docs.casama.ai and https://gallery.casama.ai"
