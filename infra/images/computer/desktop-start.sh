#!/usr/bin/env bash
# Starts the virtual display, accessibility bus and window manager, then computerd.
set -euo pipefail
export DISPLAY="${DISPLAY:-:1}"
Xvfb "$DISPLAY" -screen 0 "${SCREEN_GEOMETRY:-1280x800x24}" -nolisten tcp &
for _ in $(seq 1 50); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.1; done
eval "$(dbus-launch --sh-syntax)"
export NO_AT_BRIDGE=0 GTK_MODULES=gail:atk-bridge
/usr/libexec/at-spi-bus-launcher --launch-immediately >/dev/null 2>&1 &
openbox >/dev/null 2>&1 &
exec computerd
