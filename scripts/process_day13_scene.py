#!/usr/bin/env python3
"""Create Day 13 room layers and event-trace assets from generated masters."""

from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from process_day12_pose_sheet import clean_alpha_edges, remove_connected_chroma


SCENE_SIZE_3X = (1290, 2796)
SCENE_SIZE_2X = (860, 1864)

LAYER_BOXES = {
    "BackSky": (110, 0, 730, 690),
    "BackCity": (110, 390, 735, 940),
    "Window": (75, 0, 775, 1010),
    "CurtainBack": (470, 0, 810, 1030),
    "CurtainFront": (350, 0, 835, 1080),
    "Floor": (0, 900, 852, 1846),
    "FurnitureLeft": (0, 80, 285, 1090),
    "FurnitureRight": (650, 300, 852, 1210),
    "SunPatch": (0, 830, 560, 1580),
}


def soft_layer(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=36, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(8))
    alpha = image.getchannel("A")
    mask = Image.composite(mask, Image.new("L", image.size, 0), alpha)
    output = image.copy()
    output.putalpha(mask)
    return clean_alpha_edges(output)


def vignette(size: tuple[int, int]) -> Image.Image:
    width, height = size
    alpha = Image.new("L", size, 0)
    draw = ImageDraw.Draw(alpha)
    border = max(28, width // 18)
    for step in range(border):
        opacity = round(20 * (1 - step / border) ** 2)
        draw.rectangle(
            (step, step, width - step - 1, height - step - 1),
            outline=opacity,
            width=1,
        )
    output = Image.new("RGBA", size, (57, 42, 25, 0))
    output.putalpha(alpha)
    return output


def write_imageset(
    catalog: Path,
    asset_name: str,
    filename_stem: str,
    image: Image.Image,
    size_3x: tuple[int, int] = SCENE_SIZE_3X,
    size_2x: tuple[int, int] = SCENE_SIZE_2X,
) -> None:
    imageset = catalog / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    three_x_name = f"{filename_stem}@3x.png"
    two_x_name = f"{filename_stem}@2x.png"
    three_x = clean_alpha_edges(image.resize(size_3x, Image.Resampling.LANCZOS))
    two_x = clean_alpha_edges(image.resize(size_2x, Image.Resampling.LANCZOS))
    three_x.save(imageset / three_x_name, optimize=True)
    two_x.save(imageset / two_x_name, optimize=True)
    contents = {
        "images": [
            {"idiom": "universal", "scale": "1x"},
            {"filename": two_x_name, "idiom": "universal", "scale": "2x"},
            {"filename": three_x_name, "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(
        json.dumps(contents, indent=2) + "\n",
        encoding="utf-8",
    )


def trim_and_pad(image: Image.Image, size: int = 384, padding: int = 24) -> Image.Image:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Trace cell contains no visible pixels")
    subject = image.crop(bounds)
    available = size - padding * 2
    scale = min(available / subject.width, available / subject.height)
    subject = subject.resize(
        (round(subject.width * scale), round(subject.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        subject,
        ((size - subject.width) // 2, size - padding - subject.height),
    )
    return clean_alpha_edges(canvas)


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    output = image.copy()
    alpha = output.getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    seen = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or pixels[x, y] < 20:
                continue
            seen[index] = 1
            queue = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx, ny in (
                    (cx - 1, cy),
                    (cx + 1, cy),
                    (cx, cy - 1),
                    (cx, cy + 1),
                ):
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    neighbor = ny * width + nx
                    if seen[neighbor] or pixels[nx, ny] < 20:
                        continue
                    seen[neighbor] = 1
                    queue.append((nx, ny))

            components.append(component)

    if not components:
        return output
    keep = set(max(components, key=len))
    rgba = output.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                red, green, blue, _ = rgba[x, y]
                rgba[x, y] = (red, green, blue, 0)
    return output


def trace_assets(trace_sheet: Image.Image) -> dict[str, Image.Image]:
    transparent = remove_connected_chroma(trace_sheet.convert("RGBA"))
    width, height = transparent.size
    cell_width = width // 3
    cells = [
        transparent.crop((index * cell_width, 0, (index + 1) * cell_width, height))
        for index in range(3)
    ]

    nose_source = cells[2]
    nose = nose_source.crop(
        (
            round(nose_source.width * 0.20),
            round(nose_source.height * 0.35),
            round(nose_source.width * 0.62),
            round(nose_source.height * 0.68),
        )
    )
    nose_mask = Image.new("L", nose.size, 0)
    draw = ImageDraw.Draw(nose_mask)
    draw.ellipse(
        (
            0,
            0,
            nose.width,
            nose.height,
        ),
        fill=255,
    )
    nose.putalpha(Image.composite(nose_mask, Image.new("L", nose.size, 0), nose.getchannel("A")))

    return {
        "TraceToyMoved": trim_and_pad(cells[0]),
        "TracePaperBag": trim_and_pad(cells[1]),
        "TraceNoseMarkWindow": trim_and_pad(keep_largest_alpha_component(nose)),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("scene", type=Path)
    parser.add_argument("traces", type=Path)
    parser.add_argument("catalog", type=Path)
    args = parser.parse_args()

    scene = Image.open(args.scene).convert("RGBA")
    write_imageset(args.catalog, "SceneHomeBase", "scene_home_base", scene)
    for suffix, box in LAYER_BOXES.items():
        write_imageset(
            args.catalog,
            f"SceneHome{suffix}",
            f"scene_home_{suffix.lower()}",
            soft_layer(scene, box),
        )
    write_imageset(
        args.catalog,
        "SceneHomeFrontVignette",
        "scene_home_front_vignette",
        vignette(scene.size),
    )

    for asset_name, image in trace_assets(Image.open(args.traces)) .items():
        write_imageset(
            args.catalog,
            asset_name,
            "_".join(
                [
                    "trace",
                    asset_name.removeprefix("Trace")
                    .replace("Window", "_window")
                    .replace("Moved", "_moved")
                    .replace("Bag", "_bag")
                    .lower(),
                ]
            ),
            image,
            size_3x=(384, 384),
            size_2x=(256, 256),
        )


if __name__ == "__main__":
    main()
