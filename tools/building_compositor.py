#!/usr/bin/env python3
"""
Building Compositor for Celadune
Composites GandalfHardcore building part layers into static building sprites.

Usage:
  python3 tools/building_compositor.py --random stone_house --seed 42 --name "Old Cottage" --out assets/buildings/old_cottage/
  python3 tools/building_compositor.py --random complete   --seed 7  --name "The Rusty Mug" --out assets/buildings/rusty_mug/
  python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/
  python3 tools/building_compositor.py --list

Building types:
  stone_house  — Composited from interchangeable roof + upper wall + lower wall sections (184px wide)
  complete     — Random pick from a pre-assembled complete building sprite

Output per building:
  building.png  — Single static sprite (RGBA PNG, transparent background)
  spec.json     — Parts manifest for exact reproduction

Parts library:  assets/building-parts/
  roofs/        — Peaked roof sections (must be same width as walls for stacking)
  walls/        — Wall sections (upper floor, lower floor, and facade panels)
  accessories/  — Column capitals and other decorative pieces

Complete buildings: assets/buildings/
  open_hall.png, stone_hall.png, stone_house_v1.png, stone_house_v2.png

Layer order for stone_house compositing (top to bottom):
  roof → upper_wall → lower_wall
"""

import argparse
import json
import os
import random
import sys
from pathlib import Path
from PIL import Image
import numpy as np

# ── Paths ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR    = Path(__file__).parent
PROJECT_DIR   = SCRIPT_DIR.parent
PARTS_DIR     = PROJECT_DIR / "assets" / "building-parts"
BUILDINGS_DIR = PROJECT_DIR / "assets" / "buildings"

# ── Building type definitions ──────────────────────────────────────────────────

# stone_house: parts stack vertically (roof on top, then upper wall, then lower wall)
# All parts in the 'stone_house' family are 184px wide, heights vary.
STONE_HOUSE_LAYERS = ["roof", "upper_wall", "lower_wall"]

PART_GLOBS = {
    "stone_house": {
        "roof":       "roofs/roof_stone_*.png",
        "upper_wall": "walls/wall_stone_upper_*.png",
        "lower_wall": "walls/wall_stone_lower_*.png",
    }
}

COMPLETE_BUILDINGS = [
    "open_hall.png",
    "stone_hall.png",
    "stone_house_v1.png",
    "stone_house_v2.png",
]

# ── Compositor ─────────────────────────────────────────────────────────────────

def stack_vertically(parts):
    """
    Stack a list of RGBA PIL Images vertically (top to bottom).
    All images must have the same width. Heights are summed.
    """
    widths  = [p.size[0] for p in parts]
    heights = [p.size[1] for p in parts]
    if len(set(widths)) != 1:
        raise ValueError(f"Part widths don't match for vertical stacking: {widths}")
    total_h = sum(heights)
    canvas  = Image.new("RGBA", (widths[0], total_h), (0, 0, 0, 0))
    y = 0
    for part in parts:
        canvas.paste(part, (0, y), part)
        y += part.size[1]
    return canvas


def build_stone_house(spec, out_dir):
    """
    Composite a stone_house from roof + upper_wall + lower_wall parts.
    Returns path to the saved building.png.
    """
    out_path = Path(out_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    layers = []
    for key in STONE_HOUSE_LAYERS:
        path = spec.get(key)
        if not path:
            raise ValueError(f"Missing required part '{key}' in spec")
        img = Image.open(path).convert("RGBA")
        layers.append(img)
        print(f"  {key}: {Path(path).name}  ({img.size[0]}x{img.size[1]})")

    print("Stacking layers...")
    building = stack_vertically(layers)

    building_path = out_path / "building.png"
    spec_path     = out_path / "spec.json"

    building.save(building_path)

    output_spec = {k: str(v) if isinstance(v, Path) else v for k, v in spec.items()}
    output_spec["_size"] = f"{building.size[0]}x{building.size[1]}"
    with open(spec_path, "w") as f:
        json.dump(output_spec, f, indent=2)

    print(f"\nSaved {building_path}  ({building.size[0]}x{building.size[1]})")
    return building_path


def build_complete(spec, out_dir):
    """
    Copy a pre-assembled complete building sprite to the output directory.
    """
    out_path = Path(out_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    src = spec.get("source")
    if not src:
        raise ValueError("Missing 'source' in spec for complete building")

    img = Image.open(src).convert("RGBA")
    building_path = out_path / "building.png"
    spec_path     = out_path / "spec.json"

    img.save(building_path)
    output_spec = {k: str(v) if isinstance(v, Path) else v for k, v in spec.items()}
    output_spec["_size"] = f"{img.size[0]}x{img.size[1]}"
    with open(spec_path, "w") as f:
        json.dump(output_spec, f, indent=2)

    print(f"  source: {Path(src).name}  ({img.size[0]}x{img.size[1]})")
    print(f"\nSaved {building_path}  ({img.size[0]}x{img.size[1]})")
    return building_path


# ── Random spec builders ───────────────────────────────────────────────────────

def pick_random(glob_pattern, rng):
    """Pick a random PNG matching a glob pattern under PARTS_DIR."""
    files = sorted(PARTS_DIR.glob(glob_pattern))
    if not files:
        raise FileNotFoundError(f"No files found for pattern: {PARTS_DIR / glob_pattern}")
    return str(rng.choice(files))


def build_random_spec_stone_house(seed=None, name=None):
    rng = random.Random(seed)
    spec = {
        "type":       "stone_house",
        "name":       name,
        "seed":       seed,
    }
    globs = PART_GLOBS["stone_house"]
    for key, pattern in globs.items():
        spec[key] = pick_random(pattern, rng)
    return spec


def build_random_spec_complete(seed=None, name=None):
    rng = random.Random(seed)
    available = [str(BUILDINGS_DIR / b) for b in COMPLETE_BUILDINGS
                 if (BUILDINGS_DIR / b).exists()]
    if not available:
        raise FileNotFoundError(f"No complete buildings found in {BUILDINGS_DIR}")
    source = rng.choice(available)
    return {
        "type":   "complete",
        "name":   name,
        "seed":   seed,
        "source": source,
    }


# ── Part listing ───────────────────────────────────────────────────────────────

def list_parts():
    print(f"\nBuilding parts library ({PARTS_DIR}):\n")
    if not PARTS_DIR.exists():
        print("  (parts directory not found)")
    else:
        for folder in sorted(PARTS_DIR.iterdir()):
            if folder.is_dir():
                files = sorted(f.name for f in folder.glob("*.png"))
                print(f"  {folder.name}/  ({len(files)} parts)")
                for f in files:
                    print(f"    {f}")

    print(f"\nComplete building sprites ({BUILDINGS_DIR}):\n")
    for b in COMPLETE_BUILDINGS:
        path = BUILDINGS_DIR / b
        status = "✓" if path.exists() else "✗ missing"
        print(f"  {b}  {status}")

    print(f"\nBuilding types (--random):\n")
    print("  stone_house  — roof + upper_wall + lower_wall (184px wide)")
    print("  complete     — random pick from complete building sprites")
    print()


# ── Main entry ─────────────────────────────────────────────────────────────────

def generate_building(spec, out_dir):
    btype = spec.get("type")
    if btype == "stone_house":
        return build_stone_house(spec, out_dir)
    elif btype == "complete":
        return build_complete(spec, out_dir)
    else:
        raise ValueError(f"Unknown building type: '{btype}'. Expected 'stone_house' or 'complete'.")


def main():
    parser = argparse.ArgumentParser(description="Celadune Building Compositor")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--random", metavar="TYPE",
                       help="Building type to generate randomly: stone_house | complete")
    group.add_argument("--spec",   metavar="FILE",
                       help="JSON spec file with layer paths")
    group.add_argument("--list",   action="store_true",
                       help="List available parts and building types")

    parser.add_argument("--out",  metavar="DIR",  help="Output directory (required for --spec/--random)")
    parser.add_argument("--seed", metavar="INT",  type=int, help="Random seed for reproducibility")
    parser.add_argument("--name", metavar="NAME", help="Building name (stored in spec.json)")

    args = parser.parse_args()

    if args.list:
        list_parts()
        return

    if not args.out:
        parser.error("--out is required when generating a building")

    if args.spec:
        with open(args.spec) as f:
            spec = json.load(f)
        print(f"Building from spec: {args.spec}")
    else:
        btype = args.random.lower()
        if btype == "stone_house":
            print(f"Building random stone_house (seed={args.seed})...")
            spec = build_random_spec_stone_house(seed=args.seed, name=args.name)
        elif btype == "complete":
            print(f"Building random complete building (seed={args.seed})...")
            spec = build_random_spec_complete(seed=args.seed, name=args.name)
        else:
            parser.error(f"Unknown --random type '{args.random}'. Choose: stone_house | complete")

    print("\nSpec:")
    for k, v in spec.items():
        val = Path(v).name if isinstance(v, str) and v.endswith(".png") else v
        print(f"  {k}: {val}")
    print()

    generate_building(spec, args.out)


if __name__ == "__main__":
    main()
