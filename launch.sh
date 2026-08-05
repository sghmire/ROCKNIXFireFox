#!/bin/sh

. /etc/profile

APP_ROOT="/storage/apps/firefox-rocknix"
FIREFOX_DIR="$APP_ROOT/firefox"
PROFILE_DIR="/storage/.mozilla/firefox-rocknix"
CONTROLLER_PROFILE="$APP_ROOT/firefox-controller.yaml"
KEYBOARD_TOGGLE="$APP_ROOT/toggle-keyboard.sh"
FIREFOX_EXIT="$APP_ROOT/exit-firefox.sh"
PID_FILE="$APP_ROOT/firefox.pid"
FIREFOX_WORKSPACE="98:firefox"
LOG_DIR="$APP_ROOT/logs"
LOG_FILE="$LOG_DIR/firefox.log"
INPUTPLUMBER_SERVICE="org.shadowblip.InputPlumber"
INPUTPLUMBER_INTERFACE="org.shadowblip.Input.CompositeDevice"
COMPOSITE_PATH=""
FIREFOX_PID=""
WVKBD_PID=""
TOUCHKB_WAS_ACTIVE=0
CONTROLLER_PROFILE_LOADED=0
CLEANED_UP=0
PRIOR_WORKSPACE=""
WVKBD_OUT=""

if [ ! -x "$FIREFOX_DIR/firefox" ]; then
  echo "Firefox is not installed. Run the install.sh script first." >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR" "$LOG_DIR" /storage/.cache /storage/.config /storage/.local/share

export HOME="/storage"
export XDG_CACHE_HOME="/storage/.cache"
export XDG_CONFIG_HOME="/storage/.config"
export XDG_DATA_HOME="/storage/.local/share"
export MOZ_ENABLE_WAYLAND="1"
export MOZ_LOG_FILE="$LOG_FILE"
export LD_LIBRARY_PATH="$APP_ROOT/runtime/lib:$FIREFOX_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$FIREFOX_DIR" || exit 1

find_composite_device() {
  if ! command -v busctl >/dev/null 2>&1; then
    return 1
  fi

  # The Flip 2 has one managed composite controller. ROCKNIX exposes it at
  # this stable DBus path; the older busctl build on ROCKNIX does not support
  # the `tree --list` output mode previously used for discovery.
  COMPOSITE_PATH="/org/shadowblip/InputPlumber/CompositeDevice0"
  busctl introspect "$INPUTPLUMBER_SERVICE" "$COMPOSITE_PATH" \
    "$INPUTPLUMBER_INTERFACE" >/dev/null 2>&1
}

load_controller_profile() {
  if [ -r "$CONTROLLER_PROFILE" ] && find_composite_device; then
    if busctl call "$INPUTPLUMBER_SERVICE" "$COMPOSITE_PATH" \
      "$INPUTPLUMBER_INTERFACE" LoadProfilePath s "$CONTROLLER_PROFILE" \
      >> "$LOG_FILE" 2>&1; then
      CONTROLLER_PROFILE_LOADED=1
    fi
  fi
}

restore_controller_profile() {
  if [ "$CONTROLLER_PROFILE_LOADED" = "1" ]; then
    # Reloading the service is more reliable than loading the default profile:
    # it recreates the Retroid's original ds5 + keyboard target devices.
    systemctl restart inputplumber.service >> "$LOG_FILE" 2>&1 || true
  fi
}

start_onscreen_keyboard() {
  if [ ! -x /usr/bin/wvkbd-mobintl ]; then
    echo "wvkbd-mobintl not found; onscreen keyboard disabled" >> "$LOG_FILE"
    return
  fi

  if systemctl is-active --quiet touchkeyboard.service; then
    TOUCHKB_WAS_ACTIVE=1
    systemctl stop touchkeyboard.service >> "$LOG_FILE" 2>&1 || true
  fi
  killall wvkbd-mobintl >/dev/null 2>&1 || true
  sleep 1

  if command -v jq >/dev/null 2>&1; then
    WVKBD_OUT=$(swaymsg -t get_outputs -r 2>/dev/null \
      | jq -r '.[] | select(.focused == true) | .name' | head -n 1)
  fi
  echo "wvkbd output: ${WVKBD_OUT:-automatic}" >> "$LOG_FILE"

  if [ -n "$WVKBD_OUT" ]; then
    /usr/bin/wvkbd-mobintl \
      -H 380 -L 380 \
      -fg 6b6b75 -fg-sp 6b6b75 -bg 1d1d1d \
      --text ffffff --text-sp ffffff \
      -press 000000 --press-sp 000000 \
      -fn 32 -l full,nav,special \
      --landscape-layers full,nav,special \
      --hidden --output "$WVKBD_OUT" >> "$LOG_FILE" 2>&1 &
  else
    /usr/bin/wvkbd-mobintl \
      -H 380 -L 380 \
      -fg 6b6b75 -fg-sp 6b6b75 -bg 1d1d1d \
      --text ffffff --text-sp ffffff \
      -press 000000 --press-sp 000000 \
      -fn 32 -l full,nav,special \
      --landscape-layers full,nav,special \
      --hidden >> "$LOG_FILE" 2>&1 &
  fi
  WVKBD_PID=$!

  # InputPlumber maps Y to F12 while Firefox is running. Use a common function
  # key because this ROCKNIX Sway build does not reliably handle F23/F24.
  swaymsg "bindsym --locked F12 exec $KEYBOARD_TOGGLE" >> "$LOG_FILE" 2>&1 || true
  swaymsg "bindsym --locked F9 exec $FIREFOX_EXIT" >> "$LOG_FILE" 2>&1 || true
}

cleanup() {
  if [ "$CLEANED_UP" = "1" ]; then
    return
  fi
  CLEANED_UP=1

  swaymsg 'unbindsym F12' >/dev/null 2>&1 || true
  swaymsg 'unbindsym F9' >/dev/null 2>&1 || true
  rm -f "$PID_FILE"
  if [ -n "$WVKBD_PID" ]; then
    kill "$WVKBD_PID" 2>/dev/null || true
    wait "$WVKBD_PID" 2>/dev/null || true
  fi
  killall wvkbd-mobintl >/dev/null 2>&1 || true
  if [ "$TOUCHKB_WAS_ACTIVE" = "1" ]; then
    systemctl start touchkeyboard.service >> "$LOG_FILE" 2>&1 || true
  fi

  restore_controller_profile
  if command -v set_kill >/dev/null 2>&1; then
    set_kill stop
  fi
  if [ -n "$PRIOR_WORKSPACE" ]; then
    swaymsg "workspace $PRIOR_WORKSPACE" >/dev/null 2>&1 || true
  fi
}

stop_firefox() {
  if [ -n "$FIREFOX_PID" ]; then
    kill "$FIREFOX_PID" 2>/dev/null || true
  fi
  exit 130
}

trap cleanup EXIT
trap stop_firefox INT TERM HUP

{
  echo
  echo "===== Firefox launch $(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date) ====="
  echo "Integration version: v6"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
  echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<unset>}"
} >> "$LOG_FILE"

if command -v set_kill >/dev/null 2>&1; then
  # ROCKNIX's standard global exit chord is L1 + Select + Start.
  set_kill set "firefox firefox-bin"
fi

load_controller_profile
start_onscreen_keyboard

# A true fullscreen Sway container covers the layer-shell keyboard. Give
# Firefox its own tiled workspace instead: it still fills the available screen,
# but moves upward when wvkbd reserves space at the bottom.
if command -v jq >/dev/null 2>&1; then
  PRIOR_WORKSPACE=$(swaymsg -t get_workspaces -r 2>/dev/null \
    | jq -r '.[] | select(.focused == true) | .name' | head -n 1)
fi
swaymsg "workspace $FIREFOX_WORKSPACE" >> "$LOG_FILE" 2>&1 || true

"$FIREFOX_DIR/firefox" --no-remote --profile "$PROFILE_DIR" "$@" >> "$LOG_FILE" 2>&1 &
FIREFOX_PID=$!
echo "$FIREFOX_PID" > "$PID_FILE"

# Focus Firefox as soon as its native Wayland window appears. Keep Sway
# fullscreen disabled so its onscreen-keyboard layer remains visible.
attempt=0
while [ "$attempt" -lt 15 ] && kill -0 "$FIREFOX_PID" 2>/dev/null; do
  if swaymsg -t get_tree 2>/dev/null | grep -q '"app_id": "firefox"'; then
    swaymsg "[app_id=\"firefox\"] move container to workspace $FIREFOX_WORKSPACE" >/dev/null 2>&1 || true
    swaymsg "workspace $FIREFOX_WORKSPACE" >/dev/null 2>&1 || true
    swaymsg '[app_id="firefox"] focus' >/dev/null 2>&1 || true
    swaymsg '[app_id="firefox"] fullscreen disable' >/dev/null 2>&1 || true
    break
  fi
  attempt=$((attempt + 1))
  sleep 1
done

wait "$FIREFOX_PID"
