#!/bin/sh

set -u

APP_ROOT="/storage/apps/firefox-rocknix"
FIREFOX_DIR="$APP_ROOT/firefox"
REPORT="$APP_ROOT/diagnostics.txt"

mkdir -p "$APP_ROOT"

{
  echo "Firefox for ROCKNIX diagnostic report"
  echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date)"
  echo
  echo "== Platform =="
  uname -a
  if [ -r /etc/os-release ]; then
    sed -n '1,20p' /etc/os-release
  fi
  echo
  echo "== libc =="
  if command -v getconf >/dev/null 2>&1; then
    getconf GNU_LIBC_VERSION 2>&1 || true
  fi
  ldd --version 2>&1 | head -n 2 || true
  echo
  echo "== Session =="
  echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<unset>}"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
  echo "DISPLAY=${DISPLAY:-<unset>}"
  echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<unset>}"
  echo "SWAYSOCK=${SWAYSOCK:-<unset>}"
  echo
  echo "== Executables =="
  for command_name in swaymsg firefox ffmpeg pactl wpctl; do
    command -v "$command_name" 2>/dev/null || echo "$command_name: not found"
  done
  echo
  echo "== firefox-bin dependencies =="
  if [ -x "$FIREFOX_DIR/firefox-bin" ]; then
    LD_LIBRARY_PATH="$APP_ROOT/runtime/lib:$FIREFOX_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      ldd "$FIREFOX_DIR/firefox-bin" 2>&1 || true
  else
    echo "$FIREFOX_DIR/firefox-bin: not installed"
  fi
  echo
  echo "== libxul dependencies =="
  if [ -r "$FIREFOX_DIR/libxul.so" ]; then
    LD_LIBRARY_PATH="$APP_ROOT/runtime/lib:$FIREFOX_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      ldd "$FIREFOX_DIR/libxul.so" 2>&1 || true
  else
    echo "$FIREFOX_DIR/libxul.so: not installed"
  fi
  echo
  echo "== Relevant libraries visible through ldconfig =="
  if command -v ldconfig >/dev/null 2>&1; then
    ldconfig -p 2>/dev/null | grep -E 'lib(gtk-3|gdk-3|pango|cairo|glib-2|gio-2|gobject-2|gdk_pixbuf|dbus-1|asound|X11|wayland)' || true
  else
    echo "ldconfig: not found"
  fi
  echo
  echo "== Storage =="
  df -h /storage 2>&1 || true
  echo
  echo "== Firefox version =="
  if [ -r "$FIREFOX_DIR/application.ini" ]; then
    grep -E '^(Name|Version|BuildID)=' "$FIREFOX_DIR/application.ini" || true
  fi
} > "$REPORT" 2>&1

cat "$REPORT"

