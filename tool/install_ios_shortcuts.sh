#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <iphone-udid> [trip-slug]" >&2
  exit 64
fi

DEVICE_ID="$1"
TRIP_SLUG="${2:-japan}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA="$PROJECT_ROOT/build/ios-shortcuts/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Release-iphoneos/Runner.app"

cd "$PROJECT_ROOT"

flutter build ios \
  --release \
  --config-only \
  --dart-define=EVERAFTER_NATIVE_NFC=false

xcodebuild \
  -quiet \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  CODE_SIGN_ENTITLEMENTS=Runner/RunnerShortcuts.entitlements \
  build

"$SCRIPT_DIR/optimize_ios_app.sh" "$APP_PATH"

APP_BUNDLE_ID="$(
  /usr/libexec/PlistBuddy \
    -c 'Print :CFBundleIdentifier' \
    "$APP_PATH/Info.plist"
)"

if [[ -z "$APP_BUNDLE_ID" ]]; then
  echo "Could not read the bundle identifier from $APP_PATH" >&2
  exit 65
fi

if codesign -d --entitlements :- "$APP_PATH" 2>&1 | rg -q \
  'com\.apple\.developer\.nfc'; then
  echo "Refusing to install: the Shortcuts build unexpectedly has an NFC entitlement." >&2
  exit 1
fi

xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  --timeout 1200 \
  "$APP_PATH"

xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --timeout 90 \
  --terminate-existing \
  --payload-url "everafter:///nfc/$TRIP_SLUG" \
  "$APP_BUNDLE_ID"
