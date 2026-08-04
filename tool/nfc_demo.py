#!/usr/bin/env python3
"""Continuously read NFC tags with the PN532 and print their information."""

from __future__ import annotations

import board
import busio
from adafruit_pn532.i2c import PN532_I2C


def main() -> None:
    i2c = busio.I2C(board.SCL, board.SDA)
    pn532 = PN532_I2C(i2c, debug=False)

    firmware = pn532.firmware_version
    pn532.SAM_configuration()

    print(
        f"PN532 ready (firmware {firmware[1]}.{firmware[2]}).",
        flush=True,
    )
    print("Hold an NFC tag flat against the reader.", flush=True)
    print("Remove it before presenting the next tag. Press Ctrl+C to stop.")

    scan_number = 0
    active_uid: bytes | None = None

    while True:
        uid = pn532.read_passive_target(timeout=0.5)
        if uid is None:
            active_uid = None
            continue

        uid_bytes = bytes(uid)
        if uid_bytes == active_uid:
            continue

        active_uid = uid_bytes
        scan_number += 1
        uid_hex = ":".join(f"{byte:02X}" for byte in uid_bytes)
        uid_decimal = int.from_bytes(uid_bytes, byteorder="big")

        print(f"\nTag #{scan_number} detected!")
        print("Protocol: ISO/IEC 14443A")
        print(f"UID: {uid_hex}")
        print(f"UID (decimal): {uid_decimal}")
        print(f"UID length: {len(uid_bytes)} bytes")
        print("Remove this tag, then present the next one.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nNFC demo stopped.")
