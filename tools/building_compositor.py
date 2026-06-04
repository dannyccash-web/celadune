#!/usr/bin/env python3
"""
Building Compositor for Celadune — Layer-Based
Generates buildings by stacking pre-made PNG layers (base, upper floor, roof, door).

Assets live in assets/building-parts/v2/:
  Small_Base_1.png, Small_Base_2.png           (256×128)
  Large_Base_1.png, Large_Base_2.png           (320×128)
  Small_Upper_Floor_1.png, Small_Upper_Floor_2.png  (256×128)
  Large_Upper_Floor_1.png, Large_Upper_Floor_2.png  (320×128)
  Small_Roof_1.png, Small_Roof_2.png           (256×128)
  Large_Roof_1.png, Large_Roof_2.png           (320×128)
  Door_1.png                                   (96×128)

Building assembly (bottom to top):
  1. Base (small or large, random pick)
  2. Door composited onto the base at a random horizontal position
  3. Optional upper floor (50% chance, matching size class)
  4. Roof (matching size class)

Usage:
  python3 tools/building_compositor.py --random --seed 42 --name "Old Cottage" --out assets/buildings/old_cottage/
  python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/
  python3 tools/building_compositor.py --list

Output per building:
  building.png  — Single static RGBA PNG
  spec.json     — Full spec for exact reproduction
"""

import argparse
import json
import random
import sys
from pathlib import Path
from PIL import Image

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR  = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
PARTS_DIR   = PROJECT_DIR / "assets" / "building-parts" / "v2"

LAYER_HEIGHT = 128  # every layer is 128px tall
SMALL_WIDTH  = 256
LARGE_WIDTH  = 320
DOOR_WIDTH   = 96
DOOR_HEIGHT  = 128

# ── Asset catalogue ───────────────────────────────────────────────────────────

ASSETS = {
    "small_bases":   ["Small_Base_1.png", "Small_Base_2.png"],
    "large_bases":   ["Large_Base_1.png", "Large_Base_2.png"],
    "small_uppers":  ["Small_Upper_Floor_1.png", "Small_Upper_Floor_2.png"],
    "large_uppers":  ["Large_Upper_Floor_1.png", "Large_Upper_Floor_2.png"],
    "small_roofs":   ["Small_Roof_1.png", "Small_Roof_2.png"],
    "large_roofs":   ["Large_Roof_1.png", "Large_Roof_2.png"],
    "doors":         ["Door_1.png"],
}

# ── Helpers ───────────────────────────────────────────────────────────────────

_cache: dict[str, Image.Image] = {}

def load(filename: str) -> Image.Image:
    if filename not in _cache:
        path = PARTS_DIR / filename
        if not path.exists():
            raise FileNotFoundError(f"Asset not found: {path}")
        _cache[filename] = Image.open(path).convert("RGBA")
    return _cache[filename]


# ── Building generation ───────────────────────────────────────────────────────

def generate_building(spec: dict, out_dir: str) -> Path:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    size_class   = spec["size"]           # "small" or "large"
    base_file    = spec["base"]           # e.g. "Small_Base_1.png"
    door_file    = spec["door"]           # e.g. "Door_1.png"
    door_x       = spec["door_x"]         # pixel offset for door on base
    has_upper    = spec["has_upper_floor"]
    upper_file   = spec.get("upper_floor")  # None if no upper floor
    roof_file    = spec["roof"]

    width = SMALL_WIDTH if size_class == "small" else LARGE_WIDTH

    # Count layers to determine total height
    num_layers = 2  # base + roof always present
    if has_upper:
        num_layers = 3
    total_height = num_layers * LAYER_HEIGHT

    building = Image.new("RGBA", (width, total_height), (0, 0, 0, 0))

    # Stack from top to bottom: roof, [upper], base
    y = 0
    building.paste(load(roof_file), (0, y), load(roof_file))
    y += LAYER_HEIGHT

    if has_upper:
        building.paste(load(upper_file), (0, y), load(upper_file))
        y += LAYER_HEIGHT

    # Base layer
    base_img = load(base_file).copy()
    # Composite door onto base
    door_img = load(door_file)
    base_img.paste(door_img, (door_x, 0), door_img)
    building.paste(base_img, (0, y), base_img)

    # Scale if requested
    scale = spec.get("scale", 1.0)
    if scale != 1.0:
        new_w = round(building.width * scale)
        new_h = round(building.height * scale)
        building = building.resize((new_w, new_h), Image.LANCZOS)

    # Save
    bp = out / "building.png"
    sp = out / "spec.json"
    building.save(bp)

    export = {k: v for k, v in spec.items()}
    export["_size_px"] = f"{building.width}×{building.height}"
    with open(sp, "w") as f:
        json.dump(export, f, indent=2)

    print(f"  → {bp}  ({building.width}×{building.height}px)")
    return bp


# ── Random spec builder ───────────────────────────────────────────────────────

def build_random_spec(seed=None, name=None) -> dict:
    rng = random.Random(seed)

    size_class = rng.choice(["small", "large"])
    width = SMALL_WIDTH if size_class == "small" else LARGE_WIDTH

    if size_class == "small":
        base  = rng.choice(ASSETS["small_bases"])
        roof  = rng.choice(ASSETS["small_roofs"])
        upper = rng.choice(ASSETS["small_uppers"])
    else:
        base  = rng.choice(ASSETS["large_bases"])
        roof  = rng.choice(ASSETS["large_roofs"])
        upper = rng.choice(ASSETS["large_uppers"])

    door = rng.choice(ASSETS["doors"])
    has_upper = rng.random() < 0.5

    # Random door X: must fit within the base width
    max_door_x = width - DOOR_WIDTH
    door_x = rng.randint(0, max_door_x)

    spec = {
        "name":            name,
        "seed":            seed,
        "size":            size_class,
        "base":            base,
        "door":            door,
        "door_x":          door_x,
        "has_upper_floor": has_upper,
        "roof":            roof,
    }
    if has_upper:
        spec["upper_floor"] = upper

    return spec


# ── Part listing ──────────────────────────────────────────────────────────────

def list_parts():
    print(f"\nAsset library ({PARTS_DIR}):\n")
    for category, files in ASSETS.items():
        print(f"  {category}:")
        for f in files:
            path = PARTS_DIR / f
            exists = "✓" if path.exists() else "✗ MISSING"
            print(f"    {f}  {exists}")
    print(f"\nBuilding rules:")
    print(f"  Size:        50/50 small ({SMALL_WIDTH}px) or large ({LARGE_WIDTH}px)")
    print(f"  Upper floor: 50% chance")
    print(f"  Door:        {DOOR_WIDTH}×{DOOR_HEIGHT}px, random X placement")
    print(f"  Height:      256px (no upper) or 384px (with upper)")
    print()


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Celadune Building Compositor (layer-based)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--random", action="store_true", help="Generate a random building")
    group.add_argument("--spec",   metavar="FILE",      help="JSON spec file")
    group.add_argument("--list",   action="store_true", help="List available assets")

    parser.add_argument("--out",   metavar="DIR", help="Output directory")
    parser.add_argument("--seed",  metavar="INT", type=int)
    parser.add_argument("--name",  metavar="NAME")
    parser.add_argument("--scale", metavar="FLOAT", type=float, default=1.0,
                        help="Scale factor for final image (e.g. 1.5 = 50%% bigger)")

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

    if args.scale != 1.0:
        spec["scale"] = args.scale

    print("Spec:")
    for k, v in spec.items():
        if not k.startswith("_"):
            print(f"  {k}: {v}")
    print()

    generate_building(spec, args.out)


if __name__ == "__main__":
    main()
