#!/bin/sh

set -eu

APP_ROOT="/storage/apps/firefox-rocknix"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ ! -x "$APP_ROOT/firefox/firefox" ]; then
  echo "ERROR: Firefox is not installed at $APP_ROOT/firefox." >&2
  echo "Run install.sh first." >&2
  exit 1
fi

cp "$SCRIPT_DIR/launch.sh" "$APP_ROOT/launch.sh"
cp "$SCRIPT_DIR/firefox-controller.yaml" "$APP_ROOT/firefox-controller.yaml"
cp "$SCRIPT_DIR/toggle-keyboard.sh" "$APP_ROOT/toggle-keyboard.sh"
cp "$SCRIPT_DIR/exit-firefox.sh" "$APP_ROOT/exit-firefox.sh"
chmod +x "$APP_ROOT/launch.sh" "$APP_ROOT/toggle-keyboard.sh" "$APP_ROOT/exit-firefox.sh"

echo "Firefox controller integration v6 installed."
echo "Close any running Firefox process, then launch Firefox again."
