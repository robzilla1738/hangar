#!/usr/bin/env bash
# import-cert.sh — import Developer ID certificate into a temporary keychain
# for use by the release workflow on macos-* runners.

set -euo pipefail

: "${APPLE_DEVELOPER_ID_CERT_P12_BASE64:?must be set}"
: "${APPLE_DEVELOPER_ID_CERT_PASSWORD:?must be set}"
: "${KEYCHAIN_PASSWORD:?must be set}"

KEYCHAIN_PATH="$RUNNER_TEMP/hangar-build.keychain-db"

echo "→ Decoding cert"
echo "$APPLE_DEVELOPER_ID_CERT_P12_BASE64" | base64 --decode > "$RUNNER_TEMP/cert.p12"

echo "→ Creating temporary keychain"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

echo "→ Importing cert"
security import "$RUNNER_TEMP/cert.p12" \
    -P "$APPLE_DEVELOPER_ID_CERT_PASSWORD" \
    -A -t cert -f pkcs12 \
    -k "$KEYCHAIN_PATH"

security set-key-partition-list -S apple-tool:,apple: \
    -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | tr -d '"')
security default-keychain -s "$KEYCHAIN_PATH"
echo "✓ Cert imported into $KEYCHAIN_PATH"
