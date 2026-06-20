#!/usr/bin/env python3
import json
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TILESET = ROOT / "SharedGameData" / "Tiles" / "Mossy" / "terrain-256"
MANIFEST = TILESET / "manifest.json"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

SPARSE_MASKS = {0, 1, 2, 4, 5, 8, 10}
INNER_CORNER_MASKS = {1, 2, 4, 8}
NORTH = 1
EAST = 2
SOUTH = 4
WEST = 8
COMMON_VARIATION_MASKS = {
    EAST | SOUTH | WEST,  # surface
    NORTH | EAST | SOUTH,  # left edge
    NORTH | SOUTH | WEST,  # right edge
    NORTH | EAST | WEST,  # bottom edge
    NORTH | EAST | SOUTH | WEST,  # middle fill
}


def png_size(path):
    with path.open("rb") as handle:
        signature = handle.read(8)
        if signature != PNG_SIGNATURE:
            raise ValueError(f"{path} is not a PNG")
        length = struct.unpack(">I", handle.read(4))[0]
        chunk_type = handle.read(4)
        if chunk_type != b"IHDR" or length < 8:
            raise ValueError(f"{path} has invalid PNG header")
        width, height = struct.unpack(">II", handle.read(8))
        return width, height


def fail(message):
    print(f"FAIL: {message}", file=sys.stderr)
    return 1


def connection_mask(cell, terrain):
    x, y = cell
    mask = 0
    if (x, y - 1) in terrain:
        mask |= NORTH
    if (x + 1, y) in terrain:
        mask |= EAST
    if (x, y + 1) in terrain:
        mask |= SOUTH
    if (x - 1, y) in terrain:
        mask |= WEST
    return mask


def inner_corner_mask(cell, terrain):
    x, y = cell
    north = (x, y - 1) in terrain
    east = (x + 1, y) in terrain
    south = (x, y + 1) in terrain
    west = (x - 1, y) in terrain

    mask = 0
    if north and west and (x - 1, y - 1) not in terrain:
        mask |= 1
    if north and east and (x + 1, y - 1) not in terrain:
        mask |= 2
    if south and west and (x - 1, y + 1) not in terrain:
        mask |= 4
    if south and east and (x + 1, y + 1) not in terrain:
        mask |= 8
    return mask


def stable_index(x, y, mask, inner_mask, seed, count):
    hash_value = 14_695_981_039_346_656_037
    for value in (x, y, mask, inner_mask, seed):
        hash_value ^= (value * 16_777_619) & 0xFFFFFFFFFFFFFFFF
        hash_value = (hash_value * 1_099_511_628_211) & 0xFFFFFFFFFFFFFFFF
    return hash_value % count


def preferred_exact_candidates(candidates, mask):
    if mask not in SPARSE_MASKS:
        return candidates

    generated = [tile for tile in candidates if tile.get("generated")]
    return generated or candidates


def preferred_inner_candidates(candidates, mask):
    if mask == 0:
        plain = [tile for tile in candidates if tile.get("innerCornerMask", 0) == 0]
        return plain or candidates

    exact = [tile for tile in candidates if tile.get("innerCornerMask", 0) == mask]
    if exact:
        return exact

    overlapping = [tile for tile in candidates if tile.get("innerCornerMask", 0) & mask]
    return overlapping or candidates


def selected_tile_for(cell, terrain, candidates_by_mask, seed=0):
    mask = connection_mask(cell, terrain)
    inner_mask = inner_corner_mask(cell, terrain)
    candidates = candidates_by_mask.get(mask, [])
    if not candidates:
        raise AssertionError(f"no candidates for mask {mask} at cell {cell}")

    candidates = preferred_exact_candidates(candidates, mask)
    candidates = preferred_inner_candidates(candidates, inner_mask)
    index = stable_index(cell[0], cell[1], mask, inner_mask, seed, len(candidates))
    return candidates[index], mask, inner_mask


def rectangle(x, y, width, height):
    return {
        (cell_x, cell_y)
        for cell_y in range(y, y + height)
        for cell_x in range(x, x + width)
    }


def verify_scenario(name, terrain, expected_cells, candidates_by_mask):
    for label, cell, expected_mask, expected_inner in expected_cells:
        actual_mask = connection_mask(cell, terrain)
        actual_inner = inner_corner_mask(cell, terrain)
        if actual_mask != expected_mask:
            raise AssertionError(
                f"{name} {label} at {cell}: mask {actual_mask}, expected {expected_mask}"
            )
        if actual_inner != expected_inner:
            raise AssertionError(
                f"{name} {label} at {cell}: inner {actual_inner}, expected {expected_inner}"
            )

        tile, tile_mask, tile_inner = selected_tile_for(cell, terrain, candidates_by_mask)
        if tile_mask != expected_mask:
            raise AssertionError(
                f"{name} {label} selected {tile['id']} mask {tile_mask}, expected {expected_mask}"
            )
        if expected_inner and not (tile_inner & expected_inner):
            raise AssertionError(
                f"{name} {label} selected {tile['id']} inner {tile_inner}, expected {expected_inner}"
            )


def verify_autotile_scenarios(candidates_by_mask):
    solid = rectangle(1, 1, 5, 4)
    platform = rectangle(1, 1, 5, 1)
    column = rectangle(1, 1, 1, 5)
    isolated = {(1, 1)}

    scenarios = [
        (
            "solid block",
            solid,
            [
                ("top-left", (1, 1), EAST | SOUTH, 0),
                ("top", (3, 1), EAST | SOUTH | WEST, 0),
                ("top-right", (5, 1), SOUTH | WEST, 0),
                ("left edge", (1, 2), NORTH | EAST | SOUTH, 0),
                ("middle fill", (3, 2), NORTH | EAST | SOUTH | WEST, 0),
                ("right edge", (5, 2), NORTH | SOUTH | WEST, 0),
                ("bottom-left", (1, 4), NORTH | EAST, 0),
                ("bottom", (3, 4), NORTH | EAST | WEST, 0),
                ("bottom-right", (5, 4), NORTH | WEST, 0),
            ],
        ),
        (
            "thin platform",
            platform,
            [
                ("left end", (1, 1), EAST, 0),
                ("center", (3, 1), EAST | WEST, 0),
                ("right end", (5, 1), WEST, 0),
            ],
        ),
        (
            "thin column",
            column,
            [
                ("top end", (1, 1), SOUTH, 0),
                ("center", (1, 3), NORTH | SOUTH, 0),
                ("bottom end", (1, 5), NORTH, 0),
            ],
        ),
        (
            "isolated block",
            isolated,
            [("isolated", (1, 1), 0, 0)],
        ),
    ]

    for missing_cell, expected_inner in [
        ((1, 1), 1),
        ((3, 1), 2),
        ((1, 3), 4),
        ((3, 3), 8),
    ]:
        terrain = rectangle(1, 1, 3, 3)
        terrain.remove(missing_cell)
        scenarios.append(
            (
                f"inner corner {expected_inner}",
                terrain,
                [("center", (2, 2), NORTH | EAST | SOUTH | WEST, expected_inner)],
            )
        )

    for scenario in scenarios:
        verify_scenario(*scenario, candidates_by_mask)

    wide_surface = rectangle(1, 1, 12, 2)
    varied_surface = {
        selected_tile_for((x, 1), wide_surface, candidates_by_mask, seed=0)[0]["id"]
        for x in range(2, 12)
    }
    if len(varied_surface) < 2:
        raise AssertionError("surface row did not vary selected tile ids")

    full_fill = rectangle(1, 1, 6, 6)
    varied_fill = {
        selected_tile_for((x, y), full_fill, candidates_by_mask, seed=0)[0]["id"]
        for y in range(2, 6)
        for x in range(2, 6)
    }
    if len(varied_fill) < 2:
        raise AssertionError("middle fill did not vary selected tile ids")

    return len(scenarios)


def main():
    if not MANIFEST.exists():
        return fail(f"missing manifest: {MANIFEST}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    tile_size = manifest.get("tileSize")
    tiles = manifest.get("tiles", [])
    if tile_size != 256:
        return fail(f"expected tileSize 256, got {tile_size}")
    if not tiles:
        return fail("manifest has no tiles")

    tile_ids = {tile["id"] for tile in tiles}
    unique_usable_by_mask = {}
    generated_unique_by_mask = {}
    inner_corner_candidates = set()
    unique_usable_tiles = []

    for tile in tiles:
        path = TILESET / tile["file"]
        if not path.exists():
            return fail(f"missing tile file: {path}")

        width, height = png_size(path)
        if (width, height) != (tile_size, tile_size):
            return fail(f"{path.name} is {width}x{height}, expected {tile_size}x{tile_size}")

        if tile.get("usable") and tile.get("duplicateOf") is None:
            unique_usable_tiles.append(tile)
            mask = tile.get("connectionMask")
            unique_usable_by_mask.setdefault(mask, []).append(tile["id"])
            if tile.get("generated"):
                generated_unique_by_mask.setdefault(mask, []).append(tile["id"])
            if mask == 15 and tile.get("innerCornerMask") in INNER_CORNER_MASKS:
                inner_corner_candidates.add(tile["innerCornerMask"])

        for source_id in tile.get("generatedFrom", []):
            if "#" in source_id:
                continue
            if source_id not in tile_ids:
                return fail(f"{tile['id']} references missing generatedFrom id: {source_id}")

    missing_masks = [mask for mask in range(16) if not unique_usable_by_mask.get(mask)]
    if missing_masks:
        return fail(f"missing unique usable candidates for masks: {missing_masks}")

    missing_generated = [mask for mask in sorted(SPARSE_MASKS) if not generated_unique_by_mask.get(mask)]
    if missing_generated:
        return fail(f"missing generated candidates for sparse masks: {missing_generated}")

    missing_inner = sorted(INNER_CORNER_MASKS - inner_corner_candidates)
    if missing_inner:
        return fail(f"missing inner corner candidates: {missing_inner}")

    low_variation_masks = [
        mask
        for mask in sorted(COMMON_VARIATION_MASKS)
        if len(unique_usable_by_mask.get(mask, [])) < 2
    ]
    if low_variation_masks:
        return fail(f"not enough variation candidates for masks: {low_variation_masks}")

    candidates_by_mask = {}
    for tile in unique_usable_tiles:
        candidates_by_mask.setdefault(tile.get("connectionMask"), []).append(tile)

    try:
        scenario_count = verify_autotile_scenarios(candidates_by_mask)
    except AssertionError as error:
        return fail(str(error))

    print("OK: Mossy autotile manifest")
    print(f"  tiles: {len(tiles)}")
    print(f"  unique usable masks: {sorted(unique_usable_by_mask)}")
    print(f"  generated sparse masks: {sorted(generated_unique_by_mask)}")
    print(f"  inner corners: {sorted(inner_corner_candidates)}")
    print(f"  autotile scenarios: {scenario_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
