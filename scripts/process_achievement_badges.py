#!/usr/bin/env python3
"""Build DeepMine achievement badge PNGs from generated square source art."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PALETTE = (
    (16, 16, 15),     # coal
    (55, 54, 48),     # shale
    (231, 224, 207),  # limestone
    (197, 140, 57),   # lamp brass
)
EXPECTED_BADGE_COUNT = 35


def quantize(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    palette_image = Image.new("P", (1, 1))
    flat_palette = [component for color in PALETTE for component in color]
    palette_image.putpalette(flat_palette + [0] * (768 - len(flat_palette)))
    result = rgb.quantize(palette=palette_image, dither=Image.Dither.NONE).convert("RGB")
    unused_palette_mask = result.convert("L").point(lambda value: 255 if value == 0 else 0)
    result.paste(PALETTE[0], mask=unused_palette_mask)
    return result


def contents_json(filenames: dict[int, str]) -> str:
    payload = {
        "images": [
            {"filename": filenames[1], "idiom": "universal", "scale": "1x"},
            {"filename": filenames[2], "idiom": "universal", "scale": "2x"},
            {"filename": filenames[3], "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "compression-type": "lossless",
            "template-rendering-intent": "original",
        },
    }
    return json.dumps(payload, indent=2) + "\n"


def build_badge(source: Path, badge_id: str, catalog: Path) -> dict[str, object]:
    with Image.open(source) as opened:
        if opened.format != "PNG" or opened.width != opened.height:
            raise ValueError(f"{badge_id}: source must be a square PNG")
        quantized = quantize(opened)

    logical = quantized.resize((96, 96), Image.Resampling.NEAREST)
    outputs = {
        1: logical.resize((48, 48), Image.Resampling.NEAREST),
        2: logical,
        3: logical.resize((144, 144), Image.Resampling.NEAREST),
    }
    stem = f"achievement-badge-{badge_id}"
    filenames = {
        1: f"{stem}.png",
        2: f"{stem}@2x.png",
        3: f"{stem}@3x.png",
    }
    imageset = catalog / f"AchievementBadge_{badge_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    for scale, image in outputs.items():
        image.save(imageset / filenames[scale], format="PNG", optimize=True)
    (imageset / "Contents.json").write_text(contents_json(filenames), encoding="utf-8")

    colors = sorted(
        {
            color
            for image in outputs.values()
            for _, color in (image.getcolors(maxcolors=image.width * image.height) or [])
        }
    )
    if not set(colors).issubset(PALETTE):
        raise ValueError(f"{badge_id}: output escaped the DeepMine palette")
    for image in outputs.values():
        corners = (
            image.getpixel((0, 0)),
            image.getpixel((image.width - 1, 0)),
            image.getpixel((0, image.height - 1)),
            image.getpixel((image.width - 1, image.height - 1)),
        )
        if image.mode != "RGB" or any(color != PALETTE[0] for color in corners):
            raise ValueError(f"{badge_id}: output must be opaque with coal corners")

    return {
        "id": badge_id,
        "source": str(source),
        "imageset": str(imageset),
        "sizes": [[image.width, image.height] for image in outputs.values()],
        "colors": ["#%02X%02X%02X" % color for color in colors],
    }


def contact_sheet(ids: list[str], catalog: Path, output: Path) -> None:
    columns = 5
    cell_width = 176
    cell_height = 194
    rows = (len(ids) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_width, rows * cell_height), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)

    for index, badge_id in enumerate(ids):
        column = index % columns
        row = index // columns
        origin_x = column * cell_width
        origin_y = row * cell_height
        image_path = (
            catalog
            / f"AchievementBadge_{badge_id}.imageset"
            / f"achievement-badge-{badge_id}.png"
        )
        with Image.open(image_path) as badge:
            preview = badge.resize((144, 144), Image.Resampling.NEAREST)
            sheet.paste(preview, (origin_x + 16, origin_y + 8))
        draw.text(
            (origin_x + 8, origin_y + 160),
            badge_id,
            fill=PALETTE[2],
            font=font,
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--contact-sheet", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    entries = json.loads(args.manifest.read_text(encoding="utf-8"))
    ids = [entry["id"] for entry in entries]
    if len(ids) != EXPECTED_BADGE_COUNT or len(set(ids)) != EXPECTED_BADGE_COUNT:
        raise ValueError("manifest must contain exactly 35 unique achievement IDs")
    args.catalog.mkdir(parents=True, exist_ok=True)
    reports = [
        build_badge(Path(entry["source"]), entry["id"], args.catalog)
        for entry in entries
    ]
    contact_sheet(ids, args.catalog, args.contact_sheet)
    args.report.write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(reports)} achievement badge imagesets")


if __name__ == "__main__":
    main()
