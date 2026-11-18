# TURN relay for live view (coturn with Casama's relay-only policy).
FROM coturn/coturn:4.7.0
# socat passes a bot's computer on to the relay outside when someone watches from away (Casama
# Connect, D-296; see start-turn.sh). It does nothing unless TURN_FORWARD=on.
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends socat \
  && rm -rf /var/lib/apt/lists/*
COPY infra/turn/start-turn.sh /usr/local/bin/start-turn
COPY infra/turn/udp-forward.pl /usr/local/bin/udp-forward
USER nobody:nogroup
ENTRYPOINT ["/usr/local/bin/start-turn"]
