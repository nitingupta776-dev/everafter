#!/usr/bin/env bash
set -euo pipefail

optimize_jpeg() {
  local source="$1"
  local output

  TASK_TEMP_DIR="$(mktemp -d /tmp/everafter-ios-jpeg.XXXXXX)"
  output="$TASK_TEMP_DIR/output.jpg"
  trap 'rm -rf "$TASK_TEMP_DIR"' EXIT

  /usr/bin/sips \
    -Z 1280 \
    -s format jpeg \
    -s formatOptions 72 \
    "$source" \
    --out "$output" >/dev/null

  if [[ -s "$output" ]] && \
    [[ "$(stat -f %z "$output")" -lt "$(stat -f %z "$source")" ]]; then
    mv "$output" "$source"
  fi
}

optimize_video() {
  local source="$1"
  local output

  TASK_TEMP_DIR="$(mktemp -d /tmp/everafter-ios-video.XXXXXX)"
  output="$TASK_TEMP_DIR/output.mp4"
  trap 'rm -rf "$TASK_TEMP_DIR"' EXIT

  /usr/bin/avconvert \
    --source "$source" \
    --preset PresetMediumQuality \
    --output "$output" \
    --replace \
    --disableMetadataFilter >/dev/null

  if [[ -s "$output" ]] && \
    [[ "$(stat -f %z "$output")" -lt "$(stat -f %z "$source")" ]]; then
    mv "$output" "$source"
  fi
}

if [[ "${1:-}" == "--jpeg" ]]; then
  optimize_jpeg "$2"
  exit 0
fi

if [[ "${1:-}" == "--video" ]]; then
  optimize_video "$2"
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <Runner.app>" >&2
  exit 64
fi

APP_PATH="$1"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ASSET_ROOT="$APP_PATH/Frameworks/App.framework/flutter_assets/assets"
APP_FRAMEWORK="$APP_PATH/Frameworks/App.framework"

if [[ ! -d "$ASSET_ROOT" ]]; then
  echo "Flutter asset bundle not found: $ASSET_ROOT" >&2
  exit 66
fi

for command_name in avconvert codesign sips; do
  if ! command -v "$command_name" >/dev/null; then
    echo "Required command not found: $command_name" >&2
    exit 69
  fi
done

SIGNING_IDENTITY="$(
  codesign -dvvv "$APP_PATH" 2>&1 | \
    sed -n 's/^Authority=\(Apple Development:.*\)$/\1/p' | \
    head -n 1
)"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Could not read the Apple Development identity from $APP_PATH" >&2
  exit 65
fi

BEFORE_KB="$(du -sk "$APP_PATH" | awk '{print $1}')"

find "$ASSET_ROOT" -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | \
  xargs -0 -P 4 -n 1 "$SCRIPT_PATH" --jpeg

find "$ASSET_ROOT" -type f -iname '*.mp4' -print0 | \
  xargs -0 -P 4 -n 1 "$SCRIPT_PATH" --video

codesign \
  --force \
  --sign "$SIGNING_IDENTITY" \
  --preserve-metadata=identifier,entitlements,requirements,flags \
  --timestamp=none \
  "$APP_FRAMEWORK"

codesign \
  --force \
  --sign "$SIGNING_IDENTITY" \
  --preserve-metadata=identifier,entitlements,requirements,flags \
  --timestamp=none \
  "$APP_PATH"

codesign --verify --deep --strict "$APP_PATH"

AFTER_KB="$(du -sk "$APP_PATH" | awk '{print $1}')"
printf 'Optimized iOS app: %.1f MB -> %.1f MB\n' \
  "$(awk -v value="$BEFORE_KB" 'BEGIN {print value / 1024}')" \
  "$(awk -v value="$AFTER_KB" 'BEGIN {print value / 1024}')"
