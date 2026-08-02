#!/usr/bin/env python3
"""Validate long-depth and progression PNGs with Python's strict zlib decoder."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "artifacts/imagegen/long-progression-v2/manifest.json"
PROVENANCE = ROOT / "artifacts/imagegen/long-progression-v2/provenance.json"
PALETTE = {
    (16, 16, 15),
    (55, 54, 48),
    (231, 224, 207),
    (197, 140, 57),
}
EXPECTED_ASSET_IDS = frozenset({
    "ShaftRock_pressure",
    "ShaftRock_fault",
    "ShaftRock_core",
    "RefinementBadge_drill",
    "RefinementBadge_cart",
    "RefinementBadge_lamp",
    "PrestigeMemoryRing",
})
WEB_ASSET_IDS = frozenset({
    "ShaftRock_pressure",
    "ShaftRock_fault",
    "ShaftRock_core",
})


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def paeth(left: int, above: int, upper_left: int) -> int:
    estimate = left + above - upper_left
    distances = (
        abs(estimate - left),
        abs(estimate - above),
        abs(estimate - upper_left),
    )
    return (left, above, upper_left)[distances.index(min(distances))]


def decode_png(path: Path) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    payload = path.read_bytes()
    if payload[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: invalid PNG signature")

    offset = 8
    header: tuple[int, int, int, int, int, int, int] | None = None
    compressed = bytearray()
    saw_end = False
    while offset < len(payload):
        if offset + 12 > len(payload):
            raise ValueError(f"{path}: truncated PNG chunk")
        length = struct.unpack(">I", payload[offset:offset + 4])[0]
        chunk_type = payload[offset + 4:offset + 8]
        start = offset + 8
        end = start + length
        if end + 4 > len(payload):
            raise ValueError(f"{path}: truncated {chunk_type!r} payload")
        data = payload[start:end]
        declared_crc = struct.unpack(">I", payload[end:end + 4])[0]
        actual_crc = zlib.crc32(chunk_type)
        actual_crc = zlib.crc32(data, actual_crc) & 0xFFFFFFFF
        if declared_crc != actual_crc:
            raise ValueError(f"{path}: CRC mismatch in {chunk_type.decode('ascii')}")
        if chunk_type == b"IHDR":
            header = struct.unpack(">IIBBBBB", data)
        elif chunk_type == b"IDAT":
            compressed.extend(data)
        elif chunk_type == b"IEND":
            saw_end = True
            break
        offset = end + 4

    if header is None or not saw_end:
        raise ValueError(f"{path}: incomplete PNG")
    width, height, bit_depth, color_type, compression, filtering, interlace = header
    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(f"{path}: only 8-bit RGB/RGBA is accepted")
    if compression != 0 or filtering != 0 or interlace != 0:
        raise ValueError(f"{path}: unsupported PNG encoding")

    channels = 4 if color_type == 6 else 3
    stride = width * channels
    try:
        scanlines = zlib.decompress(bytes(compressed))
    except zlib.error as error:
        raise ValueError(f"{path}: corrupt IDAT stream: {error}") from error
    if len(scanlines) != (stride + 1) * height:
        raise ValueError(f"{path}: decoded byte count does not match dimensions")

    previous = bytearray(stride)
    pixels: list[tuple[int, int, int, int]] = []
    cursor = 0
    for _ in range(height):
        filter_type = scanlines[cursor]
        cursor += 1
        encoded = scanlines[cursor:cursor + stride]
        cursor += stride
        decoded = bytearray(stride)
        for index, value in enumerate(encoded):
            left = decoded[index - channels] if index >= channels else 0
            above = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = above
            elif filter_type == 3:
                predictor = (left + above) // 2
            elif filter_type == 4:
                predictor = paeth(left, above, upper_left)
            else:
                raise ValueError(f"{path}: invalid PNG filter {filter_type}")
            decoded[index] = (value + predictor) & 0xFF
        for index in range(0, stride, channels):
            red, green, blue = decoded[index:index + 3]
            alpha = decoded[index + 3] if channels == 4 else 255
            pixels.append((red, green, blue, alpha))
        previous = decoded
    return width, height, pixels


def validate(entry: dict[str, object]) -> dict[str, object]:
    asset_id = str(entry["id"])
    raw = ROOT / str(entry["raw_source"])
    processed = ROOT / str(entry["processed_source"])
    expected_size = tuple(entry["logical_size"])
    if sha256(raw) != entry["raw_sha256"]:
        raise ValueError(f"{asset_id}: raw SHA mismatch")
    if sha256(processed) != entry["processed_sha256"]:
        raise ValueError(f"{asset_id}: processed SHA mismatch")

    width, height, pixels = decode_png(processed)
    if (width, height) != expected_size:
        raise ValueError(f"{asset_id}: expected {expected_size}, got {(width, height)}")
    if any(alpha not in (0, 255) for *_, alpha in pixels):
        raise ValueError(f"{asset_id}: partial alpha is not allowed")
    transparent = bool(entry["transparent"])
    if transparent and not any(alpha == 0 for *_, alpha in pixels):
        raise ValueError(f"{asset_id}: transparent asset lacks transparent pixels")
    if not transparent and any(alpha != 255 for *_, alpha in pixels):
        raise ValueError(f"{asset_id}: rock texture must be fully opaque")
    opaque_colors = {(red, green, blue) for red, green, blue, alpha in pixels if alpha == 255}
    if opaque_colors - PALETTE:
        raise ValueError(f"{asset_id}: colors outside the four-pigment palette")

    catalog = ROOT / str(entry["catalog_source"])
    if sha256(catalog) != entry["processed_sha256"]:
        raise ValueError(f"{asset_id}: catalog copy differs from processed source")
    contents = json.loads((catalog.parent / "Contents.json").read_text())
    if contents["images"][0].get("filename") != catalog.name:
        raise ValueError(f"{asset_id}: asset catalog does not select the v2 PNG")
    web_source = entry.get("web_source")
    if asset_id in WEB_ASSET_IDS and not web_source:
        raise ValueError(f"{asset_id}: web_source is required")
    if web_source and sha256(ROOT / str(web_source)) != entry["processed_sha256"]:
        raise ValueError(f"{asset_id}: web copy differs from processed source")
    return {
        "id": asset_id,
        "valid": True,
        "size": [width, height],
        "opaque_colors": len(opaque_colors),
        "transparent": transparent,
    }


def validate_provenance(
    manifest_entries: list[dict[str, object]],
    provenance_entries: object,
) -> None:
    if not isinstance(provenance_entries, list):
        raise ValueError("provenance root must be an array")
    provenance_ids = [str(entry.get("asset")) for entry in provenance_entries]
    if len(provenance_ids) != len(set(provenance_ids)):
        raise ValueError("provenance asset IDs must be unique")
    if set(provenance_ids) != EXPECTED_ASSET_IDS:
        missing = sorted(EXPECTED_ASSET_IDS - set(provenance_ids))
        extra = sorted(set(provenance_ids) - EXPECTED_ASSET_IDS)
        raise ValueError(f"provenance asset set mismatch; missing={missing}, extra={extra}")

    raw_sources = {
        str(entry["id"]): str(entry["raw_source"])
        for entry in manifest_entries
    }
    for entry in provenance_entries:
        asset_id = str(entry["asset"])
        if entry.get("project_raw_copy") != raw_sources[asset_id]:
            raise ValueError(f"{asset_id}: provenance raw copy differs from manifest")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    entries = json.loads(MANIFEST.read_text())
    if not isinstance(entries, list):
        raise ValueError("manifest root must be an array")
    asset_ids = [str(entry.get("id")) for entry in entries]
    if len(asset_ids) != len(set(asset_ids)):
        raise ValueError("manifest asset IDs must be unique")
    if set(asset_ids) != EXPECTED_ASSET_IDS:
        missing = sorted(EXPECTED_ASSET_IDS - set(asset_ids))
        extra = sorted(set(asset_ids) - EXPECTED_ASSET_IDS)
        raise ValueError(f"manifest asset set mismatch; missing={missing}, extra={extra}")
    validate_provenance(entries, json.loads(PROVENANCE.read_text()))
    reports = [validate(entry) for entry in entries]
    if args.report:
        args.report.write_text(json.dumps(reports, ensure_ascii=False, indent=2) + "\n")
    print(f"Validated {len(reports)} long-progression PNG assets")


if __name__ == "__main__":
    main()
