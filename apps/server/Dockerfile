# One image, two modes: MODE=api or MODE=worker. Build from the repo root:
#   docker build -f apps/server/Dockerfile -t ghcr.io/kasama-dev/server .
FROM node:24-slim AS base
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH NODE_ENV=production
RUN corepack enable
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/server/package.json apps/server/
COPY packages/contracts/package.json packages/contracts/
COPY packages/db/package.json packages/db/
COPY packages/domain/package.json packages/domain/
COPY packages/observability/package.json packages/observability/
RUN pnpm install --frozen-lockfile --prod --filter @kasama/server...

FROM base AS runtime
COPY --from=deps /app /app
COPY packages/contracts/src packages/contracts/src
COPY packages/db/src packages/db/src
COPY packages/domain/src packages/domain/src
COPY packages/observability/src packages/observability/src
COPY apps/server/src apps/server/src
USER node
WORKDIR /app/apps/server
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" || exit 1
CMD ["node", "src/main.ts"]
