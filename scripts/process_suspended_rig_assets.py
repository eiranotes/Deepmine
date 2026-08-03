#!/usr/bin/env python3
"""Build and validate DeepMine's generated suspended-rig asset pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from shaft_asset_contract import PALETTE, ROOT


ARTIFACTS = ROOT / "artifacts/imagegen/suspended-rig-v1"
RAW = ARTIFACTS / "raw"
EXTRACTED = ARTIFACTS / "extracted"
PROCESSED = ARTIFACTS / "processed"
WEB = ROOT / "web/public/assets/rig"
CATALOG = ROOT / "DeepMineProbe/Shared/SharedAssets.xcassets"
MANIFEST = ARTIFACTS / "manifest.json"
REPORT = ARTIFACTS / "validation-report.json"
CONTACT_SHEET = ARTIFACTS / "contact-sheet.png"

PROMPT_RIG = (
    "Front-facing suspended underground mining rig chassis with two hoist cables, "
    "guide-rail clamps, a riveted crossbeam, operator bay, ore chute and a clear "
    "central tool socket; premium chunky 16-bit DeepMine pixel art on flat chroma key."
)
PROMPT_DRILLS = (
    "Three equal front-facing rig tools with a shared mount: reciprocating chisel, "
    "hydraulic piston hammer and twin rotary cutter; increasingly heavy silhouettes."
)
PROMPT_BRANCHES = (
    "Six equal specialization modules: wide double chisel, impact accumulator, fleet "
    "rail coupling, freight hopper, reach reflector and fortune scanning lens."
)
PROMPT_HOUSINGS = (
    "Four front-facing generation housings for the same rig socket: compact chassis, "
    "wide ribbed chassis, tall side-pod chassis and heavy shock-armored chassis; "
    "four unmistakably different silhouettes that remain readable at 64 pixels."
)

ASSETS = (
    {
        "id": "SuspendedRigFrame",
        "raw": "SuspendedRigFrame",
        "source_frames": 1,
        "frame": 0,
        "logical_size": (320, 128),
        "maximum_brass_ratio": 0.18,
        "prompt_id": "suspended-rig-frame",
        "prompt": PROMPT_RIG,
    },
    *(
        {
            "id": f"RigDrill_tier{tier}",
            "raw": "RigDrillTierStrip",
            "source_frames": 3,
            "frame": tier - 1,
            "logical_size": (96, 96),
            "maximum_brass_ratio": 0.22,
            "prompt_id": f"rig-drill-tier-{tier}",
            "prompt": PROMPT_DRILLS,
        }
        for tier in range(1, 4)
    ),
    *(
        {
            "id": asset_id,
            "raw": "RigSpecializationStrip",
            "source_frames": 6,
            "frame": frame,
            "logical_size": (64, 64),
            "maximum_brass_ratio": 0.28,
            "prompt_id": prompt_id,
            "prompt": PROMPT_BRANCHES,
        }
        for frame, (asset_id, prompt_id) in enumerate((
            ("RigModification_drillWide", "rig-modification-drill-wide"),
            ("RigModification_drillImpact", "rig-modification-drill-impact"),
            ("RigModification_cartFleet", "rig-modification-cart-fleet"),
            ("RigModification_cartFreight", "rig-modification-cart-freight"),
            ("RigModification_lampReach", "rig-modification-lamp-reach"),
            ("RigModification_lampFortune", "rig-modification-lamp-fortune"),
        ))
    ),
    *(
        {
            "id": f"RigHousing_generation{variant}",
            "raw": "RigHousingGenerationStrip",
            "source_frames": 4,
            "frame": variant - 1,
            "logical_size": (80, 80),
            "maximum_brass_ratio": 0.30,
            "prompt_id": f"rig-housing-generation-{variant}",
            "prompt": PROMPT_HOUSINGS,
        }
        for variant in range(1, 5)
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def crop_to_ratio(image: Image.Image, ratio: float) -> Image.Image:
    source_ratio = image.width / image.height
    if source_ratio > ratio:
        width = round(image.height * ratio)
        left = (image.width - width) // 2
        return image.crop((left, 0, left + width, image.height))
    height = round(image.width / ratio)
    top = (image.height - height) // 2
    return image.crop((0, top, image.width, top + height))


def select_frame(source: Image.Image, count: int, index: int) -> Image.Image:
    if count == 1:
        return crop_to_ratio(source, 2.5)
    left = round(source.width * index / count)
    right = round(source.width * (index + 1) / count)
    return crop_to_ratio(source.crop((left, 0, right, source.height)), 1.0)


def extract_chroma(raw_path: Path, extracted_path: Path) -> None:
    with Image.open(raw_path) as opened:
        source = opened.convert("RGBA")
    pixels = []
    for red, green, blue, _ in source.get_flattened_data():
        is_green = green > 120 and green - max(red, blue) > 55
        pixels.append((red, green, blue, 0 if is_green else 255))
    extracted = Image.new("RGBA", source.size)
    extracted.putdata(pixels)
    EXTRACTED.mkdir(parents=True, exist_ok=True)
    extracted.save(extracted_path, format="PNG", optimize=True)


def quantize(source: Image.Image) -> Image.Image:
    output = Image.new("RGBA", source.size)
    pixels = []
    for red, green, blue, alpha in source.get_flattened_data():
        if alpha < 128:
            pixels.append((*PALETTE[0], 0))
            continue
        pixel = (red, green, blue)
        pigment = min(
            PALETTE,
            key=lambda target: sum(
                (channel - target_channel) ** 2
                for channel, target_channel in zip(pixel, target)
            ),
        )
        pixels.append((*pigment, 255))
    output.putdata(pixels)
    return output


def process(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    raw = RAW / f"{entry['raw']}.png"
    extracted = EXTRACTED / f"{entry['raw']}.png"
    if not raw.exists():
        raise FileNotFoundError(f"{asset_id}: raw source is required")
    if not extracted.exists():
        extract_chroma(raw, extracted)

    logical_size = tuple(entry["logical_size"])
    with Image.open(extracted) as opened:
        frame = select_frame(
            opened.convert("RGBA"),
            int(entry["source_frames"]),
            int(entry["frame"]),
        )
        logical = quantize(frame.resize(logical_size, Image.Resampling.LANCZOS))

    PROCESSED.mkdir(parents=True, exist_ok=True)
    WEB.mkdir(parents=True, exist_ok=True)
    processed = PROCESSED / f"{asset_id}.png"
    web = WEB / f"{asset_id}.png"
    logical.save(processed, format="PNG", optimize=True)
    shutil.copy2(processed, web)

    imageset = CATALOG / f"{asset_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    stem = asset_id.replace("_", "-").lower()
    filenames = {
        scale: f"{stem}{'' if scale == 1 else f'@{scale}x'}.png"
        for scale in (1, 2, 3)
    }
    for scale, filename in filenames.items():
        logical.resize(
            (logical_size[0] * scale, logical_size[1] * scale),
            Image.Resampling.NEAREST,
        ).save(imageset / filename, format="PNG", optimize=True)
    (imageset / "Contents.json").write_text(json.dumps({
        "images": [
            {"filename": filenames[scale], "idiom": "universal", "scale": f"{scale}x"}
            for scale in (1, 2, 3)
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "compression-type": "lossless",
            "template-rendering-intent": "original",
        },
    }, indent=2) + "\n")

    return {
        **entry,
        "logical_size": list(logical_size),
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
            raise ValueError(f"{asset_id}: invalid format or size")
        rgba = opened.convert("RGBA")
    if sha256(processed) != sha256(web):
        raise ValueError(f"{asset_id}: web copy differs")

    pixels = list(rgba.get_flattened_data())
    if any(pixel[3] not in (0, 255) for pixel in pixels):
        raise ValueError(f"{asset_id}: partial alpha is not allowed")
    opaque = [pixel for pixel in pixels if pixel[3] == 255]
    if not opaque or len(opaque) == len(pixels):
        raise ValueError(f"{asset_id}: invalid subject coverage")
    if {pixel[:3] for pixel in opaque} - set(PALETTE):
        raise ValueError(f"{asset_id}: color outside four-pigment palette")
    coverage = len(opaque) / len(pixels)
    if not 0.035 <= coverage <= 0.82:
        raise ValueError(f"{asset_id}: implausible coverage {coverage:.3f}")
    brass_ratio = sum(pixel[:3] == PALETTE[3] for pixel in opaque) / len(opaque)
    if brass_ratio >= float(entry["maximum_brass_ratio"]):
        raise ValueError(f"{asset_id}: brass exceeds declared limit")

    imageset = ROOT / str(entry["imageset"])
    contents = json.loads((imageset / "Contents.json").read_text())
    logical_size = tuple(entry["logical_size"])
    for scale, item in zip((1, 2, 3), contents["images"]):
        path = imageset / item["filename"]
        with Image.open(path) as opened:
            expected = (logical_size[0] * scale, logical_size[1] * scale)
            if opened.format != "PNG" or opened.size != expected:
                raise ValueError(f"{asset_id}: invalid imageset at {scale}x")
    return {
        "id": asset_id,
        "valid": True,
        "coverage": coverage,
        "brass_ratio": brass_ratio,
    }


def make_contact_sheet(entries: list[dict[str, object]]) -> None:
    sheet = Image.new("RGB", (640, 600), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    rig = Image.open(ROOT / str(entries[0]["processed_source"])).convert("RGBA")
    sheet.paste(rig, (160, 8), rig)
    draw.text((12, 142), "SuspendedRigFrame", fill=PALETTE[2], font=font)
    for index, entry in enumerate(entries[1:4]):
        art = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        x = 88 + index * 184
        sheet.paste(art, (x, 168), art)
        draw.text((x, 268), str(entry["id"]), fill=PALETTE[2], font=font)
    for index, entry in enumerate(entries[4:10]):
        art = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        x = 22 + (index % 6) * 102
        sheet.paste(art, (x, 326), art)
        draw.text((x, 396), str(entry["id"]).replace("RigModification_", ""), fill=PALETTE[2], font=font)
    for index, entry in enumerate(entries[10:]):
        art = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        x = 68 + index * 142
        sheet.paste(art, (x, 438), art)
        draw.text((x, 524), f"Housing G{index + 1}", fill=PALETTE[2], font=font)
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_SHEET, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if args.validate_only:
        entries = json.loads(MANIFEST.read_text())
    else:
        entries = [process(entry) for entry in ASSETS]
        MANIFEST.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n")
        make_contact_sheet(entries)
    reports = [validate(entry) for entry in entries]
    REPORT.write_text(json.dumps(reports, indent=2) + "\n")
    print(f"Validated {len(reports)} suspended-rig assets")


if __name__ == "__main__":
    main()
