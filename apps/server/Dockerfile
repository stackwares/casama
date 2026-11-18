# One image, two modes: MODE=api or MODE=worker. Build from the repo root:
#   docker build -f apps/server/Dockerfile -t casama/server:local .
# Node runs the TypeScript sources directly (type stripping); there is no build step.
FROM node:26-slim AS base
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH NODE_ENV=production
RUN npm install -g pnpm@12.18.0 --no-fund --no-audit
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/server/package.json apps/server/
COPY packages/agent/package.json packages/agent/
COPY packages/contracts/package.json packages/contracts/
COPY packages/db/package.json packages/db/
COPY packages/domain/package.json packages/domain/
COPY packages/mcp/package.json packages/mcp/
COPY packages/observability/package.json packages/observability/
COPY packages/sandbox/package.json packages/sandbox/
COPY ee/package.json ee/
RUN pnpm install --frozen-lockfile --prod --filter @casama/server...

# Chinese, Japanese and Korean for the PDFs bots make (D-351): only the two Sans collections
# (about 40 MB); the Debian package also carries Serif, twice that again.
FROM base AS fonts
RUN apt-get update && apt-get install -y --no-install-recommends fonts-noto-cjk && rm -rf /var/lib/apt/lists/*

FROM base AS runtime
# ffmpeg makes the posters chat video cards show (GET /v1/media/{id}/poster).
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
COPY --from=deps /app /app
COPY --from=fonts /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc /usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc /usr/share/fonts/opentype/noto/
COPY packages/agent/src packages/agent/src
COPY packages/contracts/src packages/contracts/src
COPY packages/db/src packages/db/src
COPY packages/domain/src packages/domain/src
COPY packages/mcp/src packages/mcp/src
COPY packages/observability/src packages/observability/src
COPY packages/sandbox/src packages/sandbox/src
COPY ee/server ee/server
COPY ee/LICENSE ee/LICENSE
COPY apps/server/src apps/server/src
# Distributions carry the licenses (AGPL-3.0 in LICENSE, Apache-2.0 for the files LICENSING.md lists)
# and NOTICE.
COPY LICENSE NOTICE LICENSING.md TRADEMARKS.md ./
COPY LICENSES LICENSES
# The support assistant's docs (D-298); it refreshes them from docs.casama.ai/llms-full.txt hourly.
COPY docs-site/*.md docs-site/
COPY docs-site/guide docs-site/guide
COPY docs-site/self-hosting docs-site/self-hosting
COPY docs-site/develop docs-site/develop
# casama.ai explainers the support assistants also answer from (D-401).
COPY site/content site/content
# Built-in apps' marks, served to apps built before a mark was bundled (services/app-logos.ts).
COPY client/assets/apps client/assets/apps
# Migrations, applied by the one-shot `migrate` service in the self-host stack.
COPY supabase/migrations /app/supabase/migrations
# The Library's kept files (D-276), when OBJECT_STORE_DIR points here: a named volume mounted on
# this path takes the folder's owner, so the server can write to it.
RUN mkdir -p /data/library && chown node:node /data/library
# Casama Link (D-296): the tunnel secret the API writes for the connector, on a shared volume.
RUN mkdir -p /link && chown node:node /link && chmod 700 /link
USER node
WORKDIR /app/apps/server
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" || exit 1
CMD ["node", "src/main.ts"]
