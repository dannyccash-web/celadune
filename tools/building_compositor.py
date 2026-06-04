#!/usr/bin/env python3
"""
Building Compositor for Celadune — Layer-Based (v2)
Generates buildings by stacking pre-made PNG layers (base, upper floor, roof, door, window).

All assets are pre-scaled at 1.5x and live in assets/building-parts/v2/:
  Small_Base_1/2.png              (384×192)
  Large_Base_1/2.png              (480×192)
  Small_Upper_Floor_1.png         (384×192)
  Small_Upper_Floor_2.png         (384×144)   ← shorter variant
  Large_Upper_Floor_1.png         (480×192)
  Large_Upper_Floor_2.png         (480×145)   ← shorter variant
  Small_Roof_1/2/3/4.png          (384×192)
  Large_Roof_1/2/3/4.png          (480×192)
  Door_1/2/3.png                  (144×192)
  Window_1/2.png                  (384×144)   ← overlay for upper floor

Building assembly (bottom to top in the final image):
  1. Base (small or large, random pick)
  2. Door composited onto the base at a random horizontal position
  3. Upper floor (always present, matching size class)
  4. Window composited onto the upper floor
  5. Roof (matching size class) — sits flush on top of the upper floor

Upper floors have varying heights, so total building height depends on
which upper floor is chosen.

Usage:
  python3 tools/building_compositor.py --random --seed 42 --name "Old Cottage" --out assets/buildings/old_cottage/
  python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/
  python3 tools/building_compositor.py --list

Output per building:
  building.png  — Single static RGBA PNG (no additional scaling needed)
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

SMALL_WIDTH  = 384
LARGE_WIDTH  = 480
BASE_HEIGHT  = 192
ROOF_HEIGHT  = 192
DOOR_WIDTH   = 144
DOOR_HEIGHT  = 192
WINDOW_WIDTH = 384  # window overlays are sized for small buildings

# ── Asset catalogue ───────────────────────────────────────────────────────────

ASSETS = {
    "small_bases":   ["Small_Base_1.png", "Small_Base_2.png"],
    "large_bases":   ["Large_Base_1.png", "Large_Base_2.png"],
    "small_uppers":  ["Small_Upper_Floor_1.png", "Small_Upper_Floor_2.png"],
    "large_uppers":  ["Large_Upper_Floor_1.png", "Large_Upper_Floor_2.png"],
    "small_roofs":   ["Small_Roof_1.png", "Small_Roof_2.png", "Small_Roof_3.png", "Small_Roof_4.png"],
    "large_roofs":   ["Large_Roof_1.png", "Large_Roof_2.png", "Large_Roof_3.png", "Large_Roof_4.png"],
    "doors":         ["Door_1.png", "Door_2.png", "Door_3.png"],
    "windows":       ["Window_1.png", "Window_2.png"],
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
    base_file    = spec["base"]
    door_file    = spec["door"]
    door_x       = spec["door_x"]
    upper_file   = spec["upper_floor"]
    window_file  = spec["window"]
    roof_file    = spec["roof"]

    width = SMALL_WIDTH if size_class == "small" else LARGE_WIDTH

    # Upper floors have varying heights — read the actual image height
    upper_img = load(upper_file).copy()
    upper_height = upper_img.height

    # Total height = roof + upper floor + base
    total_height = ROOF_HEIGHT + upper_height + BASE_HEIGHT

    building = Image.new("RGBA", (width, total_height), (0, 0, 0, 0))

    # Stack from top to bottom: roof, upper floor (with window), base (with door)
    y = 0

    # Roof
    building.paste(load(roof_file), (0, y), load(roof_file))
    y += ROOF_HEIGHT

    # Upper floor with window overlay
    window_img = load(window_file)
    # Center window horizontally on the upper floor
    window_x = (width - window_img.width) // 2
    # Align window to the bottom of the upper floor layer
    window_y = upper_height - window_img.height
    if window_y < 0:
        window_y = 0
    upper_img.paste(window_img, (window_x, window_y), window_img)
    building.paste(upper_img, (0, y), upper_img)
    y += upper_height

    # Base layer with door
    base_img = load(base_file).copy()
    door_img = load(door_file)
    base_img.paste(door_img, (door_x, 0), door_img)
    building.paste(base_img, (0, y), base_img)

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

    door   = rng.choice(ASSETS["doors"])
    window = rng.choice(ASSETS["windows"])

    # Random door X: must fit within the base width
    max_door_x = width - DOOR_WIDTH
    door_x = rng.randint(0, max_door_x)

    return {
        "name":        name,
        "seed":        seed,
        "size":        size_class,
        "base":        base,
        "door":        door,
        "door_x":      door_x,
        "upper_floor": upper,
        "window":      window,
        "roof":        roof,
    }


# ── Part listing ──────────────────────────────────────────────────────────────

def list_parts():
    print(f"\nAsset library ({PARTS_DIR}):\n")
    for category, files in ASSETS.items():
        print(f"  {category}:")
        for f in files:
            path = PARTS_DIR / f
            if path.exists():
                img = Image.open(path)
                print(f"    {f}  ✓  {img.width}×{img.height}")
            else:
                print(f"    {f}  ✗ MISSING")
    print(f"\nBuilding rules:")
    print(f"  Size:        50/50 small ({SMALL_WIDTH}px) or large ({LARGE_WIDTH}px)")
    print(f"  Upper floor: always present (varying heights)")
    print(f"  Window:      overlaid on upper floor")
    print(f"  Door:        {DOOR_WIDTH}×{DOOR_HEIGHT}px, random X placement")
    print(f"  Assets are pre-scaled — no runtime scaling applied")
    print()


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Celadune Building Compositor (layer-based v2)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--random", action="store_true", help="Generate a random building")
    group.add_argument("--spec",   metavar="FILE",      help="JSON spec file")
    group.add_argument("--list",   action="store_true", help="List available assets")

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
