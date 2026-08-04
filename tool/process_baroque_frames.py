#!/usr/bin/env python3
"""Turn a chroma-key frame concept sheet into Flutter-ready PNG assets."""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


@dataclass(frozen=True)
class FrameSpec:
    name: str
    crop: tuple[float, float, float, float]
    output_size: tuple[int, int]


FRAME_SPECS = (
    FrameSpec("oval", (0.01, 0.14, 0.30, 0.83), (1656, 2360)),
    FrameSpec("portrait", (0.30, 0.14, 0.58, 0.83), (1732, 2472)),
    FrameSpec("landscape", (0.58, 0.29, 1.0, 0.84), (2224, 1784)),
)


def _chroma_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    keyed = []
    for red, green, blue, _ in rgba.getdata():
        green_dominance = green - max(red, blue)
        alpha = max(0, min(255, round((105 - green_dominance) * 255 / 75)))
        # Remove green spill from both anti-aliased edges and reflective gilt.
        # Genuine gold pixels are red-dominant, so this keeps their color intact.
        green = min(green, max(red, blue))
        keyed.append((red, green, blue, alpha))
    rgba.putdata(keyed)
    return rgba


def _visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A").point(lambda value: 255 if value > 24 else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("No frame pixels survived chroma keying")
    left, top, right, bottom = bbox
    margin = 4
    return (
        max(0, left - margin),
        max(0, top - margin),
        min(image.width, right + margin),
        min(image.height, bottom + margin),
    )


def _opening_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    """Return the largest transparent hole enclosed by the frame."""

    alpha = image.getchannel("A")
    width, height = image.size
    transparent = bytearray(
        1 if alpha.getpixel((x, y)) <= 12 else 0
        for y in range(height)
        for x in range(width)
    )
    outside = bytearray(width * height)
    queue: deque[int] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if transparent[index] and not outside[index]:
            outside[index] = 1
            queue.append(index)

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        index = queue.popleft()
        x, y = index % width, index // width
        if x:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    visited = bytearray(width * height)
    largest: tuple[int, int, int, int, int] | None = None
    for start in range(width * height):
        if not transparent[start] or outside[start] or visited[start]:
            continue
        visited[start] = 1
        queue.append(start)
        count = 0
        min_x = max_x = start % width
        min_y = max_y = start // width
        while queue:
            index = queue.popleft()
            x, y = index % width, index // width
            count += 1
            min_x, max_x = min(min_x, x), max(max_x, x)
            min_y, max_y = min(min_y, y), max(max_y, y)
            for neighbor in (
                index - 1 if x else -1,
                index + 1 if x + 1 < width else -1,
                index - width if y else -1,
                index + width if y + 1 < height else -1,
            ):
                if (
                    neighbor >= 0
                    and transparent[neighbor]
                    and not outside[neighbor]
                    and not visited[neighbor]
                ):
                    visited[neighbor] = 1
                    queue.append(neighbor)
        candidate = (count, min_x, min_y, max_x + 1, max_y + 1)
        if largest is None or candidate[0] > largest[0]:
            largest = candidate

    if largest is None:
        raise ValueError("Could not find an enclosed photo opening")
    _, left, top, right, bottom = largest
    return left, top, right, bottom


def _process_frame(
    sheet: Image.Image,
    spec: FrameSpec,
    output_dir: Path,
) -> tuple[float, float, float, float]:
    left, top, right, bottom = spec.crop
    crop = sheet.crop(
        (
            round(left * sheet.width),
            round(top * sheet.height),
            round(right * sheet.width),
            round(bottom * sheet.height),
        )
    )
    keyed = _chroma_key(crop)
    trimmed = keyed.crop(_visible_bbox(keyed))
    opening = _opening_bbox(trimmed)

    target_width, target_height = spec.output_size
    scale = min(target_width / trimmed.width, target_height / trimmed.height)
    resized_size = (
        round(trimmed.width * scale),
        round(trimmed.height * scale),
    )
    resized = trimmed.resize(resized_size, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", spec.output_size, (0, 0, 0, 0))
    offset_x = (target_width - resized.width) // 2
    offset_y = (target_height - resized.height) // 2
    output.alpha_composite(resized, (offset_x, offset_y))

    output_path = output_dir / f"baroque-frame-{spec.name}-hd.png"
    output.save(output_path, optimize=True)

    opening_left, opening_top, opening_right, opening_bottom = opening
    normalized = (
        (offset_x + opening_left * scale) / target_width,
        (offset_y + opening_top * scale) / target_height,
        (opening_right - opening_left) * scale / target_width,
        (opening_bottom - opening_top) * scale / target_height,
    )
    return normalized


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    sheet = Image.open(args.source).convert("RGB")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for spec in FRAME_SPECS:
        photo_rect = _process_frame(sheet, spec, args.output_dir)
        print(
            f"{spec.name}: "
            + ", ".join(f"{value:.4f}" for value in photo_rect)
        )


if __name__ == "__main__":
    main()
