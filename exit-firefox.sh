#!/bin/sh

PID_FILE="/storage/apps/firefox-rocknix/firefox.pid"
[ -r "$PID_FILE" ] || exit 1

FIREFOX_PID=$(sed -n '1p' "$PID_FILE")
case "$FIREFOX_PID" in
  ''|*[!0-9]*) exit 1 ;;
esac

kill -TERM "$FIREFOX_PID" 2>/dev/null || true

