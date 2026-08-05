#!/bin/sh

WVKBD_PIDS=$(pidof wvkbd-mobintl 2>/dev/null || true)
if [ -z "$WVKBD_PIDS" ]; then
  exit 1
fi

# SIGRTMIN is signal 34 on Linux and toggles wvkbd visibility.
kill -34 $WVKBD_PIDS

