#!/bin/sh
# Starts coturn for live view (D-055). It listens on every interface (computer networks are
# attached after start under the alias "turn") and relays only between its own allocations:
# every peer address except its relay address is refused, so it can never be used to reach
# other hosts, private networks or metadata services.
set -eu
: "${TURN_SECRET:?TURN_SECRET is required}"
RELAY_IP="${TURN_RELAY_IP:-$(hostname -i | cut -d' ' -f1)}"
exec turnserver -n --log-file=stdout --no-cli --no-tls --no-dtls --fingerprint \
  --listening-ip=0.0.0.0 --listening-port="${TURN_PORT:-3478}" \
  --relay-ip="$RELAY_IP" --min-port="${TURN_MIN_PORT:-49160}" --max-port="${TURN_MAX_PORT:-49260}" \
  --realm="${TURN_REALM:-kasama}" --use-auth-secret --static-auth-secret="$TURN_SECRET" \
  --no-multicast-peers \
  --denied-peer-ip=0.0.0.0-255.255.255.255 --allowed-peer-ip="$RELAY_IP" \
  --user-quota=12 --total-quota=1200 --stale-nonce=600
