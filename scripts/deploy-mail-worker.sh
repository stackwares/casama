#!/usr/bin/env bash
# Deploys hosted bot mail's door (infra/mail/, BOT-EMAIL-PLAN §5.1, §9.2) to Cloudflare.
# Production: ask Oliver first (AGENTS.md). Needs `wrangler login` on the Stackwares account, the
# mail domain's zone on that account, and the MAIL_HOOK_SECRET secret (wrangler secret put).
# The Email Routing catch-all rule pointing at this Worker is wired separately in Phase 0 and
# stays untouched by this script.
#
#   scripts/deploy-mail-worker.sh --dry-run   check the files and show what would be published
#   scripts/deploy-mail-worker.sh             same, then ask before publishing
#   scripts/deploy-mail-worker.sh --yes       publish without asking
set -euo pipefail
cd "$(dirname "$0")/../infra/mail"

mode=ask
case "${1:-}" in
  --dry-run) mode=dry ;;
  --yes) mode=yes ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run|--yes]" >&2; exit 2 ;;
esac

node --check mail.js
[[ -s wrangler.jsonc ]] || { echo "Missing infra/mail/wrangler.jsonc" >&2; exit 1; }
command -v wrangler >/dev/null || { echo "Needs wrangler (npm i -g wrangler) and wrangler login." >&2; exit 1; }
api=$(sed -n 's/.*"CASAMA_API_URL": *"\([^"]*\)".*/\1/p' wrangler.jsonc)
[[ -n "$api" ]] || { echo "wrangler.jsonc has no CASAMA_API_URL." >&2; exit 1; }
echo "Worker casama-mail → API $api"
wrangler deploy --dry-run --outdir "$(mktemp -d)" >/dev/null
echo "Bundle checks out. Secrets on the Worker (names only):"
wrangler secret list 2>/dev/null || echo "(couldn't list secrets)"

[[ "$mode" == dry ]] && { echo "Dry run: nothing published."; exit 0; }
if [[ "$mode" == ask ]]; then
  read -r -p "Publish infra/mail to Cloudflare now? [y/N] " ok
  [[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "Cancelled."; exit 1; }
fi

wrangler deploy
