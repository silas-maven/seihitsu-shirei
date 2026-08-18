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

BUNDLE="$APP_DIR/$APP_NAME.app"
echo "==> assembling $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp "$APP_DIR/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"

echo "==> ad-hoc codesign"
codesign --force --sign - "$BUNDLE"

echo "==> done: $BUNDLE"
echo "    launch with:  open \"$BUNDLE\""
