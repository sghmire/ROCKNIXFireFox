#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <ROCKNIX-IP-or-hostname>" >&2
  exit 2
fi

TARGET="$1"
REMOTE_DIR="/storage/downloads/rocknix-firefox"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

ssh "root@$TARGET" "mkdir -p '$REMOTE_DIR'"
scp "$SCRIPT_DIR/README.md" \
    "$SCRIPT_DIR/install.sh" \
    "$SCRIPT_DIR/install-controls.sh" \
    "$SCRIPT_DIR/launch.sh" \
    "$SCRIPT_DIR/diagnose.sh" \
    "$SCRIPT_DIR/reset-firefox.sh" \
    "$SCRIPT_DIR/firefox-controller.yaml" \
    "$SCRIPT_DIR/toggle-keyboard.sh" \
    "$SCRIPT_DIR/exit-firefox.sh" \
    "root@$TARGET:$REMOTE_DIR/"
ssh -t "root@$TARGET" "chmod +x '$REMOTE_DIR/install.sh' '$REMOTE_DIR/install-controls.sh' '$REMOTE_DIR/launch.sh' '$REMOTE_DIR/diagnose.sh' '$REMOTE_DIR/reset-firefox.sh' '$REMOTE_DIR/toggle-keyboard.sh' '$REMOTE_DIR/exit-firefox.sh' && '$REMOTE_DIR/install.sh'"
