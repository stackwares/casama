#!/usr/bin/env bash
# Starts the X server, accessibility bus and window manager, then computerd.
# computerd starts the Neko streamer only while someone is watching (D-054).
set -euo pipefail
export DISPLAY="${DISPLAY:-:1}"
mkdir -p "$HOME/.local/share/xorg"
/usr/lib/xorg/Xorg "$DISPLAY" -config /etc/kasama/xorg.conf -logfile /tmp/xorg.log -noreset -nolisten tcp &
for _ in $(seq 1 100); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.1; done
eval "$(dbus-launch --sh-syntax)"
export NO_AT_BRIDGE=0 GTK_MODULES=gail:atk-bridge
/usr/libexec/at-spi-bus-launcher --launch-immediately >/dev/null 2>&1 &
# A plain background and a taskbar, so an empty desktop doesn't look like a dead screen.
xsetroot -solid '#23303f' || true
openbox >/dev/null 2>&1 &
tint2 >/dev/null 2>&1 &
# The desktop's browser can't send the egress proxy's credentials, so it goes through a local relay
# that adds them (no "proxy requires a username and password" dialog). Restarted if it ever exits.
if [ -n "${AGENT_BROWSER_PROXY_USERNAME:-}" ]; then
  (while true; do node /usr/local/lib/kasama/proxy-relay.mjs >/dev/null 2>&1; sleep 1; done) &
fi
exec computerd
