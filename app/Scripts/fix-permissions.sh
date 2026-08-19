#!/usr/bin/env bash
# One-shot recovery: (re)create the stable signing identity, then rebuild + reinstall so
# the app is stably signed and macOS keeps its permission grants across future rebuilds.
#
# Run this once. Approve any keychain dialog. Then grant Accessibility + Microphone +
# Speech one time (⌥C and ⌥L will prompt). After that, permissions persist.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== 1) signing identity =="
"$DIR/setup-signing.sh" || { echo; echo "Signing setup failed (see above). Fix that first."; exit 1; }

echo
echo "== 2) rebuild + reinstall (stable-signed) =="
"$DIR/bundle.sh"

echo
echo "== 3) launch =="
pkill -f "Seihitsu.app/Contents/MacOS/Seihitsu" 2>/dev/null || true
open "$HOME/Applications/Seihitsu.app"

echo
echo "Done. Now grant Accessibility + Microphone + Speech ONCE:"
echo "  - press ⌥C over some highlighted text  -> allow Accessibility"
echo "  - press ⌥L                              -> allow Microphone + Speech"
echo "Because the identity is now stable, this is the last time you'll be asked."
