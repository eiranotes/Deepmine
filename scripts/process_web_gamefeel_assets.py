#!/usr/bin/env python3
"""Process and validate the web-first mining-action ImageGen assets."""

from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from shaft_asset_contract import PALETTE, ROOT


ARTIFACTS = ROOT / "artifacts/imagegen/web-gamefeel-v1"
RAW = ARTIFACTS / "raw"
EXTRACTED = ARTIFACTS / "extracted"
PROCESSED = ARTIFACTS / "processed"
WEB = ROOT / "web/public/assets/shaft"
# D-055 held these two out of the app catalog until the web feel was approved. The port
# is now underway, so the same processed pixels ship to both surfaces from one source.
CATALOG = ROOT / "DeepMineProbe/Shared/SharedAssets.xcassets"
MANIFEST = ARTIFACTS / "manifest.json"
REPORT = ARTIFACTS / "validation-report.json"
CONTACT_SHEET = ARTIFACTS / "contact-sheet.png"

ASSETS = (
    {
        "id": "MinerMiningStrip",
        "logical_size": (384, 96),
        "crop_ratio": 4.0,
        "frame_count": 4,
        "maximum_brass_ratio": 0.24,
        "prompt_id": "miner-mining-strip",
        "prompt": (
            "Four equal side-view frames of the same DeepMine miner: ready, "
            "anticipation, full-body impact, and recoil. The pickaxe stays in both "
            "hands in every frame; identical baseline and scale; four-pigment pixel "
            "art on a perfectly flat #00FF00 chroma-key background."
        ),
    },
    {
        "id": "ShaftFrontierLip",
        "logical_size": (320, 128),
        "crop_ratio": 2.5,
        "frame_count": 1,
        "maximum_brass_ratio": 0.12,
        "prompt_id": "shaft-frontier-lip",
        "prompt": (
            "Panoramic front-facing rock shoulders forming one jagged U-shaped "
            "tunnel throat, with an empty upper centre and a chipped contact notch "
            "at the bottom centre; connected strata in the DeepMine four-pigment "
            "pixel style on a flat #00FF00 chroma-key background."
        ),
    },
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def crop_to_ratio(image: Image.Image, target_ratio: float) -> Image.Image:
    source_ratio = image.width / image.height
    if source_ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        return image.crop((left, 0, left + width, image.height))
    height = round(image.width / target_ratio)
    top = (image.height - height) // 2
    return image.crop((0, top, image.width, top + height))


def quantize(source: Image.Image) -> Image.Image:
    output = Image.new("RGBA", source.size)
    pixels: list[tuple[int, int, int, int]] = []
    for red, green, blue, alpha in source.getdata():
        if alpha < 128:
            pixels.append((*PALETTE[0], 0))
            continue
        color = min(
            PALETTE,
            key=lambda pigment: sum(
                (channel - target) ** 2
                for channel, target in zip((red, green, blue), pigment)
            ),
        )
        pixels.append((*color, 255))
    output.putdata(pixels)
    return output


def process(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    raw = RAW / f"{asset_id}.png"
    extracted = EXTRACTED / f"{asset_id}.png"
    if not raw.exists() or not extracted.exists():
        raise FileNotFoundError(f"{asset_id}: raw and chroma-extracted PNGs are required")

    size = tuple(entry["logical_size"])
    with Image.open(extracted) as opened:
        cropped = crop_to_ratio(opened.convert("RGBA"), float(entry["crop_ratio"]))
        logical = quantize(cropped.resize(size, Image.Resampling.NEAREST))

    PROCESSED.mkdir(parents=True, exist_ok=True)
    WEB.mkdir(parents=True, exist_ok=True)
    processed = PROCESSED / f"{asset_id}.png"
    web = WEB / f"{asset_id}.png"
    logical.save(processed, format="PNG", optimize=True)
    shutil.copy2(processed, web)

    imageset = CATALOG / f"{asset_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    stem = asset_id.replace("_", "-").lower()
    filenames = {scale: f"{stem}{'' if scale == 1 else f'@{scale}x'}.png" for scale in (1, 2, 3)}
    for scale, filename in filenames.items():
        logical.resize(
            (size[0] * scale, size[1] * scale),
            Image.Resampling.NEAREST,
        ).save(imageset / filename, format="PNG", optimize=True)
    (imageset / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"filename": filenames[scale], "idiom": "universal", "scale": f"{scale}x"}
                    for scale in (1, 2, 3)
                ],
                "info": {"author": "xcode", "version": 1},
                "properties": {
                    "compression-type": "lossless",
                    "template-rendering-intent": "original",
                },
            },
            indent=2,
        )
        + "\n"
    )

    return {
        **entry,
        "logical_size": list(size),
        "raw_source": str(raw.relative_to(ROOT)),
        "raw_sha256": sha256(raw),
        "extracted_source": str(extracted.relative_to(ROOT)),
        "processed_source": str(processed.relative_to(ROOT)),
        "web_source": str(web.relative_to(ROOT)),
        "imageset": str(imageset.relative_to(ROOT)),
        "scales": [1, 2, 3],
    }


def validate(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    raw = ROOT / str(entry["raw_source"])
    if sha256(raw) != entry["raw_sha256"]:
        raise ValueError(f"{asset_id}: raw source hash changed")

    processed = ROOT / str(entry["processed_source"])
    web = ROOT / str(entry["web_source"])
    with Image.open(processed) as opened:
        if opened.format != "PNG" or opened.size != tuple(entry["logical_size"]):
            raise ValueError(f"{asset_id}: invalid format or logical size")
        rgba = opened.convert("RGBA")
    if sha256(processed) != sha256(web):
        raise ValueError(f"{asset_id}: web copy differs from processed source")

    pixels = list(rgba.getdata())
    if any(pixel[3] not in (0, 255) for pixel in pixels):
        raise ValueError(f"{asset_id}: partial alpha is not allowed")
    if not any(pixel[3] == 0 for pixel in pixels):
        raise ValueError(f"{asset_id}: transparent background is missing")
    opaque = [pixel for pixel in pixels if pixel[3] == 255]
    if {pixel[:3] for pixel in opaque} - set(PALETTE):
        raise ValueError(f"{asset_id}: color outside the four-pigment palette")
    brass_ratio = sum(pixel[:3] == PALETTE[3] for pixel in opaque) / max(1, len(opaque))
    if brass_ratio >= float(entry["maximum_brass_ratio"]):
        raise ValueError(f"{asset_id}: brass exceeds its declared limit")

    frame_count = int(entry["frame_count"])
    frame_width = rgba.width // frame_count
    frame_coverage = []
    for frame in range(frame_count):
        alpha = rgba.getchannel("A").crop((frame * frame_width, 0, (frame + 1) * frame_width, rgba.height))
        coverage = sum(value == 255 for value in alpha.getdata())
        if coverage == 0:
            raise ValueError(f"{asset_id}: frame {frame + 1} is empty")
        frame_coverage.append(coverage)

    # The app catalog copy has to be the same pixels at every scale, or the two surfaces
    # would drift apart exactly where the port is supposed to make them agree.
    imageset = ROOT / str(entry["imageset"])
    contents = json.loads((imageset / "Contents.json").read_text())
    logical_size = tuple(entry["logical_size"])
    for scale, item in zip((1, 2, 3), contents["images"]):
        path = imageset / item["filename"]
        with Image.open(path) as opened:
            expected = (logical_size[0] * scale, logical_size[1] * scale)
            if opened.format != "PNG" or opened.size != expected:
                raise ValueError(f"{asset_id}: invalid imageset PNG size at {scale}x")
            scaled = opened.convert("RGBA")
        scaled_pixels = list(scaled.getdata())
        if any(pixel[3] not in (0, 255) for pixel in scaled_pixels):
            raise ValueError(f"{asset_id}: imageset {scale}x has partial alpha")
        scaled_opaque = [pixel for pixel in scaled_pixels if pixel[3] == 255]
        if {pixel[:3] for pixel in scaled_opaque} - set(PALETTE):
            raise ValueError(f"{asset_id}: imageset {scale}x leaves the four-pigment palette")
    if sha256(imageset / contents["images"][0]["filename"]) != sha256(processed):
        raise ValueError(f"{asset_id}: imageset 1x differs from the processed source")

    return {
        "id": asset_id,
        "valid": True,
        "brass_ratio": brass_ratio,
        "frame_coverage": frame_coverage,
        "imageset": str(imageset.relative_to(ROOT)),
    }


def make_contact_sheet(entries: list[dict[str, object]]) -> None:
    width = max(int(entry["logical_size"][0]) for entry in entries)
    label_height = 24
    height = sum(int(entry["logical_size"][1]) + label_height for entry in entries)
    sheet = Image.new("RGB", (width, height), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    y = 0
    for entry in entries:
        art = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        sheet.paste(art, ((width - art.width) // 2, y), art)
        y += art.height
        draw.text((8, y + 6), str(entry["id"]), fill=PALETTE[2], font=font)
        y += label_height
    sheet.save(CONTACT_SHEET, format="PNG", optimize=True)


def main() -> None:
    entries = [process(entry) for entry in ASSETS]
    MANIFEST.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n")
    reports = [validate(entry) for entry in entries]
    REPORT.write_text(json.dumps(reports, indent=2) + "\n")
    make_contact_sheet(entries)
    print(f"Validated {len(reports)} web game-feel assets")


if __name__ == "__main__":
    main()
