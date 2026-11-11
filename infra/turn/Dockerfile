# TURN relay for live view (coturn with Casama's relay-only policy).
FROM coturn/coturn:4.7.0
COPY infra/turn/start-turn.sh /usr/local/bin/start-turn
ENTRYPOINT ["/usr/local/bin/start-turn"]
