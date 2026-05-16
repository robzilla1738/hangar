#!/usr/bin/env bash
# build-appcast.sh — generate Sparkle 2 appcast for the dist/ DMGs.

set -euo pipefail

# Sparkle's generate_appcast lives in the SPM checkout's binary artifact.
GENERATE=$(find ~/Library/Developer/Xcode/DerivedData -name generate_appcast -type f 2>/dev/null | head -n1)
if [[ -z "$GENERATE" ]]; then
    echo "✗ Could not find Sparkle's generate_appcast binary. Build the app once via xcodebuild first." >&2
    exit 1
fi

KEY="${SPARKLE_PRIVATE_KEY:-$HOME/.config/hangar-secrets/sparkle_ed_private.pem}"
if [[ ! -f "$KEY" ]]; then
    echo "✗ Sparkle private key not found at $KEY" >&2
    echo "  Generate once with: \`$GENERATE\` (will create the keypair on first run)" >&2
    exit 1
fi

echo "→ Generating appcast from dist/"
"$GENERATE" --ed-key-file "$KEY" dist/
echo "✓ Appcast: dist/appcast.xml"
