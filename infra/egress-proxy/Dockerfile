# Egress proxy: the only route out of computer networks. No dependencies beyond Node.js.
#   docker build -f infra/egress-proxy/Dockerfile -t kasama/egress-proxy:dev .
FROM node:24-slim
WORKDIR /app
COPY infra/egress-proxy/src ./src
USER node
EXPOSE 3128 3129
CMD ["node", "src/main.ts"]
