# Sandbox supervisor: the only service with Docker access.
#   docker build -f apps/supervisor/Dockerfile -t casama/supervisor:dev .
FROM node:26-slim AS base
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH NODE_ENV=production
RUN npm install -g pnpm@12.18.0 --no-fund --no-audit
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/supervisor/package.json apps/supervisor/
COPY packages/sandbox/package.json packages/sandbox/
COPY packages/observability/package.json packages/observability/
RUN pnpm install --frozen-lockfile --prod --filter @casama/supervisor...

FROM base AS runtime
COPY --from=deps /app /app
COPY packages/sandbox/src packages/sandbox/src
COPY packages/observability/src packages/observability/src
COPY apps/supervisor/src apps/supervisor/src
WORKDIR /app/apps/supervisor
EXPOSE 8788
# Runs as root to use the Docker socket; it never executes user code.
CMD ["node", "src/main.ts"]
