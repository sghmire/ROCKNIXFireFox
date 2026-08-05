#!/bin/sh

set -eu

APP_ROOT="/storage/apps/firefox-rocknix"
FIREFOX_DIR="$APP_ROOT/firefox"
NEW_DIR="$APP_ROOT/firefox.new"
PREVIOUS_DIR="$APP_ROOT/firefox.previous"
PORTS_DIR="/storage/roms/ports"
DOWNLOAD_URL="${FIREFOX_DOWNLOAD_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64-aarch64&lang=en-US}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORK_DIR=$(mktemp -d /storage/firefox-install.XXXXXX)
ARCHIVE="$WORK_DIR/firefox.tar.xz"
EXTRACT_DIR="$WORK_DIR/extracted"

cleanup() {
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT INT TERM

case "$(uname -m)" in
  aarch64|arm64)
    ;;
  *)
    echo "ERROR: This package requires ARM64/aarch64; found $(uname -m)." >&2
    exit 1
    ;;
esac

mkdir -p "$APP_ROOT" "$APP_ROOT/runtime/lib" "$APP_ROOT/logs" "$PORTS_DIR" "$EXTRACT_DIR"

echo "Downloading Mozilla Firefox for Linux ARM64..."
if command -v curl >/dev/null 2>&1; then
  curl -L --fail --retry 3 -o "$ARCHIVE" "$DOWNLOAD_URL"
elif [ -x /opt/bin/curl ]; then
  /opt/bin/curl -L --fail --retry 3 -o "$ARCHIVE" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$ARCHIVE" "$DOWNLOAD_URL"
elif [ -x /opt/bin/wget ]; then
  /opt/bin/wget -O "$ARCHIVE" "$DOWNLOAD_URL"
else
  echo "ERROR: curl or wget is required." >&2
  exit 1
fi

echo "Extracting archive..."
if ! tar -xJf "$ARCHIVE" -C "$EXTRACT_DIR"; then
  echo "ERROR: The installed tar cannot extract xz archives." >&2
  echo "Install the Entware tar and xz packages, then retry." >&2
  exit 1
fi

if [ ! -x "$EXTRACT_DIR/firefox/firefox-bin" ]; then
  echo "ERROR: Mozilla archive did not contain firefox/firefox-bin." >&2
  exit 1
fi

rm -rf -- "$NEW_DIR"
mv "$EXTRACT_DIR/firefox" "$NEW_DIR"

if [ -e "$PREVIOUS_DIR" ]; then
  rm -rf -- "$PREVIOUS_DIR"
fi
if [ -e "$FIREFOX_DIR" ]; then
  mv "$FIREFOX_DIR" "$PREVIOUS_DIR"
fi
mv "$NEW_DIR" "$FIREFOX_DIR"

cp "$SCRIPT_DIR/launch.sh" "$APP_ROOT/launch.sh"
cp "$SCRIPT_DIR/diagnose.sh" "$APP_ROOT/diagnose.sh"
cp "$SCRIPT_DIR/firefox-controller.yaml" "$APP_ROOT/firefox-controller.yaml"
cp "$SCRIPT_DIR/toggle-keyboard.sh" "$APP_ROOT/toggle-keyboard.sh"
cp "$SCRIPT_DIR/exit-firefox.sh" "$APP_ROOT/exit-firefox.sh"
chmod +x "$APP_ROOT/launch.sh" "$APP_ROOT/diagnose.sh" "$APP_ROOT/toggle-keyboard.sh" "$APP_ROOT/exit-firefox.sh"

cat > "$PORTS_DIR/Firefox.sh" <<'EOF'
#!/bin/sh
exec /storage/apps/firefox-rocknix/launch.sh "$@"
EOF
chmod +x "$PORTS_DIR/Firefox.sh"

"$APP_ROOT/diagnose.sh" || true

VERSION=$(sed -n 's/^Version=//p' "$FIREFOX_DIR/application.ini" | head -n 1)
echo
echo "Firefox ${VERSION:-unknown} installed at $FIREFOX_DIR"
echo "Dependency report: $APP_ROOT/diagnostics.txt"
echo
if grep -q '=> not found' "$APP_ROOT/diagnostics.txt"; then
  echo "Some runtime libraries are missing. Paste diagnostics.txt into the conversation"
  echo "so the compatible GTK bundle can be prepared."
else
  echo "No linked libraries are missing. Try: $APP_ROOT/launch.sh"
fi
