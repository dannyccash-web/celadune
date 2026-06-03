#!/usr/bin/env python3
"""
Building Compositor for Celadune — Tile-Based
Generates buildings by assembling individual 32×32 tiles.

Scale: 1 tile = 32px. NPCs are 64×64px (2 tiles tall).
Door = 1 tile wide × 2 tiles tall = 32×64px (matches NPC height).

Building anatomy (bottom to top in the image, top to bottom in the scene):
  Wall base  — W tiles wide × H tiles tall (min 5 wide × 3 tall)
    • Door   — 1×2 tiles at ground level (bottom 2 rows of wall), random column
    • Windows — 1×1 tiles, greedy-filled in non-forbidden cells
    • Wall   — fills all remaining cells
  Roof       — sits above the wall base
    • 'peaked'  — 2 rows: peak row + slope row, using slope/peak tiles
    • 'ceramic' — 2 rows: ceramic_top + ceramic_main, tiled across full width

1-tile buffer rule for windows:
  • Edge columns (col 0 and W-1) are always plain wall.
  • No window may be orthogonally adjacent to the door or another window.

Usage:
  python3 tools/building_compositor.py --random --seed 42 --name "Old Cottage" --out assets/buildings/old_cottage/
  python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/
  python3 tools/building_compositor.py --list

Output per building:
  building.png  — Single static RGBA PNG at native tile scale
  spec.json     — Full spec for exact reproduction
"""

import argparse
import json
import random
import sys
from pathlib import Path
from PIL import Image

# ── Paths ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR  = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
TILES_DIR   = PROJECT_DIR / "assets" / "building-parts" / "tiles"

TILE = 32  # px per tile

# ── Tile loader (cached) ───────────────────────────────────────────────────────

_tile_cache: dict[str, Image.Image] = {}

def load_tile(rel_path: str) -> Image.Image:
    if rel_path not in _tile_cache:
        full = TILES_DIR / rel_path
        if not full.exists():
            raise FileNotFoundError(f"Tile not found: {full}")
        _tile_cache[rel_path] = Image.open(full).convert("RGBA")
    return _tile_cache[rel_path]


# ── Roof builders ──────────────────────────────────────────────────────────────

def build_peaked_roof(W: int) -> Image.Image:
    """
    Peaked (triangular) roof for a building W tiles wide.
    Output: W*32 wide × 64 tall (2 tile rows). Transparent outside the triangle.

    Peak row  (y 0–31):  covers cols 2 … W-3  (W-4 tiles)
    Slope row (y 32–63): covers cols 1 … W-2  (W-2 tiles)
    Outer columns are transparent (roof doesn't extend to building edges).
    """
    img = Image.new("RGBA", (W * TILE, 2 * TILE), (0, 0, 0, 0))

    # ── Peak row ──────────────────────────────────────────────────────────────
    p_start = 2
    p_end   = W - 3
    for col in range(p_start, p_end + 1):
        if p_start == p_end:
            tile = load_tile("roof/peak_center.png")   # single-tile peak
        elif col == p_start:
            tile = load_tile("roof/peak_left.png")
        elif col == p_end:
            tile = load_tile("roof/peak_right.png")
        else:
            tile = load_tile("roof/peak_center.png")
        img.paste(tile, (col * TILE, 0), tile)

    # ── Slope row ─────────────────────────────────────────────────────────────
    s_start = 1
    s_end   = W - 2
    s_len   = s_end - s_start  # number of interior slots
    for col in range(s_start, s_end + 1):
        pos = col - s_start   # 0-indexed position within slope row
        if col == s_start:
            tile = load_tile("roof/slope_left_eave.png")
        elif col == s_end:
            tile = load_tile("roof/slope_right_eave.png")
        elif pos == 1 and s_len > 2:
            tile = load_tile("roof/slope_left.png")
        elif col == s_end - 1 and s_len > 2:
            tile = load_tile("roof/slope_right.png")
        else:
            tile = load_tile("roof/slope_center.png")
        img.paste(tile, (col * TILE, TILE), tile)

    return img


def build_ceramic_roof(W: int) -> Image.Image:
    """
    Flat-facing ceramic tile roof, W tiles wide × 2 tile rows tall.
    Row 0: ceramic_top trim; Row 1: ceramic_main (repeatable).
    """
    img = Image.new("RGBA", (W * TILE, 2 * TILE), (0, 0, 0, 0))
    top  = load_tile("roof/ceramic_top.png")
    main = load_tile("roof/ceramic_main.png")
    for col in range(W):
        img.paste(top,  (col * TILE, 0),    top)
        img.paste(main, (col * TILE, TILE), main)
    return img


# ── Wall base builder ──────────────────────────────────────────────────────────

def build_wall(W: int, H: int, wall_key: str, door_key: str,
               window_key: str, door_col: int) -> Image.Image:
    """
    Build the wall base as a W*32 × H*32 image.

    Grid rows: 0 = top, H-1 = ground level.
    Door bottom tile at (H-1, door_col); door top at (H-2, door_col).
    Windows fill non-forbidden cells; everything else is wall.
    """
    # ── Grid initialisation ───────────────────────────────────────────────────
    grid: list[list[str]] = [["wall"] * W for _ in range(H)]

    # Place door (bottom 2 rows of wall)
    grid[H - 1][door_col] = "door_bottom"
    grid[H - 2][door_col] = "door_top"

    # ── Forbidden cells (window buffer rules) ─────────────────────────────────
    forbidden: set[tuple[int, int]] = set()

    # Edge columns are always plain wall
    for r in range(H):
        forbidden.add((r, 0))
        forbidden.add((r, W - 1))

    # Door tiles and their orthogonal neighbours (1-tile buffer)
    for door_row in (H - 1, H - 2):
        for dr, dc in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = door_row + dr, door_col + dc
            if 0 <= nr < H and 0 <= nc < W:
                forbidden.add((nr, nc))

    # ── Greedy window placement ───────────────────────────────────────────────
    placed: set[tuple[int, int]] = set()
    for r in range(H):
        for c in range(W):
            if (r, c) in forbidden or grid[r][c] != "wall":
                continue
            # Skip if orthogonally adjacent to an already-placed window
            if any((r + dr, c + dc) in placed
                   for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))):
                continue
            grid[r][c] = "window"
            placed.add((r, c))

    # ── Composite image ───────────────────────────────────────────────────────
    img = Image.new("RGBA", (W * TILE, H * TILE), (0, 0, 0, 0))

    wall_tile   = load_tile(f"walls/{wall_key}.png")
    window_tile = load_tile(f"windows/{window_key}.png")
    door_top    = load_tile(f"doors/door_{door_key}_top.png")
    door_bottom = load_tile(f"doors/door_{door_key}_bottom.png")

    tile_map = {
        "wall":        wall_tile,
        "window":      window_tile,
        "door_top":    door_top,
        "door_bottom": door_bottom,
    }

    for r in range(H):
        for c in range(W):
            tile = tile_map[grid[r][c]]
            img.paste(tile, (c * TILE, r * TILE), tile)

    return img


# ── Full building ──────────────────────────────────────────────────────────────

def generate_building(spec: dict, out_dir: str) -> Path:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    W        = spec["width"]
    H        = spec["wall_height"]
    wall_key = spec["wall"]          # e.g. "wall_stone"
    door_key = spec["door"]          # e.g. "wood", "teal", "red"
    win_key  = spec["window"]        # e.g. "window_glass"
    roof_t   = spec["roof"]          # "peaked" or "ceramic"
    door_col = spec["door_col"]

    print(f"  Size: {W}×{H} wall tiles, roof: {roof_t}, door: {door_key} @ col {door_col}, wall: {wall_key}")

    roof = build_peaked_roof(W) if roof_t == "peaked" else build_ceramic_roof(W)
    wall = build_wall(W, H, wall_key, door_key, win_key, door_col)

    total_h = roof.height + wall.height
    building = Image.new("RGBA", (W * TILE, total_h), (0, 0, 0, 0))
    building.paste(roof, (0, 0),           roof)
    building.paste(wall, (0, roof.height), wall)

    bp = out / "building.png"
    sp = out / "spec.json"
    building.save(bp)

    export = {k: v for k, v in spec.items()}
    export["_size_px"] = f"{building.width}×{building.height}"
    with open(sp, "w") as f:
        json.dump(export, f, indent=2)

    print(f"  → {bp}  ({building.width}×{building.height}px)")
    return bp


# ── Random spec builder ────────────────────────────────────────────────────────

WALL_OPTIONS   = ["wall_stone", "wall_stone_dark"]
DOOR_OPTIONS   = ["wood", "teal", "red"]
WINDOW_OPTIONS = ["window_glass"]
ROOF_OPTIONS   = ["peaked", "ceramic"]

def build_random_spec(seed=None, name=None) -> dict:
    rng = random.Random(seed)

    W    = rng.randint(5, 8)
    H    = rng.randint(3, 5)
    wall = rng.choice(WALL_OPTIONS)
    door = rng.choice(DOOR_OPTIONS)
    win  = rng.choice(WINDOW_OPTIONS)
    roof = rng.choice(ROOF_OPTIONS)

    # Door column: interior only (cols 1 to W-2), skipping edge-adjacent
    door_col = rng.randint(1, W - 2)

    return {
        "name":        name,
        "seed":        seed,
        "width":       W,
        "wall_height": H,
        "wall":        wall,
        "door":        door,
        "window":      win,
        "roof":        roof,
        "door_col":    door_col,
    }


# ── Part listing ───────────────────────────────────────────────────────────────

def list_parts():
    print(f"\nTile library ({TILES_DIR}):\n")
    for cat in sorted(TILES_DIR.iterdir()):
        if cat.is_dir():
            files = sorted(f.name for f in cat.glob("*.png"))
            print(f"  {cat.name}/  ({len(files)} tiles)")
            for f in files:
                print(f"    {f}")
    print(f"\nRandom options:")
    print(f"  wall:   {WALL_OPTIONS}")
    print(f"  door:   {DOOR_OPTIONS}")
    print(f"  roof:   {ROOF_OPTIONS}")
    print(f"  width:  5–8 tiles  ({5*TILE}–{8*TILE}px)")
    print(f"  height: 3–5 wall tiles + 2 roof tiles")
    print(f"  door:   1×2 tiles = {TILE}×{TILE*2}px (matches 64px NPC height)")
    print()


# ── CLI ────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Celadune Building Compositor (tile-based)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--random", action="store_true", help="Generate a random building")
    group.add_argument("--spec",   metavar="FILE",      help="JSON spec file")
    group.add_argument("--list",   action="store_true", help="List available tiles")

    parser.add_argument("--out",  metavar="DIR", help="Output directory")
    parser.add_argument("--seed", metavar="INT", type=int)
    parser.add_argument("--name", metavar="NAME")

    args = parser.parse_args()

    if args.list:
        list_parts()
        return

    if not args.out:
        parser.error("--out is required")

    if args.spec:
        with open(args.spec) as f:
            spec = json.load(f)
        print(f"Building from spec: {args.spec}")
    else:
        print(f"Random building (seed={args.seed})...")
        spec = build_random_spec(seed=args.seed, name=args.name)

    print("Spec:")
    for k, v in spec.items():
        if not k.startswith("_"):
            print(f"  {k}: {v}")
    print()

    generate_building(spec, args.out)


if __name__ == "__main__":
    main()
