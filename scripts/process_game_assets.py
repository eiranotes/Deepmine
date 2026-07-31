#!/usr/bin/env python3
"""Build and validate DeepMine's generated PNG game-art catalog."""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts/imagegen/game-assets-v1"
RAW = ARTIFACTS / "raw"
EXTRACTED = ARTIFACTS / "extracted"
PROCESSED = ARTIFACTS / "processed"
CATALOG = ROOT / "DeepMineProbe/Shared/SharedAssets.xcassets"
MANIFEST = ARTIFACTS / "manifest.json"
REPORT = ARTIFACTS / "validation-report.json"
PALETTE = (
    (16, 16, 15),     # coal
    (55, 54, 48),     # shale
    (231, 224, 207),  # limestone
    (197, 140, 57),   # brass
)
BRASS_LIMIT = 0.10


@dataclass(frozen=True)
class Family:
    logical_size: tuple[int, int]
    transparent: bool
    crop: str


FAMILIES = {
    "icon": Family((32, 32), False, "square"),
    "miner": Family((24, 24), True, "alpha-fit"),
    "decoration": Family((32, 32), True, "alpha-fit"),
    "onboarding": Family((96, 96), False, "square"),
    "theme": Family((192, 108), False, "center"),
    "di": Family((192, 72), False, "center"),
    "standby": Family((256, 144), False, "center"),
}


COMMON_ICON_PROMPT = (
    "Square canvas, centered with generous padding. Chunky 16-bit pixel-art "
    "game asset, hard stair-step edges, no antialiasing, no gradients, no glow, "
    "no soft shadow, no text, no letters, no numbers, no border, no UI frame. "
    "Use only the visual roles of coal black #10100F, shale gray #373630, "
    "limestone #E7E0CF, and a tiny lamp-brass highlight #C58C39 under 10% of "
    "pixels. Strong grayscale readability. PNG output."
)
COMMON_SCENE_PROMPT = (
    "Chunky 16-bit pixel-art environment, strict hard stair-step edges, no "
    "antialiasing, no gradients, no glow, no soft shadow, no text, no letters, "
    "no numbers, no border, no UI frame. Use only the visual roles of coal black "
    "#10100F, shale gray #373630, limestone #E7E0CF, and sparse lamp-brass "
    "#C58C39 under 10% of scene pixels. Strong grayscale and red-monochrome "
    "readability. Opaque PNG output."
)


def entry(asset_id: str, family: str, subject: str, *, chroma: bool = False) -> dict[str, str]:
    backdrop = (
        "Subject fully isolated on a perfectly flat solid #00FF00 chroma-key "
        "background, uniform green edge to edge, with no green in the subject. "
        if chroma
        else "Perfectly flat solid coal-black background #10100F. "
    )
    return {
        "id": asset_id,
        "family": family,
        "prompt": f"Create one finished DeepMine asset depicting {subject}. {backdrop}{COMMON_ICON_PROMPT}",
    }


ASSETS = [
    entry("Vein_blue", "icon", "a compact cluster of three angular ore crystals representing the Blue Vein"),
    entry("Vein_crystal", "icon", "a single faceted crystal gemstone with two small shards"),
    entry("Vein_vault", "icon", "a compact ancient locked mine chest with brass corner fittings"),
    entry("Vein_resonance", "icon", "three concentric angular resonance rings around a tiny central stone"),
    entry("Vein_abyss", "icon", "a jagged vertical abyss fissure in a rock slab"),
    *[
        entry(
            f"Equipment_{kind}_tier{tier}",
            "icon",
            subject,
        )
        for kind, tier, subject in [
            ("drill", 1, "a basic hand-powered mine drill with one short bit and a simple handle"),
            ("drill", 2, "an upgraded mechanical mine drill with a longer bit and one visible gear"),
            ("drill", 3, "an advanced heavy mine drill with a reinforced triple-section bit and two compact gears"),
            ("cart", 1, "a basic small mine cart with one bin and two simple wheels"),
            ("cart", 2, "an upgraded reinforced mine cart with a larger bin, metal rim, and four visible wheels"),
            ("cart", 3, "an advanced armored mine cart with a segmented bin, reinforced axle, and six compact wheels"),
            ("lamp", 1, "a basic handheld mining lantern with one small lens and simple handle"),
            ("lamp", 2, "an upgraded mining lantern with a larger lens cage and side reflector"),
            ("lamp", 3, "an advanced heavy mining lantern with a triple-facet lens and reinforced cage"),
        ]
    ],
    *[
        entry(f"Decoration_{name}", "decoration", subject, chroma=True)
        for name, subject in [
            ("marker", "a compact underground depth marker signpost made of stone and one brass nail"),
            ("rail", "a short horizontal mine rail segment with two sleepers"),
            ("lamp", "a small hanging mine lamp with a hard-edged metal shade"),
            ("cart", "a small empty parked mine cart in side view"),
        ]
    ],
    entry("MinerPlan_deep", "miner", "a compact crouched deep-plan miner with helmet lamp and short diagonal pickaxe", chroma=True),
    entry("MinerPlan_survey", "miner", "an upright survey-plan miner holding a small lantern forward", chroma=True),
    entry("Resource_ore", "icon", "a compact pile of three rough ore rocks"),
    entry("Resource_crystal", "icon", "a compact single cut crystal with two small facets"),
    entry("Resource_coreShard", "icon", "a rare angular core shard split by one bright central seam"),
    entry("PermanentUpgrade_excavationMemory", "icon", "a miner helmet merged with a layered memory tablet"),
    entry("PermanentUpgrade_resonanceDetection", "icon", "an angular tuning fork over a small crystal"),
    entry("PermanentUpgrade_compressedTime", "icon", "an hourglass pressed between two stone plates"),
    entry("Onboarding_blocks", "onboarding", "a miniature mine wall made from four stacked focus blocks"),
    entry("Onboarding_sessions", "onboarding", "a tiny miner walking through three sequential tunnel chambers"),
]


REGION_SUBJECTS = {
    "entry": "plain layered rock, two timber supports, a distant dormant shaft, and one tiny lamp",
    "crystal": "angular pale crystal geology embedded in dark shale, squared braces, and a dormant shaft",
    "ruins": "buried stone machinery, broken gear silhouettes, ancient pillars, and a dormant shaft",
    "abyss": "an immense near-black void, sparse pale cliff edges, tiny depth markers, and a dormant shaft",
}

for region, subject in REGION_SUBJECTS.items():
    ASSETS.append({
        "id": f"ThemeScene_{region}",
        "family": "theme",
        "prompt": (
            f"Create one finished DeepMine {region} theme background: {subject}. "
            "Compose useful art as a wide 16:9 scene across the middle of a square "
            "source canvas for center cropping. Keep central and lower foreground "
            "quiet for UI. No miner, rare vein, treasure, or reward reveal. "
            + COMMON_SCENE_PROMPT
        ),
    })
    ASSETS.append({
        "id": f"DIBanner_{region}",
        "family": "di",
        "prompt": (
            f"Create one finished DeepMine Dynamic Island banner: {subject}. "
            "Compose useful art as an ultrawide 8:3 scene across the middle of a "
            "square source canvas. Keep the top-center 36% width and top 45% height "
            "coal-black and empty. No miner, active vein, treasure, or reward. "
            + COMMON_SCENE_PROMPT
        ),
    })
    ASSETS.append({
        "id": f"StandBy_{region}",
        "family": "standby",
        "prompt": (
            f"Create one finished DeepMine StandBy background: {subject}. Compose "
            "useful art as a wide 16:9 scene across the middle of a square source "
            "canvas. Keep the left third low-detail coal-black and the right quarter "
            "subdued for UI. No miner, active vein, treasure, or reward. "
            + COMMON_SCENE_PROMPT
        ),
    })


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def crop_center(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    target_ratio = target[0] / target[1]
    ratio = image.width / image.height
    if ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        return image.crop((left, 0, left + width, image.height))
    height = round(image.width / target_ratio)
    top = (image.height - height) // 2
    return image.crop((0, top, image.width, top + height))


def alpha_fit(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("transparent source has no opaque subject")
    subject = rgba.crop(bbox)
    max_width = max(1, round(target[0] * 0.82))
    max_height = max(1, round(target[1] * 0.82))
    subject.thumbnail((max_width, max_height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", target, (0, 0, 0, 0))
    canvas.alpha_composite(subject, ((target[0] - subject.width) // 2, (target[1] - subject.height) // 2))
    return canvas


def quantize_rgb(rgb: Image.Image, alpha: Image.Image | None = None) -> Image.Image:
    source = rgb.convert("RGB")
    pixels = list(source.get_flattened_data())
    alpha_pixels = (
        list(alpha.get_flattened_data()) if alpha is not None else [255] * len(pixels)
    )
    assigned: list[tuple[int, int, int]] = []
    brass_candidates: list[tuple[int, int]] = []
    for index, pixel in enumerate(pixels):
        distances = [
            sum((pixel[channel] - color[channel]) ** 2 for channel in range(3))
            for color in PALETTE
        ]
        best = min(range(3), key=distances.__getitem__)
        assigned.append(PALETTE[best])
        if alpha_pixels[index] == 255:
            brass_candidates.append((distances[3] - min(distances[:3]), index))
    maximum = int(sum(value == 255 for value in alpha_pixels) * 0.085)
    for _, index in sorted(brass_candidates)[:maximum]:
        pixel = pixels[index]
        brass_distance = sum((pixel[channel] - PALETTE[3][channel]) ** 2 for channel in range(3))
        neutral_distance = min(
            sum((pixel[channel] - color[channel]) ** 2 for channel in range(3))
            for color in PALETTE[:3]
        )
        if brass_distance < neutral_distance:
            assigned[index] = PALETTE[3]
    output = Image.new("RGB", source.size)
    output.putdata(assigned)
    return output


def process_asset(spec: dict[str, str]) -> dict[str, object]:
    asset_id = spec["id"]
    family = FAMILIES[spec["family"]]
    raw_path = RAW / f"{asset_id}.png"
    source_path = EXTRACTED / f"{asset_id}.png" if family.transparent else raw_path
    if not raw_path.is_file() or not source_path.is_file():
        raise FileNotFoundError(f"{asset_id}: missing generated source")
    with Image.open(raw_path) as opened:
        if opened.format != "PNG":
            raise ValueError(f"{asset_id}: raw source is not PNG")
    with Image.open(source_path) as opened:
        source = opened.copy()

    if family.crop == "alpha-fit":
        logical = alpha_fit(source, family.logical_size)
        alpha = logical.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
        rgb = quantize_rgb(logical.convert("RGB"), alpha)
        logical = Image.merge("RGBA", (*rgb.split(), alpha))
    else:
        cropped = crop_center(source.convert("RGB"), family.logical_size)
        resized = cropped.resize(family.logical_size, Image.Resampling.NEAREST)
        logical = quantize_rgb(resized)

    PROCESSED.mkdir(parents=True, exist_ok=True)
    processed_path = PROCESSED / f"{asset_id}.png"
    logical.save(processed_path, format="PNG", optimize=True)

    images = {
        scale: logical.resize(
            (family.logical_size[0] * scale, family.logical_size[1] * scale),
            Image.Resampling.NEAREST,
        )
        for scale in (1, 2, 3)
    }
    stem = asset_id.replace("_", "-").lower()
    filenames = {
        1: f"{stem}.png",
        2: f"{stem}@2x.png",
        3: f"{stem}@3x.png",
    }
    imageset = CATALOG / f"{asset_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    for scale, image in images.items():
        image.save(imageset / filenames[scale], format="PNG", optimize=True)
    contents = {
        "images": [
            {"filename": filenames[scale], "idiom": "universal", "scale": f"{scale}x"}
            for scale in (1, 2, 3)
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "compression-type": "lossless",
            "template-rendering-intent": "original",
        },
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    return {
        **spec,
        "raw_source": str(raw_path.relative_to(ROOT)),
        "raw_sha256": sha256(raw_path),
        "processed_source": str(processed_path.relative_to(ROOT)),
        "imageset": str(imageset.relative_to(ROOT)),
        "logical_size": list(family.logical_size),
        "transparent": family.transparent,
        "scales": [1, 2, 3],
    }


def image_colors(image: Image.Image) -> set[tuple[int, int, int]]:
    rgba = image.convert("RGBA")
    return {
        pixel[:3]
        for pixel in rgba.get_flattened_data()
        if pixel[3] > 0
    }


def validate_entry(spec: dict[str, object]) -> dict[str, object]:
    asset_id = str(spec["id"])
    logical_size = tuple(spec["logical_size"])
    imageset = ROOT / str(spec["imageset"])
    contents = json.loads((imageset / "Contents.json").read_text())
    expected_scales = {"1x": 1, "2x": 2, "3x": 3}
    seen: set[str] = set()
    brass_pixels = 0
    opaque_pixels = 0
    for image_record in contents["images"]:
        scale_name = image_record["scale"]
        scale = expected_scales[scale_name]
        seen.add(scale_name)
        path = imageset / image_record["filename"]
        with Image.open(path) as opened:
            if opened.format != "PNG":
                raise ValueError(f"{asset_id}: {scale_name} is not PNG")
            image = opened.convert("RGBA")
        expected = (logical_size[0] * scale, logical_size[1] * scale)
        if image.size != expected:
            raise ValueError(f"{asset_id}: {scale_name} size {image.size} != {expected}")
        if not image_colors(image).issubset(PALETTE):
            raise ValueError(f"{asset_id}: {scale_name} escaped the four-pigment palette")
        alpha_values = {pixel[3] for pixel in image.get_flattened_data()}
        if bool(spec["transparent"]):
            if not alpha_values.issubset({0, 255}) or 0 not in alpha_values or 255 not in alpha_values:
                raise ValueError(f"{asset_id}: expected binary transparent sprite")
        elif alpha_values != {255}:
            raise ValueError(f"{asset_id}: expected opaque output")
        if scale == 1:
            pixels = [
                pixel for pixel in image.get_flattened_data() if pixel[3] == 255
            ]
            opaque_pixels = len(pixels)
            brass_pixels = sum(pixel[:3] == PALETTE[3] for pixel in pixels)
    if seen != set(expected_scales):
        raise ValueError(f"{asset_id}: incomplete Contents.json scales")
    brass_ratio = brass_pixels / max(1, opaque_pixels)
    if brass_ratio >= BRASS_LIMIT:
        raise ValueError(f"{asset_id}: brass ratio {brass_ratio:.3f} >= {BRASS_LIMIT:.2f}")
    return {
        "id": asset_id,
        "logical_size": list(logical_size),
        "transparent": bool(spec["transparent"]),
        "brass_ratio": round(brass_ratio, 4),
        "colors": ["#%02X%02X%02X" % color for color in sorted(image_colors(
            Image.open(ROOT / str(spec["processed_source"]))
        ))],
    }


def contact_sheet(entries: list[dict[str, object]], family_names: set[str], output: Path) -> None:
    selected = [entry for entry in entries if entry["family"] in family_names]
    columns = 4
    cell_width, cell_height = 300, 210
    rows = (len(selected) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_width, rows * cell_height), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=15)
    for index, spec in enumerate(selected):
        x = (index % columns) * cell_width
        y = (index // columns) * cell_height
        with Image.open(ROOT / str(spec["processed_source"])) as opened:
            image = opened.convert("RGBA")
        scale = max(1, min(280 // image.width, 168 // image.height))
        preview = image.resize(
            (image.width * scale, image.height * scale),
            Image.Resampling.NEAREST,
        )
        checker = Image.new("RGB", preview.size, PALETTE[1])
        checker.paste(preview, mask=preview.getchannel("A"))
        sheet.paste(checker, (x + (cell_width - preview.width) // 2, y + 6))
        draw.text((x + 8, y + 182), str(spec["id"]), fill=PALETTE[2], font=font)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, format="PNG", optimize=True)


def safe_zone_sheet(entries: list[dict[str, object]], output: Path) -> None:
    selected = [entry for entry in entries if entry["family"] in {"di", "standby"}]
    columns = 2
    cell_width, cell_height = 560, 230
    sheet = Image.new("RGB", (columns * cell_width, 4 * cell_height), PALETTE[0])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=15)
    for index, spec in enumerate(selected):
        x = (index % columns) * cell_width
        y = (index // columns) * cell_height
        with Image.open(ROOT / str(spec["processed_source"])) as opened:
            image = opened.convert("RGB").resize((512, 192 if spec["family"] == "di" else 288), Image.Resampling.NEAREST)
        image.thumbnail((520, 190), Image.Resampling.NEAREST)
        sheet.paste(image, (x + 20, y + 8))
        overlay = ImageDraw.Draw(sheet, "RGBA")
        image_x, image_y = x + 20, y + 8
        if spec["family"] == "di":
            width = round(image.width * 0.36)
            overlay.rectangle(
                (image_x + (image.width - width) // 2, image_y, image_x + (image.width + width) // 2, image_y + round(image.height * 0.45)),
                fill=(197, 140, 57, 70),
                outline=(231, 224, 207, 220),
                width=2,
            )
        else:
            overlay.rectangle(
                (image_x, image_y, image_x + image.width // 3, image_y + image.height),
                fill=(197, 140, 57, 55),
                outline=(231, 224, 207, 220),
                width=2,
            )
        draw.text((x + 20, y + 204), str(spec["id"]), fill=PALETTE[2], font=font)
    sheet.save(output, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if len(ASSETS) != 40 or len({spec["id"] for spec in ASSETS}) != 40:
        raise ValueError("asset inventory must contain exactly 40 unique IDs")
    if args.validate_only:
        entries = json.loads(MANIFEST.read_text())
    else:
        entries = [process_asset(spec) for spec in ASSETS]
        hashes = [entry["raw_sha256"] for entry in entries]
        if len(set(hashes)) != 40:
            raise ValueError("all 40 assets require distinct generated raw sources")
        MANIFEST.write_text(json.dumps(entries, indent=2) + "\n")
        contact_sheet(entries, {"icon", "miner", "decoration", "onboarding"}, ARTIFACTS / "contact-sheet-compact.png")
        contact_sheet(entries, {"theme", "di", "standby"}, ARTIFACTS / "contact-sheet-scenes.png")
        safe_zone_sheet(entries, ARTIFACTS / "safe-zone-overlays.png")
    if len(entries) != 40:
        raise ValueError("manifest must contain exactly 40 entries")
    reports = [validate_entry(entry) for entry in entries]
    REPORT.write_text(json.dumps(reports, indent=2) + "\n")
    print(f"Validated {len(reports)} PNG game-art imagesets")


if __name__ == "__main__":
    main()
