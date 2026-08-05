#!/bin/sh

set -eu

APP_ROOT="/storage/apps/firefox-rocknix"
PORT_LAUNCHER="/storage/roms/ports/Firefox.sh"

pkill -f '/storage/apps/firefox-rocknix/firefox' 2>/dev/null || true
killall wvkbd-mobintl 2>/dev/null || true
systemctl restart inputplumber.service 2>/dev/null || true
systemctl restart touchkeyboard.service 2>/dev/null || true

# Remove only the installed application and its Ports entry. The user profile at
# /storage/.mozilla/firefox-rocknix is deliberately preserved.
rm -rf -- "$APP_ROOT"
rm -f -- "$PORT_LAUNCHER"

echo "Firefox application and ROCKNIX integration removed."
echo "Browser data was preserved at /storage/.mozilla/firefox-rocknix."

