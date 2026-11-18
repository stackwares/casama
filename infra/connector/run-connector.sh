#!/bin/sh
# Holds this server's tunnel open (Casama Link, D-296).
#
# The API writes the tunnel's secret to CASAMA_LINK_TOKEN_FILE when remote access is on, replaces it
# when Casama Cloud makes the tunnel again (same address), and removes it when remote access is
# turned off. This waits for the file, runs cloudflared with it, and starts over whenever the file
# changes or cloudflared exits. cloudflared only dials out (TCP and UDP 7844); the metrics port is
# for the API's status check on the internal network and isn't published.
set -u

TOKEN_FILE="${CASAMA_LINK_TOKEN_FILE:-/link/token}"
# CONNECT_METRICS is the name from before the Casama Link rename, still read if a stack sets it.
METRICS="${CASAMA_LINK_METRICS:-${CONNECT_METRICS:-0.0.0.0:2000}}"
child=""

stop() {
  if [ -n "$child" ]; then
    kill -TERM "$child" 2>/dev/null
    wait "$child" 2>/dev/null
  fi
  exit 0
}
trap stop TERM INT

# Sleeps in the background so a stop signal is handled at once.
nap() {
  sleep "$1" &
  wait $!
}

fingerprint() {
  if [ -s "$TOKEN_FILE" ]; then sha256sum "$TOKEN_FILE" | cut -d' ' -f1; else echo none; fi
}

pause=3
while :; do
  if [ ! -s "$TOKEN_FILE" ]; then
    echo "connector: waiting for this server's tunnel secret (remote access is off, or still being set up)"
    while [ ! -s "$TOKEN_FILE" ]; do nap 5; done
    pause=3
  fi
  running=$(fingerprint)
  echo "connector: starting"
  started=$(date +%s)
  cloudflared tunnel --no-autoupdate --metrics "$METRICS" run --token-file "$TOKEN_FILE" &
  child=$!
  changed=0
  while kill -0 "$child" 2>/dev/null; do
    nap 10
    if [ "$(fingerprint)" != "$running" ]; then
      echo "connector: the tunnel secret changed; restarting"
      kill -TERM "$child" 2>/dev/null
      changed=1
      break
    fi
  done
  wait "$child" 2>/dev/null
  child=""
  # A secret the provider refuses makes cloudflared exit at once: wait longer each time (up to a
  # minute) until the API writes a new one, which starts it straight away.
  if [ "$changed" -eq 1 ] || [ $(($(date +%s) - started)) -ge 60 ]; then
    pause=3
  elif [ "$pause" -lt 60 ]; then
    pause=$((pause * 2))
  fi
  waited=0
  while [ "$waited" -lt "$pause" ] && [ "$(fingerprint)" = "$running" ]; do
    nap 3
    waited=$((waited + 3))
  done
done
