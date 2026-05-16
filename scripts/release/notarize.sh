#!/usr/bin/env bash
# notarize.sh — submit Hangar.app to Apple notary service and staple.
#
# Prerequisites:
#   xcrun notarytool store-credentials AC_PASSWORD \
#       --apple-id "$APPLE_ID" \
#       --team-id 9F2JXY8TCK \
#       --password "<app-specific-password from appleid.apple.com>"

set -euo pipefail

APP="${APP:-build/export/Hangar.app}"
PROFILE="${NOTARY_PROFILE:-AC_PASSWORD}"
ZIP="build/Hangar.zip"

if [[ ! -d "$APP" ]]; then
    echo "✗ App bundle not found at $APP" >&2
    exit 1
fi

echo "→ Zipping for notarization"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "→ Submitting to notary service (may take 1-5 minutes)"
xcrun notarytool submit "$ZIP" \
    --keychain-profile "$PROFILE" \
    --wait \
    --output-format json | tee build/notarytool-output.json

STATUS=$(python3 -c "import json,sys; print(json.load(open('build/notarytool-output.json')).get('status',''))")
if [[ "$STATUS" != "Accepted" ]]; then
    echo "✗ Notarization not accepted: status=$STATUS"
    exit 1
fi

echo "→ Stapling ticket"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "✓ Notarized + stapled: $APP"
