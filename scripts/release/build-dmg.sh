#!/usr/bin/env bash
# build-dmg.sh — create a signed/notarized DMG containing Hangar.app.

set -euo pipefail

APP="${APP:-build/export/Hangar.app}"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
DMG="dist/Hangar-${VERSION}.dmg"
VOLNAME="Hangar ${VERSION}"
IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Robert Courson (9F2JXY8TCK)}"

mkdir -p dist

echo "→ Building DMG"
create-dmg \
    --volname "$VOLNAME" \
    --window-pos 200 120 \
    --window-size 760 400 \
    --icon-size 96 \
    --icon "Hangar.app" 180 170 \
    --app-drop-link 540 170 \
    --no-internet-enable \
    "$DMG" \
    "$APP" || true

if [[ ! -f "$DMG" ]]; then
    echo "✗ DMG not produced. create-dmg sometimes returns non-zero on retina-image warnings; check dist/" >&2
    exit 1
fi

echo "→ Codesigning DMG"
codesign --sign "$IDENTITY" --options runtime --timestamp "$DMG"

echo "→ SHA-256"
SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
echo "$SHA" > "$DMG.sha256"
echo "✓ DMG: $DMG"
echo "  SHA-256: $SHA"
