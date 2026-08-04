from __future__ import annotations

from pathlib import Path

from build123d import (
    Align,
    Box,
    Color,
    Compound,
    Cylinder,
    Pos,
    Polygon,
    Rot,
    Sphere,
    Text,
    TextAlign,
    Torus,
    extrude,
)
from cadpy.assembly import AssemblyHelper


# Model units are millimeters. The photo-front sketch is X/Y with +Z projecting
# outward; gen_step rotates the final assembly into standard CAD X/Y/Z orientation.
RED = Color("#e2411f")
DARK_RED = Color("#8e1d16")
BLACK = Color("#151515")
MATTE_BLACK = Color("#252525")
GOLD = Color("#d7aa45")
FOX_WHITE = Color("#f5f1e6")
FOX_SHADOW = Color("#ded7c8")
COLLAR_RED = Color("#c32826")
METAL = Color("#c9c9bd")
LABEL_WHITE = Color("#f4f1e8")

FONT_PATH = Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf")
CAD_Y_OFFSET = 22.15
CAD_Z_OFFSET = 35.45


def photo_space_to_cad(shape):
    """Orient a photo-front shape into CAD coordinates: X width, Y depth, Z height."""
    return shape.moved(Rot(90, 0, 0)).translate((0, CAD_Y_OFFSET, CAD_Z_OFFSET))


def box_part(name: str, cx: float, cy: float, cz: float, sx: float, sy: float, sz: float, color: Color):
    shape = Pos(cx, cy, cz) * Box(sx, sy, sz)
    shape = photo_space_to_cad(shape)
    shape.label = name
    shape.color = color
    return shape


def cylinder_part(name: str, radius: float, height: float, cx: float, cy: float, cz: float, color: Color):
    shape = Pos(cx, cy, cz) * Cylinder(radius=radius, height=height)
    shape = photo_space_to_cad(shape)
    shape.label = name
    shape.color = color
    return shape


def torus_part(
    name: str,
    major_radius: float,
    minor_radius: float,
    cx: float,
    cy: float,
    cz: float,
    color: Color,
    major_angle: float = 360,
):
    shape = Pos(cx, cy, cz) * Torus(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_angle=major_angle,
    )
    shape = photo_space_to_cad(shape)
    shape.label = name
    shape.color = color
    return shape


def ellipsoid_part(
    name: str,
    cx: float,
    cy: float,
    cz: float,
    rx: float,
    ry: float,
    rz: float,
    color: Color,
):
    shape = Sphere(1)
    shape = shape.scale((rx, ry, rz))
    shape = shape.translate((cx, cy, cz))
    shape = photo_space_to_cad(shape)
    shape.label = name
    shape.color = color
    return shape


def polygon_part(name: str, points: list[tuple[float, float]], z0: float, depth: float, color: Color):
    shape = extrude(Polygon(*points, align=(Align.NONE, Align.NONE)), amount=depth)
    shape = shape.translate((0, 0, z0))
    shape = photo_space_to_cad(shape)
    shape.label = name
    shape.color = color
    return shape


def add_barcode(assembly: AssemblyHelper) -> None:
    x_positions = [-10.0, -8.2, -6.9, -5.0, -3.7, -1.9, -0.6, 1.2, 2.3, 4.4, 5.7, 7.3, 8.8, 10.2]
    widths = [0.45, 0.75, 0.35, 0.55, 0.3, 0.85, 0.45, 0.35, 0.8, 0.4, 0.6, 0.35, 0.7, 0.4]
    for index, (x_pos, width) in enumerate(zip(x_positions, widths), start=1):
        assembly.add(
            box_part(f"back_label_barcode_{index:02d}", x_pos, 0.0, -2.62, width, 9.2, 0.18, BLACK),
            f"back_label_barcode_{index:02d}",
        )


def add_plaque_text(assembly: AssemblyHelper) -> None:
    text_kwargs = {
        "font_size": 4.6,
        "text_align": (TextAlign.CENTER, TextAlign.CENTER),
    }
    if FONT_PATH.exists():
        text_kwargs["font_path"] = str(FONT_PATH)
    text_shape = extrude(Text("伏見\n稲荷", **text_kwargs), amount=0.35)
    text_shape = text_shape.translate((0, 24.0, 14.35))
    text_shape = photo_space_to_cad(text_shape)
    assembly.add(text_shape, "raised_fushimi_inari_text", color=BLACK)


def gen_step() -> Compound:
    assembly = AssemblyHelper("fushimi_inari_torii_fridge_magnet")

    # Backing and round magnet pad from the rear photo.
    assembly.add(box_part("flat_red_back_plate", 0, -2, 1.35, 58, 61, 2.7, RED), "flat_red_back_plate")
    assembly.add(cylinder_part("round_dark_back_magnet_pad", 22.5, 2.4, 0, -2, -1.2, MATTE_BLACK), "round_dark_back_magnet_pad")
    assembly.add(box_part("back_paper_label", 0, 0.5, -2.54, 29.5, 13.0, 0.16, LABEL_WHITE), "back_paper_label")
    add_barcode(assembly)

    # Torii gate structure.
    assembly.add(
        polygon_part(
            "black_curved_roof_cap",
            [(-37, 31.2), (-32, 35.5), (-10, 37.0), (0, 37.4), (10, 37.0), (32, 35.5), (37, 31.2), (34, 28.4), (-34, 28.4)],
            4.4,
            11.7,
            BLACK,
        ),
        "black_curved_roof_cap",
    )
    assembly.add(
        polygon_part(
            "red_roof_under_beam",
            [(-34, 26.6), (34, 26.6), (31.5, 21.7), (-31.5, 21.7)],
            2.8,
            8.7,
            RED,
        ),
        "red_roof_under_beam",
    )
    assembly.add(box_part("top_roof_front_ridge_1", 0, 34.7, 16.15, 64, 0.75, 0.8, MATTE_BLACK), "top_roof_front_ridge_1")
    assembly.add(box_part("top_roof_front_ridge_2", 0, 32.7, 16.2, 68, 0.7, 0.75, MATTE_BLACK), "top_roof_front_ridge_2")
    assembly.add(box_part("top_roof_front_ridge_3", 0, 30.6, 16.05, 62, 0.65, 0.7, MATTE_BLACK), "top_roof_front_ridge_3")

    assembly.add(box_part("dark_recess_behind_fox", 0, -6.5, 4.25, 43.5, 44.5, 1.0, DARK_RED), "dark_recess_behind_fox")
    assembly.add(
        polygon_part(
            "left_sloped_torii_pillar",
            [(-30.5, -28.5), (-21.7, -28.5), (-17.2, 22.6), (-25.4, 22.6)],
            5.0,
            7.0,
            RED,
        ),
        "left_sloped_torii_pillar",
    )
    assembly.add(
        polygon_part(
            "right_sloped_torii_pillar",
            [(21.7, -28.5), (30.5, -28.5), (25.4, 22.6), (17.2, 22.6)],
            5.0,
            7.0,
            RED,
        ),
        "right_sloped_torii_pillar",
    )
    assembly.add(box_part("front_cross_beam", 0, 15.8, 11.1, 64.5, 4.8, 5.0, RED), "front_cross_beam")
    assembly.add(box_part("left_beam_end_peg", -35.0, 15.8, 11.1, 5.6, 5.8, 5.4, RED), "left_beam_end_peg")
    assembly.add(box_part("right_beam_end_peg", 35.0, 15.8, 11.1, 5.6, 5.8, 5.4, RED), "right_beam_end_peg")
    assembly.add(box_part("lower_front_sill", 0, -25.4, 9.8, 50.0, 4.0, 4.4, RED), "lower_front_sill")

    for side, x in [("left", -27.7), ("right", 27.7)]:
        assembly.add(box_part(f"{side}_black_foot_block", x, -31.1, 9.2, 13.5, 8.7, 7.2, BLACK), f"{side}_black_foot_block")
        assembly.add(box_part(f"{side}_pillar_black_plinth", x, -24.6, 12.4, 10.2, 3.2, 4.2, BLACK), f"{side}_pillar_black_plinth")
        assembly.add(box_part(f"{side}_upper_rib_1", x * 0.82, 20.4, 12.0, 8.0, 0.65, 2.7, RED), f"{side}_upper_rib_1")
        assembly.add(box_part(f"{side}_upper_rib_2", x * 0.82, 18.3, 12.1, 8.0, 0.65, 2.6, RED), f"{side}_upper_rib_2")

    # Central gold plaque and raised lettering.
    assembly.add(box_part("gold_name_plaque", 0, 24.0, 13.75, 20.6, 13.5, 1.25, GOLD), "gold_name_plaque")
    assembly.add(box_part("plaque_top_black_border", 0, 30.7, 14.52, 20.9, 0.55, 0.65, BLACK), "plaque_top_black_border")
    assembly.add(box_part("plaque_bottom_black_border", 0, 17.3, 14.52, 20.9, 0.55, 0.65, BLACK), "plaque_bottom_black_border")
    assembly.add(box_part("plaque_left_black_border", -10.45, 24.0, 14.52, 0.55, 13.5, 0.65, BLACK), "plaque_left_black_border")
    assembly.add(box_part("plaque_right_black_border", 10.45, 24.0, 14.52, 0.55, 13.5, 0.65, BLACK), "plaque_right_black_border")
    add_plaque_text(assembly)

    # Hanging hardware and fox charm.
    assembly.add(torus_part("small_silver_hanging_ring", 2.55, 0.38, 0, 13.3, 15.4, METAL), "small_silver_hanging_ring")
    assembly.add(box_part("tiny_hanging_link", 0, 10.4, 15.4, 1.1, 3.5, 0.85, METAL), "tiny_hanging_link")

    assembly.add(ellipsoid_part("fox_body", 0, -15.3, 17.0, 7.6, 10.4, 4.8, FOX_WHITE), "fox_body")
    assembly.add(ellipsoid_part("fox_head", 0, 0.1, 17.0, 7.5, 7.0, 4.6, FOX_WHITE), "fox_head")
    assembly.add(ellipsoid_part("fox_muzzle", 0, -2.4, 21.0, 3.4, 2.5, 1.1, FOX_SHADOW), "fox_muzzle")
    assembly.add(ellipsoid_part("fox_left_eye", -2.7, 1.3, 21.1, 0.45, 0.7, 0.25, BLACK), "fox_left_eye")
    assembly.add(ellipsoid_part("fox_right_eye", 2.7, 1.3, 21.1, 0.45, 0.7, 0.25, BLACK), "fox_right_eye")
    assembly.add(ellipsoid_part("fox_black_nose", 0, -3.1, 22.0, 0.9, 0.62, 0.3, BLACK), "fox_black_nose")
    assembly.add(box_part("fox_red_collar", 0, -7.1, 21.0, 11.0, 1.35, 0.95, COLLAR_RED), "fox_red_collar")
    assembly.add(ellipsoid_part("fox_left_paw", -3.0, -24.0, 19.2, 2.0, 2.9, 1.2, FOX_WHITE), "fox_left_paw")
    assembly.add(ellipsoid_part("fox_right_paw", 3.0, -24.0, 19.2, 2.0, 2.9, 1.2, FOX_WHITE), "fox_right_paw")
    assembly.add(torus_part("curled_fox_tail", 4.4, 1.15, 6.2, -15.0, 21.0, FOX_WHITE), "curled_fox_tail")
    assembly.add(
        polygon_part("fox_left_ear", [(-7.8, 3.4), (-2.2, 3.4), (-5.7, 12.0)], 16.0, 4.8, FOX_WHITE),
        "fox_left_ear",
    )
    assembly.add(
        polygon_part("fox_right_ear", [(2.2, 3.4), (7.8, 3.4), (5.7, 12.0)], 16.0, 4.8, FOX_WHITE),
        "fox_right_ear",
    )
    assembly.add(
        polygon_part("fox_left_inner_ear_red", [(-6.4, 4.7), (-3.7, 4.7), (-5.5, 9.0)], 20.9, 0.35, COLLAR_RED),
        "fox_left_inner_ear_red",
    )
    assembly.add(
        polygon_part("fox_right_inner_ear_red", [(3.7, 4.7), (6.4, 4.7), (5.5, 9.0)], 20.9, 0.35, COLLAR_RED),
        "fox_right_inner_ear_red",
    )

    return assembly.build()


if __name__ == "__main__":
    gen_step()
