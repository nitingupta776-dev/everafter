#!/usr/bin/env python3
"""Stream PN532 I2C tag UIDs in the format consumed by EverAfter."""

from __future__ import annotations

import time

import board
import busio
from adafruit_pn532.i2c import PN532_I2C


def main() -> None:
    i2c = busio.I2C(board.SCL, board.SDA)
    pn532 = PN532_I2C(i2c, debug=False)
    pn532.SAM_configuration()

    active_uid: str | None = None
    last_seen = 0.0

    while True:
        uid = pn532.read_passive_target(timeout=0.5)
        now = time.monotonic()
        if uid is None:
            if active_uid is not None and now - last_seen > 1.0:
                active_uid = None
            continue

        canonical_uid = ":".join(f"{byte:02X}" for byte in uid)
        if canonical_uid != active_uid:
            print(
                f"UID (NFCID1): {' '.join(f'{byte:02X}' for byte in uid)}",
                flush=True,
            )
            active_uid = canonical_uid
        last_seen = now


if __name__ == "__main__":
    main()
