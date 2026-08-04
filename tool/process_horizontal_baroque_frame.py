#!/usr/bin/env python3
"""Prepare the dedicated horizontal Rococo frame for Flutter."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from process_baroque_frames import _opening_bbox, _visible_bbox


OUTPUT_SIZE = (2500, 1700)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    keyed = Image.open(args.source).convert("RGBA")
    trimmed = keyed.crop(_visible_bbox(keyed))
    opening = _opening_bbox(trimmed)

    target_width, target_height = OUTPUT_SIZE
    scale = min(target_width / trimmed.width, target_height / trimmed.height)
    resized_size = (
        round(trimmed.width * scale),
        round(trimmed.height * scale),
    )
    resized = trimmed.resize(resized_size, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", OUTPUT_SIZE, (0, 0, 0, 0))
    offset_x = (target_width - resized.width) // 2
    offset_y = (target_height - resized.height) // 2
    output.alpha_composite(resized, (offset_x, offset_y))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output, optimize=True)

    left, top, right, bottom = opening
    photo_rect = (
        (offset_x + left * scale) / target_width,
        (offset_y + top * scale) / target_height,
        (right - left) * scale / target_width,
        (bottom - top) * scale / target_height,
    )
    print(", ".join(f"{value:.4f}" for value in photo_rect))


if __name__ == "__main__":
    main()
