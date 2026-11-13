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

FROM base AS runtime
# ffmpeg makes the posters chat video cards show (GET /v1/media/{id}/poster).
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
COPY --from=deps /app /app
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
# Migrations, applied by the one-shot `migrate` service in the self-host stack.
COPY supabase/migrations /app/supabase/migrations
# The Library's kept files (D-276), when OBJECT_STORE_DIR points here: a named volume mounted on
# this path takes the folder's owner, so the server can write to it.
RUN mkdir -p /data/library && chown node:node /data/library
USER node
WORKDIR /app/apps/server
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" || exit 1
CMD ["node", "src/main.ts"]
