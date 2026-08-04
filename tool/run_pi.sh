#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shopt -s nullglob
BINARIES=("$ROOT_DIR"/build/linux/*/release/bundle/everafter)

if (( ${#BINARIES[@]} == 0 )); then
  echo "No native release bundle found. Run tool/build_pi.sh first." >&2
  exit 1
fi

export EVERAFTER_FULLSCREEN="${EVERAFTER_FULLSCREEN:-1}"
export EVERAFTER_NFC_MODE="${EVERAFTER_NFC_MODE:-pn532}"

if [[ -z "${EVERAFTER_NFC_COMMAND:-}" ]]; then
  NFC_PYTHON="${EVERAFTER_NFC_PYTHON:-$HOME/everafter/.venv/bin/python}"
  if [[ -x "$NFC_PYTHON" ]]; then
    export EVERAFTER_NFC_COMMAND="$NFC_PYTHON"
    export EVERAFTER_NFC_ARGS="${EVERAFTER_NFC_ARGS:-$ROOT_DIR/tool/pn532_reader.py}"
  else
    export EVERAFTER_NFC_COMMAND="nfc-poll"
  fi
fi

exec "${BINARIES[0]}"
