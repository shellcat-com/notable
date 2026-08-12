#!/usr/bin/env bash
# Generate (or print) the Sparkle EdDSA public key for Parcel and show how to wire Info.plist.
# Private key stays in the login Keychain under account "parcel.parable.dev".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$ROOT/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys"
ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"

if [[ ! -x "$GEN" ]]; then
  echo "Resolving Sparkle package so generate_keys is available…"
  (cd "$ROOT" && xcodegen generate && xcodebuild -resolvePackageDependencies -project Parcel.xcodeproj -scheme Parcel -derivedDataPath "$ROOT/.derivedData")
fi

if [[ ! -x "$GEN" ]]; then
  echo "generate_keys not found at $GEN" >&2
  exit 1
fi

"$GEN" --account "$ACCOUNT"
echo
echo "Private key is in your Keychain (account: $ACCOUNT)."
echo "Use that same machine (or import via generate_keys -f) when signing appcasts with sign_update."
