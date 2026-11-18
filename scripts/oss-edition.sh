#!/usr/bin/env bash
# Writes the open-source edition of Casama (D-339): this commit without ee/, the folder under the
# Casama Enterprise License. What's left is all open source (AGPL-3.0 and Apache-2.0, D-403).
# See LICENSING.md.
#
# It never touches this checkout: it exports HEAD (committed files only) into <dir> and edits that.
#
#   scripts/oss-edition.sh <dir>            write the open-source edition into <dir> (must not exist)
#   scripts/oss-edition.sh <dir> --check    also install it and run the server's edition checks
#
# CI runs it with --check, so the open-source edition keeps working on every commit.
set -euo pipefail

OUT=${1:?usage: scripts/oss-edition.sh <dir> [--check]}
CHECK=${2:-}
ROOT=$(cd "$(dirname "$0")/.." && pwd)

[ -e "$OUT" ] && { echo "$OUT already exists" >&2; exit 1; }
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)

git -C "$ROOT" archive HEAD | tar -x -C "$OUT"
cd "$OUT"

rm -rf ee
# The tests of ee/ itself go with it.
rm -f apps/server/test/enterprise.test.ts apps/server/test/audit-forwarding.test.ts
# The workspace entry, the server's dependency on it, and the image's copies of it.
sed -i.bak '/^  - ee$/d' pnpm-workspace.yaml
sed -i.bak '/"@casama\/ee": "workspace:\*",/d' apps/server/package.json
sed -i.bak '/^COPY ee\//d' apps/server/Dockerfile
rm -f pnpm-workspace.yaml.bak apps/server/package.json.bak apps/server/Dockerfile.bak

# Nothing else may load ee/ at runtime: only apps/server/src/ee.ts imports it, and it falls back.
# Tests may name it.
LEFT=$(grep -rln --include='*.ts' --include='*.mts' --include='*.json' '@casama/ee' \
  apps packages 2>/dev/null | grep -v -e node_modules -e '/test/' | grep -v '^apps/server/src/ee.ts$' || true)
if [ -n "$LEFT" ]; then
  echo "These files still use @casama/ee; load it through apps/server/src/ee.ts instead:" >&2
  echo "$LEFT" >&2
  exit 1
fi
echo "Open-source edition written to $OUT"

[ "$CHECK" = "--check" ] || exit 0

pnpm install --no-frozen-lockfile --silent
# The server's whole module graph loads, and it reports the open-source edition.
node --input-type=module -e '
  const { edition } = await import("./apps/server/src/ee.ts");
  await import("./apps/server/src/api/app.ts");
  if (edition !== "oss") { console.error("edition is", edition); process.exit(1); }
  console.log("API loads without ee/: edition", edition);
'
# The edition test, and the admin status page that names the edition.
CASAMA_EDITION=oss pnpm --filter @casama/server exec vitest run test/oss-edition.test.ts test/admin.test.ts
