# The connector for Casama Link (D-296): cloudflared, pinned, with a small script that starts it
# when the API has written this server's tunnel secret and restarts it when that secret changes.
# The official image has no shell, so only its binary is taken from it. Bump the tag and the digest
# together (the digest is the multi-arch manifest's, from Docker Hub).
FROM cloudflare/cloudflared:2026.10.4@sha256:c6c7ae1d5dfdcb094ad344ed68ccffc26635c9c6be80965664c33baf064b0515 AS cloudflared

FROM alpine:3.22
# The same user id as the API (node, 1000), which owns the shared volume and the secret in it.
RUN apk add --no-cache ca-certificates && adduser -D -u 1000 connector
COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY infra/connector/run-connector.sh /usr/local/bin/run-connector
USER connector
# Healthy once a connection to the edge is up (cloudflared's own readiness answer).
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:2000/ready || exit 1
ENTRYPOINT ["/usr/local/bin/run-connector"]
