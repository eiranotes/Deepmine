"""Paths and immutable slot contract for DeepMine shaft-scene assets."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts/imagegen/shaft-assets-v1"
RAW = ARTIFACTS / "raw"
EXTRACTED = ARTIFACTS / "extracted"
PROCESSED = ARTIFACTS / "processed"
CATALOG = ROOT / "DeepMineProbe/Shared/SharedAssets.xcassets"
MANIFEST = ARTIFACTS / "manifest.json"
REPORT = ARTIFACTS / "validation-report.json"
CONTACT_SHEET = ARTIFACTS / "contact-sheet.png"
PALETTE = (
    (16, 16, 15),
    (55, 54, 48),
    (231, 224, 207),
    (197, 140, 57),
)


def spec(
    asset_id: str,
    prompt_id: str,
    prompt: str,
    *,
    transparent: bool,
    logical_size: tuple[int, int] = (320, 128),
    crop_anchor: str = "center",
    maximum_brass_ratio: float = 0.10,
) -> dict[str, object]:
    return {
        "id": asset_id,
        "prompt_id": prompt_id,
        "prompt": prompt,
        "transparent": transparent,
        "logical_size": logical_size,
        "crop_anchor": crop_anchor,
        "maximum_brass_ratio": maximum_brass_ratio,
    }


ASSETS = (
    spec(
        "ShaftGantry",
        "shaft-gantry",
        "A panoramic 5:2 DeepMine mine-shaft gantry overlay on a perfectly flat "
        "#00FF00 chroma-key background. Thick worked-stone and iron supports only "
        "at the far sides, a compact crossbeam, one brass lamp, a pulley and short "
        "cable, and a narrow rail along the bottom. Keep at least 70% of the centre "
        "empty. Chunky straight-on pixel art using only #10100F, #373630, #E7E0CF, "
        "and sparse #C58C39. No text, glow, gradients, shadow, perspective, or UI frame.",
        transparent=True,
    ),
    spec(
        "SeamVein",
        "seam-vein",
        "A panoramic 5:2 DeepMine rich ore seam overlay on a perfectly flat #00FF00 "
        "chroma-key background. One irregular horizontal limestone seam spanning "
        "the frame, two or three branches, and sparse brass ore pockets. Keep the "
        "rock beneath visible. Chunky straight-on pixel art using only #10100F, "
        "#373630, #E7E0CF, and #C58C39. No boulder, frame, text, glow, gradients, "
        "shadow, perspective, or extra props.",
        transparent=True,
        maximum_brass_ratio=0.20,
    ),
    spec(
        "ShaftRock_entry",
        "shaft-rock-entry",
        "Panoramic continuous entry-region sedimentary rock wall with broad connected "
        "horizontal shale strata, coal fissures and sparse limestone chips; no separate "
        "boulders, rubble, props, frame or focal object.",
        transparent=False,
        maximum_brass_ratio=0.01,
    ),
    spec(
        "ShaftRock_crystal",
        "shaft-rock-crystal",
        "Panoramic continuous crystal-region angular shale wall with embedded small "
        "limestone crystal clusters and sparse brass tips; no separate boulders or props.",
        transparent=False,
        maximum_brass_ratio=0.04,
    ),
    spec(
        "ShaftRock_ruins",
        "shaft-rock-ruins",
        "Panoramic continuous ruins-region worked masonry fused into shale, with broad "
        "courses, worn mortar lines and embedded lintel fragments; no door or text.",
        transparent=False,
        maximum_brass_ratio=0.04,
    ),
    spec(
        "ShaftRock_abyss",
        "shaft-rock-abyss",
        "Panoramic continuous abyss-region near-black rock wall with broad planes, deep "
        "void fissures and sparse thin limestone rims; no creature, symbol or props.",
        transparent=False,
        maximum_brass_ratio=0.01,
    ),
    spec(
        "ShaftSurface",
        "shaft-surface",
        "A wide surface mine entrance overlay on flat #00FF00 chroma key: thin earth "
        "lip at the top, compact side supports and one small brass marker lamp, with at "
        "least 75% of the centre and lower centre empty.",
        transparent=True,
        logical_size=(320, 90),
        crop_anchor="top",
    ),
)
