#!/usr/bin/env python3
"""Generate compact destination-centered globe rotation sheets."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/images/experience/earth-blue-marble.png"
OUTPUT_DIRECTORY = ROOT / "assets/images/experience"

FRAME_SIZE = 480
FRAME_COUNT = 32
COLUMNS = 8
ROWS = 4
DESTINATION_FRAME = 28
DESTINATION_CAMERA_OFFSET_DEGREES = 30.0

DESTINATIONS = {
    "japan": (35.6762, 139.6503),
    "south-korea": (37.5665, 126.9780),
    "china": (39.9042, 116.4074),
    "philippines": (14.5995, 120.9842),
    "turkey": (41.0082, 28.9784),
    "taiwan": (25.0330, 121.5654),
    "hong-kong": (22.3193, 114.1694),
    "thailand": (13.7563, 100.5018),
    "malaysia": (3.1390, 101.6869),
    "bali": (-8.4095, 115.1889),
    "vietnam": (15.8801, 108.3380),
    "sri-lanka": (7.9570, 80.7603),
}


def _screen_geometry():
    axis = (np.arange(FRAME_SIZE, dtype=np.float32) + 0.5) / FRAME_SIZE
    screen_x, screen_y_down = np.meshgrid(axis * 2.0 - 1.0, axis)
    screen_y = 1.0 - screen_y_down * 2.0
    radius_squared = screen_x * screen_x + screen_y * screen_y
    mask = radius_squared < 1.0
    depth = np.sqrt(np.clip(1.0 - radius_squared, 0.0, 1.0))
    edge_distance = (1.0 - np.sqrt(np.clip(radius_squared, 0.0, 1.0))) * (
        FRAME_SIZE / 2.0
    )
    edge_opacity = np.clip(edge_distance, 0.0, 1.0)
    return screen_x, screen_y, depth, mask, edge_opacity


SCREEN_X, SCREEN_Y, DEPTH, GLOBE_MASK, EDGE_OPACITY = _screen_geometry()


def _sample_texture(texture: np.ndarray, u: np.ndarray, v: np.ndarray):
    height, width, _ = texture.shape
    x = np.mod(u, 1.0) * width
    y = np.clip(v, 0.0, 1.0) * (height - 1)
    x0 = np.floor(x).astype(np.int32) % width
    y0 = np.floor(y).astype(np.int32)
    x1 = (x0 + 1) % width
    y1 = np.minimum(y0 + 1, height - 1)
    tx = (x - np.floor(x))[..., None]
    ty = (y - y0)[..., None]
    top = texture[y0, x0] * (1.0 - tx) + texture[y0, x1] * tx
    bottom = texture[y1, x0] * (1.0 - tx) + texture[y1, x1] * tx
    return top * (1.0 - ty) + bottom * ty


def _render_frame(
    texture: np.ndarray,
    center_longitude: float,
    camera_latitude_degrees: float,
) -> Image.Image:
    center_latitude = np.radians(camera_latitude_degrees)
    sin_center = np.sin(center_latitude)
    cos_center = np.cos(center_latitude)
    sin_latitude = cos_center * SCREEN_Y + sin_center * DEPTH
    latitude = np.arcsin(np.clip(sin_latitude, -1.0, 1.0))
    longitude_delta = np.arctan2(
        SCREEN_X, -sin_center * SCREEN_Y + cos_center * DEPTH
    )
    longitude = np.radians(center_longitude) + longitude_delta
    u = np.mod(longitude / (2.0 * np.pi) + 0.5, 1.0)
    v = 0.5 - latitude / np.pi
    pixels = _sample_texture(texture, u, v)

    light = np.asarray((-0.42, -0.28, 0.86), dtype=np.float32)
    light /= np.linalg.norm(light)
    diffuse = np.maximum(
        0.0,
        SCREEN_X * light[0] + SCREEN_Y * light[1] + DEPTH * light[2],
    )
    illumination = (0.48 + 0.52 * diffuse) * (
        0.66 + 0.34 * np.power(DEPTH, 0.32)
    )
    pixels *= illumination[..., None] * EDGE_OPACITY[..., None]
    pixels[~GLOBE_MASK] = 0
    return Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGB")


def _generate_sheet(
    texture: np.ndarray,
    slug: str,
    latitude: float,
    longitude: float,
) -> Path:
    camera_latitude = latitude - DESTINATION_CAMERA_OFFSET_DEGREES
    destination_frame_center = -180.0 + DESTINATION_FRAME * (
        360.0 / FRAME_COUNT
    )
    longitude_phase = longitude - destination_frame_center
    output = OUTPUT_DIRECTORY / f"earth-globe-{slug}-centered-rotation-sheet.jpg"
    sheet = Image.new(
        "RGB", (FRAME_SIZE * COLUMNS, FRAME_SIZE * ROWS), (0, 0, 0)
    )
    for frame_index in range(FRAME_COUNT):
        center_longitude = (
            -180.0 + longitude_phase + frame_index * (360.0 / FRAME_COUNT)
        )
        frame = _render_frame(texture, center_longitude, camera_latitude)
        column = frame_index % COLUMNS
        row = frame_index // COLUMNS
        sheet.paste(frame, (column * FRAME_SIZE, row * FRAME_SIZE))

    sheet.save(output, "JPEG", quality=90, optimize=True, progressive=True)
    return output


def main() -> None:
    texture = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=np.float32)
    requested_slugs = sys.argv[1:] or list(DESTINATIONS)
    unknown_slugs = set(requested_slugs).difference(DESTINATIONS)
    if unknown_slugs:
        raise SystemExit(f"Unknown destination slug(s): {sorted(unknown_slugs)}")
    for slug in requested_slugs:
        latitude, longitude = DESTINATIONS[slug]
        print(_generate_sheet(texture, slug, latitude, longitude), flush=True)


if __name__ == "__main__":
    main()
