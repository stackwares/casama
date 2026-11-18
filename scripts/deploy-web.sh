#!/usr/bin/env bash
# Publishes the marketing page (casama.ai, www), the docs (docs.casama.ai) and the gallery
# (gallery.casama.ai) to Cloudflare Workers static assets. Needs `wrangler login` on the
# Stackwares account. Custom domains and their DNS records are created by `wrangler deploy`.
#
# The gallery's manifest.json is signed before anything is published (D-315), so servers that
# check the signature never see an unsigned or stale catalog. The private key comes from, in order:
#   GALLERY_SIGNING_KEY (PEM or base64 seed), ~/.config/casama/gallery-signing-key.pem, or
#   Vaultwarden item "Casama · Gallery catalog signing key (Ed25519)" through `bw` (unlock first:
#   export BW_SESSION="$(bw unlock --raw)").
set -euo pipefail
cd "$(dirname "$0")/.."

# The public key servers trust, read from the server so the two can't drift.
PUBLIC_KEY="$(sed -n 's/^export const CASAMA_GALLERY_PUBLIC_KEY = "\(.*\)";$/\1/p' apps/server/src/services/gallery.ts)"
[[ -n "$PUBLIC_KEY" ]] || { echo "Couldn't read CASAMA_GALLERY_PUBLIC_KEY from apps/server/src/services/gallery.ts." >&2; exit 1; }
VAULT_ITEM="7b476db6-8bf4-402e-95b0-d7040e00a383"
KEY_FILE="${HOME}/.config/casama/gallery-signing-key.pem"

signing_key() {
  if [[ -n "${GALLERY_SIGNING_KEY:-}" ]]; then printf '%s' "$GALLERY_SIGNING_KEY"; return; fi
  if [[ -r "$KEY_FILE" ]]; then cat "$KEY_FILE"; return; fi
  if command -v bw >/dev/null && bw get password "$VAULT_ITEM" 2>/dev/null; then return; fi
  return 1
}

# Check the catalog and sign it before publishing anything, so a missing key stops the whole deploy.
rm -f gallery/manifest.sig
node gallery/check.mjs --check
KEY="$(signing_key)" || {
  echo "No gallery signing key: set GALLERY_SIGNING_KEY, put it in $KEY_FILE, or unlock Vaultwarden (bw)." >&2
  exit 1
}
GALLERY_SIGNING_KEY="$KEY" node gallery/sign.mjs
unset KEY
node gallery/sign.mjs --verify "$PUBLIC_KEY"

read -r -p "Publish casama.ai, docs.casama.ai and gallery.casama.ai now? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
(cd docs-site && npm run build)
# The gallery's item and author pages, share images and sitemap (gitignored; needs `pnpm install`).
node gallery/build-pages.mjs
# casama.ai's written pages, sitemap and llms.txt (docs/SEO-PLAN.md). It stops the deploy on a page
# with no description, a rival fact with no source, or one checked more than 45 days ago.
node site/build.mjs
# What is live now, so only the pages this deploy changes are sent to IndexNow afterwards.
INDEXNOW_BEFORE="$(mktemp)"
node scripts/indexnow.mjs snapshot "$INDEXNOW_BEFORE" || true
(cd site && wrangler deploy)
(cd docs-site && wrangler deploy)
(cd gallery && wrangler deploy)
node scripts/indexnow.mjs submit "$INDEXNOW_BEFORE" || echo "IndexNow didn't answer; the deploy itself is fine."
rm -f "$INDEXNOW_BEFORE"
echo "Published: https://casama.ai, https://docs.casama.ai and https://gallery.casama.ai"
