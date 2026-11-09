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
exec computerd
