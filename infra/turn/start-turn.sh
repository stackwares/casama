#!/bin/sh
# Starts coturn for live view (D-055). It listens on every interface (computer networks are
# attached after start under the alias "turn") and relays only between its own allocations:
# every peer address except its relay address is refused, so it can never be used to reach
# other hosts, private networks or metadata services.
set -eu
: "${TURN_SECRET:?TURN_SECRET is required}"
RELAY_IP="${TURN_RELAY_IP:-$(hostname -i | cut -d' ' -f1)}"

# Casama Link (D-296): someone watching from away can't reach this relay, so live view then
# goes through a relay outside, at Casama Cloud. A bot's computer has no route to the internet
# for that. It already reaches this container as "turn", so with TURN_FORWARD=on this container
# passes one more port on to that one relay and nowhere else. The relay asks for credentials,
# which the server gets from Casama Cloud; nothing here holds any.
if [ "${TURN_FORWARD:-off}" = "on" ]; then
  FORWARD_TO="${TURN_FORWARD_TO:-turn.cloudflare.com:3478}"
  FORWARD_PORT="${TURN_FORWARD_PORT:-3479}"
  # Exactly host:port, so nothing else can be slipped into the forwarder's arguments.
  case "$FORWARD_TO" in
    *[!A-Za-z0-9.:-]* | *:*:* | :* | *:*[!0-9]* | *:) FORWARD_OK=no ;;
    *:*) FORWARD_OK=yes ;;
    *) FORWARD_OK=no ;;
  esac
  if [ "$FORWARD_OK" != yes ]; then
    echo "TURN_FORWARD_TO must be host:port, got: $FORWARD_TO" >&2
    exit 1
  fi
  case "$FORWARD_PORT" in
    *[!0-9]* | "")
      echo "TURN_FORWARD_PORT must be a port number, got: $FORWARD_PORT" >&2
      exit 1
      ;;
  esac
  echo "forwarding port $FORWARD_PORT to $FORWARD_TO for live view away from this server"
  # One loop each for UDP and TCP; a forwarder that stops (the network went away) starts again.
  # UDP keeps one outbound socket per client (udp-forward.pl says why); TCP connections are
  # separate anyway, so socat forks one per connection.
  (while :; do
    perl /usr/local/bin/udp-forward "$FORWARD_PORT" "$FORWARD_TO" || true
    sleep 2
  done) &
  (while :; do
    socat "TCP4-LISTEN:$FORWARD_PORT,fork,reuseaddr,nodelay" "TCP4:$FORWARD_TO,nodelay" || true
    sleep 2
  done) &
fi

exec turnserver -n --log-file=stdout --no-cli --no-tls --no-dtls --fingerprint \
  --listening-ip=0.0.0.0 --listening-port="${TURN_PORT:-3478}" \
  --relay-ip="$RELAY_IP" --min-port="${TURN_MIN_PORT:-49160}" --max-port="${TURN_MAX_PORT:-49260}" \
  --realm="${TURN_REALM:-casama}" --use-auth-secret --static-auth-secret="$TURN_SECRET" \
  --no-multicast-peers \
  --denied-peer-ip=0.0.0.0-255.255.255.255 --allowed-peer-ip="$RELAY_IP" \
  --user-quota=12 --total-quota=1200 --stale-nonce=600
