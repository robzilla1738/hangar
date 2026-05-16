#!/usr/bin/env bash
# build-release.sh — universal Release build of Hangar.app.
# Run from repo root.

set -euo pipefail

SCHEME="${SCHEME:-Hangar}"
CONFIG="${CONFIG:-Release}"
ARCHIVE="${ARCHIVE:-build/Hangar.xcarchive}"
EXPORT_DIR="${EXPORT_DIR:-build/export}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-scripts/release/ExportOptions.plist}"

mkdir -p "$(dirname "$ARCHIVE")" "$EXPORT_DIR"

echo "→ Generating Xcode project (idempotent)"
xcodegen generate

echo "→ Resolving SwiftPM dependencies"
xcodebuild \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -resolvePackageDependencies | xcbeautify

echo "→ Archiving universal binary (arm64 + x86_64)"
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -archivePath "$ARCHIVE" \
    -destination 'generic/platform=macOS' \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO | xcbeautify

echo "→ Exporting .app"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" | xcbeautify

APP="$EXPORT_DIR/Hangar.app"
echo "→ Verifying universal binary"
lipo -info "$APP/Contents/MacOS/Hangar"

echo "→ Verifying codesign"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "✓ Done: $APP"
