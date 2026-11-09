# Sandbox supervisor: the only service with Docker access.
#   docker build -f apps/supervisor/Dockerfile -t kasama/supervisor:dev .
FROM node:24-slim AS base
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH NODE_ENV=production
RUN corepack enable
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/supervisor/package.json apps/supervisor/
COPY packages/sandbox/package.json packages/sandbox/
RUN pnpm install --frozen-lockfile --prod --filter @kasama/supervisor...

FROM base AS runtime
COPY --from=deps /app /app
COPY packages/sandbox/src packages/sandbox/src
COPY apps/supervisor/src apps/supervisor/src
WORKDIR /app/apps/supervisor
EXPOSE 8788
# Runs as root to use the Docker socket; it never executes user code.
CMD ["node", "src/main.ts"]
