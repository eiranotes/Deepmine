#!/usr/bin/env python3
"""Build and validate DeepMine's generated shaft-scene asset catalog."""

from __future__ import annotations

import argparse
import hashlib
import json

from PIL import Image, ImageDraw, ImageFont

from shaft_asset_contract import (
    ARTIFACTS, ASSETS, CATALOG, CONTACT_SHEET, EXTRACTED, MANIFEST, PALETTE,
    PROCESSED, RAW, REPORT, ROOT,
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def quantized_pixels(
    source: Image.Image,
    *,
    transparent: bool,
    brass_limit: float,
) -> list[tuple[int, int, int, int]]:
    source_pixels = list(source.get_flattened_data())
    output: list[tuple[int, int, int, int]] = []
    brass_candidates: list[tuple[int, int]] = []
    opaque_count = 0
    for index, (red, green, blue, alpha) in enumerate(source_pixels):
        if transparent and alpha < 128:
            output.append((*PALETTE[0], 0))
            continue
        pixel = (red, green, blue)
        neutral_distances = [
            sum((channel - target) ** 2 for channel, target in zip(pixel, pigment))
            for pigment in PALETTE[:3]
        ]
        neutral = min(range(3), key=neutral_distances.__getitem__)
        output.append((*PALETTE[neutral], 255))
        brass_distance = sum(
            (channel - target) ** 2 for channel, target in zip(pixel, PALETTE[3])
        )
        brass_candidates.append((brass_distance - neutral_distances[neutral], index))
        opaque_count += 1
    maximum = int(opaque_count * brass_limit * 0.95)
    for score, index in sorted(brass_candidates)[:maximum]:
        if score < 0:
            output[index] = (*PALETTE[3], 255)
    return output


def crop_to_ratio(
    image: Image.Image,
    target: tuple[int, int],
    anchor: str,
) -> Image.Image:
    target_ratio = target[0] / target[1]
    source_ratio = image.width / image.height
    if source_ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        return image.crop((left, 0, left + width, image.height))
    height = round(image.width / target_ratio)
    top = 0 if anchor == "top" else (image.height - height) // 2
    return image.crop((0, top, image.width, top + height))


def extract_chroma(raw_path: Path, extracted_path: Path) -> None:
    with Image.open(raw_path) as opened:
        source = opened.convert("RGBA")
    pixels: list[tuple[int, int, int, int]] = []
    for red, green, blue, _ in source.get_flattened_data():
        is_green = green > 120 and green - max(red, blue) > 55
        pixels.append((red, green, blue, 0 if is_green else 255))
    extracted = Image.new("RGBA", source.size)
    extracted.putdata(pixels)
    EXTRACTED.mkdir(parents=True, exist_ok=True)
    extracted.save(extracted_path, format="PNG", optimize=True)


def process_asset(asset: dict[str, object]) -> dict[str, object]:
    asset_id = str(asset["id"])
    transparent = bool(asset["transparent"])
    logical_size = tuple(asset["logical_size"])
    raw_path = RAW / f"{asset_id}.png"
    if not raw_path.exists():
        raise FileNotFoundError(f"{asset_id}: generated raw source is required")

    extracted_path = EXTRACTED / f"{asset_id}.png"
    if transparent and not extracted_path.exists():
        extract_chroma(raw_path, extracted_path)
    source_path = extracted_path if transparent else raw_path
    with Image.open(source_path) as opened:
        source = crop_to_ratio(
            opened.convert("RGBA"),
            logical_size,
            str(asset["crop_anchor"]),
        ).resize(logical_size, Image.Resampling.NEAREST)

    logical = Image.new("RGBA", logical_size)
    logical.putdata(quantized_pixels(
        source,
        transparent=transparent,
        brass_limit=float(asset["maximum_brass_ratio"]),
    ))

    PROCESSED.mkdir(parents=True, exist_ok=True)
    processed_path = PROCESSED / f"{asset_id}.png"
    logical.save(processed_path, format="PNG", optimize=True)
    imageset = CATALOG / f"{asset_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    stem = asset_id.replace("_", "-").lower()
    filenames = {1: f"{stem}.png", 2: f"{stem}@2x.png", 3: f"{stem}@3x.png"}
    for scale, filename in filenames.items():
        logical.resize(
            (logical_size[0] * scale, logical_size[1] * scale),
            Image.Resampling.NEAREST,
        ).save(imageset / filename, format="PNG", optimize=True)
    contents = {
        "images": [
            {"filename": filenames[scale], "idiom": "universal", "scale": f"{scale}x"}
            for scale in (1, 2, 3)
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"compression-type": "lossless", "template-rendering-intent": "original"},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    result = {
        **asset,
        "logical_size": list(logical_size),
        "raw_source": str(raw_path.relative_to(ROOT)),
        "raw_sha256": sha256(raw_path),
        "processed_source": str(processed_path.relative_to(ROOT)),
        "imageset": str(imageset.relative_to(ROOT)),
        "scales": [1, 2, 3],
    }
    if transparent:
        result["extracted_source"] = str(extracted_path.relative_to(ROOT))
    return result


def validate_entry(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    raw_path = ROOT / str(entry["raw_source"])
    if sha256(raw_path) != entry["raw_sha256"]:
        raise ValueError(f"{asset_id}: raw source SHA does not match the manifest")
    logical_size = tuple(entry["logical_size"])
    imageset = ROOT / str(entry["imageset"])
    contents = json.loads((imageset / "Contents.json").read_text())
    brass_ratios: list[float] = []
    for scale, item in zip((1, 2, 3), contents["images"]):
        path = imageset / item["filename"]
        with Image.open(path) as opened:
            expected = (logical_size[0] * scale, logical_size[1] * scale)
            if opened.format != "PNG" or opened.size != expected:
                raise ValueError(f"{asset_id}: invalid PNG size at {scale}x")
            rgba = opened.convert("RGBA")
        pixels = list(rgba.get_flattened_data())
        if any(pixel[3] not in (0, 255) for pixel in pixels):
            raise ValueError(f"{asset_id}: partial alpha is not allowed")
        opaque = [pixel for pixel in pixels if pixel[3] == 255]
        if bool(entry["transparent"]):
            if not any(pixel[3] == 0 for pixel in pixels):
                raise ValueError(f"{asset_id}: transparent overlay lacks alpha")
        elif len(opaque) != len(pixels):
            raise ValueError(f"{asset_id}: opaque texture contains transparency")
        if {pixel[:3] for pixel in opaque} - set(PALETTE):
            raise ValueError(f"{asset_id}: contains colors outside the four-pigment palette")
        brass_ratios.append(
            sum(pixel[:3] == PALETTE[3] for pixel in opaque) / max(1, len(opaque))
        )
    if max(brass_ratios) >= float(entry["maximum_brass_ratio"]):
        raise ValueError(f"{asset_id}: brass exceeds its declared limit")
    return {"id": asset_id, "valid": True, "brass_ratio": brass_ratios[0]}


def make_contact_sheet(entries: list[dict[str, object]]) -> None:
    label_height = 26
    total_height = sum(int(entry["logical_size"][1]) + label_height for entry in entries)
    sheet = Image.new("RGB", (320, total_height), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    y = 0
    for entry in entries:
        art = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        sheet.paste(art, (0, y), art)
        y += art.height
        draw.text((8, y + 7), str(entry["id"]), fill=PALETTE[2], font=font)
        y += label_height
    sheet.save(CONTACT_SHEET, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if args.validate_only:
        entries = json.loads(MANIFEST.read_text())
    else:
        entries = [process_asset(asset) for asset in ASSETS]
        MANIFEST.write_text(json.dumps(entries, indent=2) + "\n")
        make_contact_sheet(entries)
    expected = [str(asset["id"]) for asset in ASSETS]
    if [str(entry["id"]) for entry in entries] != expected:
        raise ValueError("manifest IDs must match the seven-slot shaft-art inventory")
    if len({str(entry["raw_sha256"]) for entry in entries}) != len(ASSETS):
        raise ValueError("every shaft slot requires a distinct generated raw source")
    reports = [validate_entry(entry) for entry in entries]
    REPORT.write_text(json.dumps(reports, indent=2) + "\n")
    print(f"Validated {len(reports)} PNG shaft-art imagesets")


if __name__ == "__main__":
    main()
