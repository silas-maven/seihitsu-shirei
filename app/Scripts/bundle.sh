#!/usr/bin/env bash
# Assemble Seihitsu.app from the SwiftPM build output and ad-hoc codesign it.
# Usage: Scripts/bundle.sh [debug|release]   (default: debug)
set -euo pipefail

APP_NAME="Seihitsu"
CONFIG="${1:-debug}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # the app/ directory

echo "==> swift build ($CONFIG)"
swift build --package-path "$APP_DIR" -c "$CONFIG"

BIN_DIR="$(swift build --package-path "$APP_DIR" -c "$CONFIG" --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"
[ -x "$BIN" ] || { echo "error: built binary not found at $BIN" >&2; exit 1; }

# Regenerate AppIcon.icns from AppIcon-source.png when the source changes.
# To use your own icon: replace Resources/AppIcon-source.png with a square PNG (1024+; 2048
# ideal), then rerun this script. Bake in the rounded-square shape for the macOS look.
SRC_PNG="$APP_DIR/Resources/AppIcon-source.png"
ICNS="$APP_DIR/Resources/AppIcon.icns"
if [ -f "$SRC_PNG" ] && { [ ! -f "$ICNS" ] || [ "$SRC_PNG" -nt "$ICNS" ]; }; then
  echo "==> regenerating AppIcon.icns from AppIcon-source.png"
  ISET="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$ISET"
  for sz in 16 32 128 256 512; do
    sips -z "$sz" "$sz" "$SRC_PNG" --out "$ISET/icon_${sz}x${sz}.png" >/dev/null 2>&1
    d=$((sz * 2)); sips -z "$d" "$d" "$SRC_PNG" --out "$ISET/icon_${sz}x${sz}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$ISET" -o "$ICNS"
fi

BUNDLE="$APP_DIR/$APP_NAME.app"
echo "==> assembling $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp "$APP_DIR/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
[ -f "$APP_DIR/Resources/AppIcon.icns" ] && cp "$APP_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> codesign"
SIGN_IDENTITY="Seihitsu Self-Signed"
# No -v: codesign can use the identity even before it is marked trusted.
if security find-identity -p codesigning 2>/dev/null | grep -q "$SIGN_IDENTITY"; then
  echo "    stable identity: $SIGN_IDENTITY (TCC permission grants persist across rebuilds)"
  codesign --force --sign "$SIGN_IDENTITY" "$BUNDLE"
else
  echo "    ad-hoc (run Scripts/setup-signing.sh once so permissions stop resetting on rebuild)"
  codesign --force --sign - "$BUNDLE"
fi

# Install to ~/Applications so it is stable and Spotlight-searchable as "Seihitsu".
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$BUNDLE" "$INSTALL_DIR/$APP_NAME.app"

echo "==> done."
echo "    built:     $BUNDLE"
echo "    installed: $INSTALL_DIR/$APP_NAME.app  (search Spotlight for 'Seihitsu')"
