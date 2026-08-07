#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH="$(uname -m)"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "EverAfter's Raspberry Pi build requires 64-bit Raspberry Pi OS (aarch64)." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  libgtk-3-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libmpv-dev \
  libnfc-bin \
  libstdc++-12-dev \
  mpv \
  ninja-build \
  pkg-config

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed. Install the current Linux ARM64 stable SDK first." >&2
  exit 1
fi

cd "$ROOT_DIR"
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release

shopt -s nullglob
BUNDLES=("$ROOT_DIR"/build/linux/*/release/bundle)
echo "EverAfter native bundle built at ${BUNDLES[0]}."
