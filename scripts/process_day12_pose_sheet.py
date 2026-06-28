#!/usr/bin/env python3
"""Turn the Day 12 chroma pose sheet into transparent, padded pose assets."""

from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


POSES = {
    "sit_window": (0, 0),
    "lie_rest": (1, 0),
    "stand_turn": (0, 1),
    "play_bow": (1, 1),
}

LAYER_BOXES = {
    "sit_window": {
        "body": (205, 195, 620, 700),
        "front_legs": (200, 430, 390, 735),
        "rear_leg": (325, 430, 585, 735),
        "tail": (455, 500, 730, 755),
        "head": (105, 25, 430, 335),
        "ear_far": (225, 25, 305, 155),
        "ear_near": (260, 25, 355, 170),
        "eyes": (165, 105, 285, 185),
        "muzzle": (100, 125, 285, 245),
    },
    "lie_rest": {
        "body": (245, 400, 660, 715),
        "front_legs": (35, 555, 350, 755),
        "rear_leg": (425, 505, 640, 735),
        "tail": (580, 500, 765, 750),
        "head": (65, 300, 350, 605),
        "ear_far": (105, 300, 180, 430),
        "ear_near": (205, 305, 290, 445),
        "eyes": (105, 410, 250, 500),
        "muzzle": (60, 430, 250, 550),
    },
    "stand_turn": {
        "body": (235, 150, 625, 545),
        "front_legs": (95, 360, 290, 755),
        "rear_leg": (500, 400, 750, 755),
        "tail": (500, 55, 755, 330),
        "head": (25, 25, 310, 325),
        "ear_far": (45, 20, 135, 175),
        "ear_near": (165, 25, 265, 185),
        "eyes": (75, 125, 235, 220),
        "muzzle": (55, 165, 250, 285),
    },
    "play_bow": {
        "body": (275, 190, 650, 610),
        "front_legs": (30, 540, 430, 755),
        "rear_leg": (525, 390, 755, 690),
        "tail": (495, 25, 740, 300),
        "head": (55, 350, 355, 640),
        "ear_far": (115, 340, 195, 485),
        "ear_near": (210, 355, 300, 500),
        "eyes": (110, 455, 270, 545),
        "muzzle": (55, 485, 270, 610),
    },
}

ASSET_PREFIXES = {
    "sit_window": "DogSitWindow",
    "lie_rest": "DogLieRest",
    "stand_turn": "DogStandTurn",
    "play_bow": "DogPlayBow",
}


def is_green(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _ = pixel
    return green >= 105 and green >= red * 1.28 and green >= blue * 1.35


def remove_connected_chroma(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    queue: deque[tuple[int, int]] = deque()
    visited = bytearray(width * height)

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not visited[index] and is_green(pixels[x, y]):
            visited[index] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue(nx, ny)

    output = rgba.copy()
    output_pixels = output.load()
    for y in range(height):
        for x in range(width):
            if visited[y * width + x] or is_green(pixels[x, y]):
                output_pixels[x, y] = (0, 0, 0, 0)
    return output


def trim_and_pad(image: Image.Image, size: int = 768, padding: int = 42) -> Image.Image:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Pose cell contains no visible pixels")
    subject = image.crop(bounds)
    available = size - padding * 2
    scale = min(available / subject.width, available / subject.height)
    resized = subject.resize(
        (round(subject.width * scale), round(subject.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - resized.width) // 2
    y = size - padding - resized.height
    canvas.alpha_composite(resized, (x, y))
    return clean_alpha_edges(canvas)


def clean_alpha_edges(image: Image.Image) -> Image.Image:
    output = image.convert("RGBA").copy()
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            baseline = max(red, blue)
            if green > 105 and green > red * 1.2 and green > blue * 1.25:
                pixels[x, y] = (red, baseline, blue, 0)
            elif green > baseline + 10:
                pixels[x, y] = (red, baseline, blue, alpha)
    return output


def save_pose_set(pose: Image.Image, name: str, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    clean_alpha_edges(pose).save(output_dir / f"dog_{name}_full@3x.png")
    clean_alpha_edges(pose.resize((512, 512), Image.Resampling.LANCZOS)).save(
        output_dir / f"dog_{name}_full@2x.png"
    )


def masked_layer(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=24, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(4))
    alpha = image.getchannel("A")
    mask = Image.composite(mask, Image.new("L", image.size, 0), alpha)
    output = image.copy()
    output.putalpha(mask)
    return output


def write_imageset(
    catalog: Path,
    asset_name: str,
    filename_stem: str,
    image: Image.Image,
) -> None:
    imageset = catalog / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    three_x = f"{filename_stem}@3x.png"
    two_x = f"{filename_stem}@2x.png"
    clean_alpha_edges(image).save(imageset / three_x)
    clean_alpha_edges(image.resize((512, 512), Image.Resampling.LANCZOS)).save(
        imageset / two_x
    )
    contents = {
        "images": [
            {"idiom": "universal", "scale": "1x"},
            {"filename": two_x, "idiom": "universal", "scale": "2x"},
            {"filename": three_x, "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(
        json.dumps(contents, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def ground_shadow(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Cannot create a shadow for an empty pose")
    left, _, right, bottom = bounds
    width = right - left
    shadow_mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(shadow_mask)
    inset = max(10, width // 12)
    draw.ellipse(
        (left + inset, bottom - 34, right - inset, bottom + 8),
        fill=92,
    )
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(14))
    shadow = Image.new("RGBA", image.size, (64, 48, 28, 0))
    shadow.putalpha(shadow_mask)
    return shadow


def normalized_poses(source: Image.Image) -> dict[str, Image.Image]:
    transparent = remove_connected_chroma(source)
    cell_width = source.width // 2
    cell_height = source.height // 2
    result = {}
    for name, (column, row) in POSES.items():
        cell = transparent.crop(
            (
                column * cell_width,
                row * cell_height,
                (column + 1) * cell_width,
                (row + 1) * cell_height,
            )
        )
        result[name] = trim_and_pad(cell)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--closed-input", type=Path)
    parser.add_argument("--catalog", type=Path)
    args = parser.parse_args()

    source = Image.open(args.input).convert("RGBA")
    transparent_master = remove_connected_chroma(source)
    args.output.mkdir(parents=True, exist_ok=True)
    transparent_master.save(args.output / "dog_pose_master.png")
    open_poses = normalized_poses(source)
    closed_poses = (
        normalized_poses(Image.open(args.closed_input).convert("RGBA"))
        if args.closed_input
        else open_poses
    )

    for name, pose in open_poses.items():
        save_pose_set(pose, name, args.output / name)
        if not args.catalog:
            continue
        prefix = ASSET_PREFIXES[name]
        write_imageset(
            args.catalog,
            prefix,
            f"dog_{name}_full",
            pose,
        )
        write_imageset(
            args.catalog,
            f"{prefix}Shadow",
            f"dog_{name}_shadow",
            ground_shadow(pose),
        )
        for layer_name, box in LAYER_BOXES[name].items():
            if layer_name == "eyes":
                write_imageset(
                    args.catalog,
                    f"{prefix}EyesOpen",
                    f"dog_{name}_eyes_open",
                    masked_layer(pose, box),
                )
                write_imageset(
                    args.catalog,
                    f"{prefix}EyesClosed",
                    f"dog_{name}_eyes_closed",
                    masked_layer(closed_poses[name], box),
                )
                continue
            asset_suffix = "".join(part.title() for part in layer_name.split("_"))
            write_imageset(
                args.catalog,
                f"{prefix}{asset_suffix}",
                f"dog_{name}_{layer_name}",
                masked_layer(pose, box),
            )


if __name__ == "__main__":
    main()
