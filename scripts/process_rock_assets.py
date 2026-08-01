#!/usr/bin/env python3
"""Build and validate DeepMine's generated clicker rock-art catalog."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts/imagegen/rock-assets-v1"
RAW = ARTIFACTS / "raw"
EXTRACTED = ARTIFACTS / "extracted"
PROCESSED = ARTIFACTS / "processed"
CATALOG = ROOT / "DeepMineProbe/Shared/SharedAssets.xcassets"
MANIFEST = ARTIFACTS / "manifest.json"
REPORT = ARTIFACTS / "validation-report.json"
CONTACT_SHEET = ARTIFACTS / "contact-sheet.png"
LOGICAL_SIZE = (64, 64)
PALETTE = (
    (16, 16, 15),
    (55, 54, 48),
    (231, 224, 207),
    (197, 140, 57),
)


def asset(asset_id: str, prompt_id: str, subject: str, *, transparent: bool = False) -> dict[str, object]:
    background = (
        "a uniform #00FF00 chroma-key background removed to binary transparency"
        if transparent
        else "a perfectly flat coal-black #10100F background"
    )
    prompt = (
        "A single DeepMine game art sprite, square, centered with generous padding, "
        f"on {background}. Chunky hand-placed pixel art with hard stair-step edges, "
        "flat 2D straight-on view, readable at 64x64. Use only coal black #10100F, "
        "shale grey #373630, limestone #E7E0CF, and sparse lamp brass #C58C39. "
        "No antialiasing, gradients, glow, soft shadows, text, watermark, UI chrome, "
        f"perspective, border, or other colors. Subject: {subject}"
    )
    return {
        "id": asset_id,
        "prompt_id": prompt_id,
        "prompt": prompt,
        "transparent": transparent,
    }


ASSETS: list[dict[str, object]] = []
ROCK_SUBJECTS = {
    "entry": [
        "an intact massive round layered sedimentary boulder with horizontal shale strata and a few limestone flecks",
        "the same layered boulder with thin upper cracks and one chipped corner exposing a small limestone patch",
        "the same layered boulder split by one deep crack with two large edge chunks missing and broad limestone fracture faces",
        "the same boulder collapsed into a low separated heap with wide limestone fracture faces and coal-black gaps",
    ],
    "crystal": [
        "an intact shale boulder with angular limestone crystals embedded and protruding, one crystal tipped with brass",
        "the same crystal boulder with cracks radiating from clusters and one chipped corner exposing crystal cross-sections",
        "the same crystal boulder split through a cluster with two large chunks missing and dense crystal fracture faces",
        "the same boulder collapsed into separated fragments and loose angular crystals, one crystal brass-tipped",
    ],
    "ruins": [
        "an intact worked masonry block with straight edges, a flat shale face, faint tool marks, and four brass rivets",
        "the same block cracked along a mortar line with one squared corner missing and one loose brass rivet",
        "the same block deeply fractured with two squared chunks missing, broad limestone faces, and two empty rivet holes",
        "the same block collapsed into squared rubble with limestone faces and one bent brass rivet on top",
    ],
    "abyss": [
        "an intact utterly smooth near-black boulder defined only by a thin limestone upper rim",
        "the same near-black boulder with thin void-black cracks and one missing corner exposing pale limestone",
        "the same near-black boulder split by a deep void with two chunks missing and bright limestone fracture faces",
        "the same boulder collapsed into separated near-black fragments with wide limestone faces and bottomless gaps",
    ],
}
for region, subjects in ROCK_SUBJECTS.items():
    for stage, subject in enumerate(subjects, start=1):
        ASSETS.append(asset(f"RockFace_{region}_stage{stage}", f"rockface-{region}-{stage}", subject))

ASSETS.extend(
    [
        asset("Fracture_light", "fracture-light", "one thin vertical jagged crack branching once, coal core with a one-pixel limestone edge", transparent=True),
        asset("Fracture_medium", "fracture-medium", "three jagged cracks radiating from one point and branching once, coal cores with one-pixel limestone edges", transparent=True),
        asset("Fracture_heavy", "fracture-heavy", "five heavily branched cracks radiating from a shattered center with a small coal-black hole", transparent=True),
        asset("WeakPoint_idle", "weakpoint-idle", "a thick brass targeting ring with four compass ticks and one small central brass dot"),
        asset("WeakPoint_hit", "weakpoint-hit", "a brass targeting ring broken outward into four arcs around a brass burst and limestone impact spikes"),
        asset("Debris_small", "debris-small", "three separated small angular shale chips with pale limestone fracture faces"),
        asset("Debris_large", "debris-large", "two separated large angular shale chunks and two small chips with broad limestone fracture faces"),
        asset("ResonanceNode", "resonance-node", "a faceted brass geode above a shale plinth with limestone highlights and three brass orbit rings"),
    ]
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def center_square(image: Image.Image) -> Image.Image:
    side = min(image.width, image.height)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def quantize_rgb(image: Image.Image, alpha: Image.Image, brass_limit: float) -> Image.Image:
    source = image.convert("RGB")
    pixels = list(source.get_flattened_data())
    alpha_pixels = list(alpha.get_flattened_data())
    assigned: list[tuple[int, int, int]] = []
    brass_candidates: list[tuple[int, int]] = []
    for index, pixel in enumerate(pixels):
        distances = [
            sum((pixel[channel] - color[channel]) ** 2 for channel in range(3))
            for color in PALETTE
        ]
        neutral = min(range(3), key=distances.__getitem__)
        assigned.append(PALETTE[neutral])
        if alpha_pixels[index] == 255:
            brass_candidates.append((distances[3] - distances[neutral], index))
    maximum = int(sum(value == 255 for value in alpha_pixels) * brass_limit)
    for score, index in sorted(brass_candidates)[:maximum]:
        if score < 0:
            assigned[index] = PALETTE[3]
    output = Image.new("RGB", source.size)
    output.putdata(assigned)
    return output


def process_asset(spec: dict[str, object]) -> dict[str, object]:
    asset_id = str(spec["id"])
    transparent = bool(spec["transparent"])
    raw_path = RAW / f"{asset_id}.png"
    source_path = EXTRACTED / f"{asset_id}.png" if transparent else raw_path
    if not raw_path.is_file() or not source_path.is_file():
        raise FileNotFoundError(f"{asset_id}: missing generated source")
    with Image.open(raw_path) as opened:
        if opened.format != "PNG":
            raise ValueError(f"{asset_id}: raw source is not PNG")
    with Image.open(source_path) as opened:
        source = center_square(opened.convert("RGBA")).resize(LOGICAL_SIZE, Image.Resampling.NEAREST)
    alpha = (
        source.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
        if transparent
        else Image.new("L", LOGICAL_SIZE, 255)
    )
    brass_limit = 0.45 if asset_id == "ResonanceNode" else 0.085
    rgb = quantize_rgb(source, alpha, brass_limit)
    logical = Image.merge("RGBA", (*rgb.split(), alpha)) if transparent else rgb

    PROCESSED.mkdir(parents=True, exist_ok=True)
    processed_path = PROCESSED / f"{asset_id}.png"
    logical.save(processed_path, format="PNG", optimize=True)
    imageset = CATALOG / f"{asset_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    stem = asset_id.replace("_", "-").lower()
    filenames = {1: f"{stem}.png", 2: f"{stem}@2x.png", 3: f"{stem}@3x.png"}
    for scale, filename in filenames.items():
        logical.resize((64 * scale, 64 * scale), Image.Resampling.NEAREST).save(imageset / filename, format="PNG", optimize=True)
    contents = {
        "images": [
            {"filename": filenames[scale], "idiom": "universal", "scale": f"{scale}x"}
            for scale in (1, 2, 3)
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"compression-type": "lossless", "template-rendering-intent": "original"},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    return {
        **spec,
        "raw_source": str(raw_path.relative_to(ROOT)),
        "raw_sha256": sha256(raw_path),
        "processed_source": str(processed_path.relative_to(ROOT)),
        "imageset": str(imageset.relative_to(ROOT)),
        "logical_size": list(LOGICAL_SIZE),
        "scales": [1, 2, 3],
    }


def validate_entry(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    imageset = ROOT / str(entry["imageset"])
    contents = json.loads((imageset / "Contents.json").read_text())
    if [item.get("scale") for item in contents["images"]] != ["1x", "2x", "3x"]:
        raise ValueError(f"{asset_id}: incomplete Contents.json scales")
    brass_ratios: list[float] = []
    for scale, item in zip((1, 2, 3), contents["images"]):
        path = imageset / item["filename"]
        with Image.open(path) as opened:
            if opened.format != "PNG" or opened.size != (64 * scale, 64 * scale):
                raise ValueError(f"{asset_id}: invalid PNG size at {scale}x")
            rgba = opened.convert("RGBA")
        pixels = list(rgba.get_flattened_data())
        opaque = [pixel for pixel in pixels if pixel[3] == 255]
        if any(pixel[3] not in (0, 255) for pixel in pixels):
            raise ValueError(f"{asset_id}: partial alpha is not allowed")
        if bool(entry["transparent"]):
            if not any(pixel[3] == 0 for pixel in pixels):
                raise ValueError(f"{asset_id}: transparent overlay lacks alpha")
        elif len(opaque) != len(pixels):
            raise ValueError(f"{asset_id}: opaque sprite contains transparency")
        if {pixel[:3] for pixel in opaque} - set(PALETTE):
            raise ValueError(f"{asset_id}: contains colors outside the four-pigment palette")
        brass_ratios.append(sum(pixel[:3] == PALETTE[3] for pixel in opaque) / max(1, len(opaque)))
    if asset_id != "ResonanceNode" and max(brass_ratios) >= 0.10:
        raise ValueError(f"{asset_id}: brass exceeds the 10% limit")
    return {"id": asset_id, "valid": True, "brass_ratio": brass_ratios[0]}


def make_contact_sheet(entries: list[dict[str, object]]) -> None:
    cell = 144
    columns = 4
    rows = (len(entries) + columns - 1) // columns
    sheet = Image.new("RGB", (cell * columns, cell * rows), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, entry in enumerate(entries):
        image = Image.open(ROOT / str(entry["processed_source"])).convert("RGBA")
        preview = image.resize((112, 112), Image.Resampling.NEAREST)
        x = (index % columns) * cell + 16
        y = (index // columns) * cell + 4
        sheet.paste(preview, (x, y), preview)
        draw.text((index % columns * cell + 4, y + 116), str(entry["id"]), fill=PALETTE[2], font=font)
    sheet.save(CONTACT_SHEET, format="PNG", optimize=True)


def validate_manifest(entries: list[dict[str, object]]) -> None:
    expected = [str(spec["id"]) for spec in ASSETS]
    if [str(entry["id"]) for entry in entries] != expected:
        raise ValueError("manifest IDs must match the 24-slot rock-art inventory")
    if len({str(entry["raw_sha256"]) for entry in entries}) != 24:
        raise ValueError("all 24 slots require distinct generated raw sources")
    for entry in entries:
        raw_path = ROOT / str(entry["raw_source"])
        if sha256(raw_path) != entry["raw_sha256"]:
            raise ValueError(f"{entry['id']}: raw source SHA no longer matches manifest")
        if not str(entry.get("prompt", "")).strip():
            raise ValueError(f"{entry['id']}: prompt provenance is missing")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if args.validate_only:
        entries = json.loads(MANIFEST.read_text())
    else:
        entries = [process_asset(spec) for spec in ASSETS]
        MANIFEST.write_text(json.dumps(entries, indent=2) + "\n")
        make_contact_sheet(entries)
    if len(entries) != 24:
        raise ValueError("manifest must contain exactly 24 entries")
    validate_manifest(entries)
    reports = [validate_entry(entry) for entry in entries]
    REPORT.write_text(json.dumps(reports, indent=2) + "\n")
    print(f"Validated {len(reports)} PNG rock-art imagesets")


if __name__ == "__main__":
    main()
