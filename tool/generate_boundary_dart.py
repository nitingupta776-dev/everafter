#!/usr/bin/env python3
"""Convert GeoJSON polygon geometry to simplified Dart Offset rings."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def _point_line_distance(point, start, end):
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    if dx == 0 and dy == 0:
        return math.hypot(point[0] - start[0], point[1] - start[1])
    t = max(
        0.0,
        min(
            1.0,
            ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy)
            / (dx * dx + dy * dy),
        ),
    )
    projected = (start[0] + t * dx, start[1] + t * dy)
    return math.hypot(point[0] - projected[0], point[1] - projected[1])


def _simplify(points, tolerance):
    if len(points) <= 2:
        return points
    farthest_index = 0
    farthest_distance = 0.0
    for index, point in enumerate(points[1:-1], start=1):
        distance = _point_line_distance(point, points[0], points[-1])
        if distance > farthest_distance:
            farthest_index = index
            farthest_distance = distance
    if farthest_distance <= tolerance:
        return [points[0], points[-1]]
    before = _simplify(points[: farthest_index + 1], tolerance)
    after = _simplify(points[farthest_index:], tolerance)
    return before[:-1] + after


def _polygon_rings(geometry):
    coordinates = geometry["coordinates"]
    polygons = coordinates if geometry["type"] == "MultiPolygon" else [coordinates]
    for polygon in polygons:
        # Keep exterior rings only. Interior holes are not needed for a glowing
        # country silhouette at this display scale.
        yield polygon[0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("constant")
    parser.add_argument("--tolerance", type=float, default=0.12)
    parser.add_argument("--label", default="Country")
    parser.add_argument(
        "--feature-name",
        help="Select one feature by its geoBoundaries shapeName property.",
    )
    args = parser.parse_args()

    data = json.loads(args.source.read_text())
    features = data["features"]
    if args.feature_name:
        matching_features = [
            feature
            for feature in features
            if feature.get("properties", {}).get("shapeName") == args.feature_name
        ]
        if len(matching_features) != 1:
            available_names = sorted(
                feature.get("properties", {}).get("shapeName", "")
                for feature in features
            )
            raise SystemExit(
                f"Expected one feature named {args.feature_name!r}; "
                f"found {len(matching_features)}. Available: {available_names}"
            )
        feature = matching_features[0]
    else:
        if len(features) != 1:
            raise SystemExit(
                f"Source contains {len(features)} features; pass --feature-name."
            )
        feature = features[0]
    geometry = feature["geometry"]
    rings = []
    for ring in _polygon_rings(geometry):
        open_ring = ring[:-1] if ring[0] == ring[-1] else ring
        simplified = _simplify(open_ring, args.tolerance)
        if len(simplified) >= 3:
            rings.append(simplified)

    lines = [
        "import 'dart:ui';",
        "",
        f"/// {args.label} boundary simplified for globe rendering.",
        "/// Each Offset stores longitude in dx and latitude in dy.",
        f"const List<List<Offset>> {args.constant} = <List<Offset>>[",
    ]
    for ring in rings:
        lines.append("  <Offset>[")
        for longitude, latitude in ring:
            lines.append(f"    Offset({longitude:.5f}, {latitude:.5f}),")
        lines.append("  ],")
    lines.extend(["];"])
    args.output.write_text("\n".join(lines))
    print(f"{args.output}: {sum(len(ring) for ring in rings)} points")


if __name__ == "__main__":
    main()
