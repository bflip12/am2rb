#!/usr/bin/env bash
# Draws the app icon and writes Resources/AppIcon.icns, plus docs/assets/icon.png for the README.
# Usage: scripts/make-icon.sh   (run it after changing scripts/make-icon.swift, and commit both outputs)
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
swift scripts/make-icon.swift "$TMP/AppIcon.iconset"
iconutil -c icns -o Resources/AppIcon.icns "$TMP/AppIcon.iconset"
mkdir -p docs/assets
cp "$TMP/AppIcon.iconset/icon_256x256@2x.png" docs/assets/icon.png
echo "Wrote Resources/AppIcon.icns and docs/assets/icon.png"
