#!/usr/bin/env python3
"""
NPC Compositor for Celadune
Composites GandalfHardcore sprite part layers into Phaser-ready spritesheets.

Usage:
  python3 npc_compositor.py --spec spec.json --out assets/npcs/my_npc/
  python3 npc_compositor.py --random random --out assets/npcs/my_npc/
  python3 npc_compositor.py --random male --out assets/npcs/my_npc/
  python3 npc_compositor.py --list              # list all available parts

The compositor produces two files:
  walk.png  — 8-frame walk animation strip (single row, 64×64 frames)
  idle.png  — 5-frame idle animation strip (single row, 64×64 frames)
  spec.json — the parts manifest used to generate this NPC (for reproducibility)

IMPORTANT — sprite orientation:
  GandalfHardcore sprites face LEFT by default (no flip).
  In Phaser: setFlipX(true) when moving RIGHT, setFlipX(false) when moving LEFT.

Layer compositing order (back to front):
  back_layer → skin → clothing → arm_layer → hand_item → hair → hat
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

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
PARTS_DIR   = PROJECT_DIR / "assets" / "npc-parts"
NPCS_DIR    = PROJECT_DIR / "assets" / "npcs"

# Output frame size (each animation frame will be padded/centred to this)
FRAME_W = 64
FRAME_H = 64

# Which rows to pull from the raw spritesheet (0-indexed)
# Row 1 (index 1): 8-frame walk cycle
# Row 0 (index 0): 5-frame slow-walk — reads as a natural idle sway at low framerate
WALK_ROW_INDEX = 1   # 8 frames
IDLE_ROW_INDEX = 0   # 5 frames

# ── Frame-grid detection ───────────────────────────────────────────────────────

def detect_frame_grid(img_array):
    """
    Auto-detects the irregular frame grid from the alpha channel.
    Returns (col_regions, row_regions) where each region is (start_px, end_px).
    """
    h, w = img_array.shape[:2]

    def find_content_regions(axis_sum):
        """Find contiguous runs of non-zero values separated by zero gaps."""
        nonzero = axis_sum > 0
        regions = []
        in_region = False
        start = 0
        for i, v in enumerate(nonzero):
            if v and not in_region:
                start = i
                in_region = True
            elif not v and in_region:
                regions.append((start, i - 1))
                in_region = False
        if in_region:
            regions.append((start, len(nonzero) - 1))
        return regions

    col_sums = img_array[:, :, 3].sum(axis=0)
    row_sums = img_array[:, :, 3].sum(axis=1)
    col_regions = find_content_regions(col_sums)
    row_regions = find_content_regions(row_sums)
    return col_regions, row_regions


def count_frames_in_row(img_array, row_region, col_regions):
    """Count non-empty frames in a given row region."""
    ry1, ry2 = row_region
    count = 0
    for cx1, cx2 in col_regions:
        region = img_array[ry1:ry2 + 1, cx1:cx2 + 1, 3]
        if region.sum() > 0:
            count += 1
    return count


def extract_row_frames(img, row_region, col_regions, frame_w, frame_h):
    """
    Extract all non-empty frames from a row, centre each in a frame_w×frame_h canvas,
    aligning feet to the bottom.
    Returns a list of RGBA PIL Images.
    """
    ry1, ry2 = row_region
    frames = []
    for cx1, cx2 in col_regions:
        crop = img.crop((cx1, ry1, cx2 + 1, ry2 + 1))
        arr = np.array(crop)
        if arr[:, :, 3].sum() == 0:
            continue  # skip empty columns

        # Trim transparent border from crop for tight bounds
        rows_with_alpha = np.any(arr[:, :, 3] > 0, axis=1)
        cols_with_alpha = np.any(arr[:, :, 3] > 0, axis=0)
        r_start = np.argmax(rows_with_alpha)
        r_end   = len(rows_with_alpha) - np.argmax(rows_with_alpha[::-1]) - 1
        c_start = np.argmax(cols_with_alpha)
        c_end   = len(cols_with_alpha) - np.argmax(cols_with_alpha[::-1]) - 1
        tight = crop.crop((c_start, r_start, c_end + 1, r_end + 1))

        # Place on frame canvas: centre horizontally, bottom-align (feet at bottom-4px)
        canvas = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
        paste_x = (frame_w - tight.width) // 2
        paste_y = frame_h - tight.height - 2  # 2px floor gap
        canvas.paste(tight, (paste_x, max(0, paste_y)), tight)
        frames.append(canvas)
    return frames


# ── Layer compositing ──────────────────────────────────────────────────────────

LAYER_ORDER = [
    ('back_layer',   None),   # behind everything
    ('skin',         None),   # base body
    ('boots',        None),   # footwear — under pants/skirt so dress covers boot tops
    ('pants',        None),   # lower body clothing (covers boot tops)
    ('shirt',        None),   # upper body clothing
    ('clothing',     None),   # legacy single-item clothing (or full outfit pieces)
    ('arm_layer',    None),   # gloves overlaid on arms
    ('hand_item',    None),   # held item
    ('hair',         None),   # hair over body
    ('hat',          None),   # hat over hair
]

def composite_layers(spec):
    """
    Given a spec dict (keys matching LAYER_ORDER[*][0]), return a composited PIL Image.
    Each value is either None (skip) or a file path string.
    """
    base = None

    for layer_key, _ in LAYER_ORDER:
        path = spec.get(layer_key)
        if not path:
            continue
        layer_img = Image.open(path).convert('RGBA')
        if base is None:
            base = Image.new('RGBA', layer_img.size, (0, 0, 0, 0))
        # If sizes differ (back_layers can be 720 vs 800 wide), paste at origin
        if layer_img.size != base.size:
            padded = Image.new('RGBA', base.size, (0, 0, 0, 0))
            padded.paste(layer_img, (0, 0))
            layer_img = padded
        base = Image.alpha_composite(base, layer_img)

    if base is None:
        raise ValueError("Spec produced no layers")
    return base


# ── Spritesheet builder ────────────────────────────────────────────────────────

def build_strip(frames):
    """Stack frames horizontally into a single PNG strip."""
    if not frames:
        raise ValueError("No frames to build strip from")
    strip = Image.new('RGBA', (FRAME_W * len(frames), FRAME_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * FRAME_W, 0))
    return strip


def generate_npc(spec, out_dir):
    """
    Main entry: composite layers, extract walk + idle rows, save spritesheets.
    Returns a dict with metadata about the generated NPC.
    """
    out_path = Path(out_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    print(f"Compositing layers...")
    composite = composite_layers(spec)
    arr = np.array(composite)

    print(f"Detecting frame grid...")
    col_regions, row_regions = detect_frame_grid(arr)
    print(f"  Found {len(col_regions)} cols × {len(row_regions)} rows")

    # Validate we have enough rows
    if len(row_regions) <= max(WALK_ROW_INDEX, IDLE_ROW_INDEX):
        raise ValueError(f"Expected at least {max(WALK_ROW_INDEX, IDLE_ROW_INDEX)+1} rows, got {len(row_regions)}")

    walk_row = row_regions[WALK_ROW_INDEX]
    idle_row = row_regions[IDLE_ROW_INDEX]

    walk_count = count_frames_in_row(arr, walk_row, col_regions)
    idle_count = count_frames_in_row(arr, idle_row, col_regions)
    print(f"  Walk row: {walk_count} frames  |  Idle row: {idle_count} frames")

    print(f"Extracting walk frames...")
    walk_frames = extract_row_frames(composite, walk_row, col_regions, FRAME_W, FRAME_H)
    print(f"Extracting idle frames...")
    idle_frames = extract_row_frames(composite, idle_row, col_regions, FRAME_W, FRAME_H)

    walk_strip = build_strip(walk_frames)
    idle_strip = build_strip(idle_frames)

    walk_path = out_path / "walk.png"
    idle_path = out_path / "idle.png"
    spec_path = out_path / "spec.json"

    walk_strip.save(walk_path)
    idle_strip.save(idle_path)

    output_spec = {**spec, '_walk_frames': len(walk_frames), '_idle_frames': len(idle_frames)}
    # Convert Path objects to strings for JSON
    output_spec = {k: str(v) if isinstance(v, Path) else v for k, v in output_spec.items()}
    with open(spec_path, 'w') as f:
        json.dump(output_spec, f, indent=2)

    print(f"\nGenerated NPC in {out_path}")
    print(f"  walk.png  — {len(walk_frames)} frames @ {FRAME_W}×{FRAME_H}")
    print(f"  idle.png  — {len(idle_frames)} frames @ {FRAME_W}×{FRAME_H}")

    return {
        'walk_frames': len(walk_frames),
        'idle_frames': len(idle_frames),
        'frame_w': FRAME_W,
        'frame_h': FRAME_H,
    }


# ── Random NPC builder ─────────────────────────────────────────────────────────

def pick_random(folder, rng=None):
    """Pick a random PNG from a folder (None if folder empty)."""
    files = [f for f in Path(folder).glob('*.png') if f.is_file()]
    # Exclude utility images
    files = [f for f in files if 'DONT FORGET' not in f.name and 'Links' not in f.name]
    if not files:
        return None
    return str(random.choice(files) if rng is None else rng.choice(files))


def build_random_spec(gender='random', seed=None):
    """Build a random NPC spec for the given gender ('male', 'female', or 'random')."""
    rng = random.Random(seed)

    # Gender — random 50/50 unless specified
    if gender.lower() == 'random':
        suffix = rng.choice(['male', 'female'])
    else:
        suffix = gender.lower()

    # Skin — random from matching gender pool
    skin_files = list((PARTS_DIR / 'skin').glob(f'*{suffix.capitalize()}*.png'))
    skin = str(rng.choice(skin_files)) if skin_files else None

    # Clothing — pick shirt, pants, and boots separately
    # 'Split hose' is medieval leggings → pants, not shirts
    clothing_dir = PARTS_DIR / f'clothing_{suffix}'
    all_clothing = [f for f in clothing_dir.glob('*.png')
                    if 'DONT' not in f.name and 'Links' not in f.name
                    and 'Underwear' not in f.name and 'Panties' not in f.name and 'Bra' not in f.name
                    and 'swim trunks' not in f.name]

    shirt_keywords = ['Shirt', 'Chainmail', 'Corset']
    pants_keywords = ['Pants', 'Skirt', 'hose', 'Split']
    boots_keywords = ['Boot', 'Shoe', 'Sock']

    shirt_files = [f for f in all_clothing if any(x in f.name for x in shirt_keywords)]
    pants_files = [f for f in all_clothing if any(x in f.name for x in pants_keywords)]
    boots_files = [f for f in all_clothing if any(x in f.name for x in boots_keywords)]

    # All shirts (including plain white) are in the random pool
    shirt = str(rng.choice(shirt_files)) if shirt_files else None
    pants = str(rng.choice(pants_files)) if pants_files else None
    boots = str(rng.choice(boots_files)) if boots_files else None
    clothing = None  # legacy field unused in random gen

    # Hair — always assigned, full random across all styles
    hair_files = [f for f in (PARTS_DIR / f'hair_{suffix}').glob('*.png')]
    hair = str(rng.choice(hair_files)) if hair_files else None

    # Hat — 10% chance
    hat = None
    if rng.random() < 0.10:
        hat_files = list((PARTS_DIR / f'hats_{suffix}').glob('*.png'))
        hat = str(rng.choice(hat_files)) if hat_files else None

    # Back layer — 10% chance (cape, backpack, lantern)
    back_layer = None
    if rng.random() < 0.10:
        back_files = list((PARTS_DIR / 'back_layers').glob('*.png'))
        friendly = [f for f in back_files if 'Cape' in f.name or 'Backpack' in f.name or 'Lantern' in f.name]
        back_pool = friendly if friendly else back_files
        back_layer = str(rng.choice(back_pool)) if back_pool else None

    # Arm layer (gloves) — 10% chance
    arm_layer = None
    if rng.random() < 0.10:
        arm_files = list((PARTS_DIR / f'arm_layers_{suffix}').glob('*.png'))
        arm_layer = str(rng.choice(arm_files)) if arm_files else None

    # Hand item — OFF by default; only assigned if explicitly specified in a spec
    hand_item = None

    return {
        'gender': suffix,
        'seed': seed,
        'skin': skin,
        'pants': pants,
        'shirt': shirt,
        'boots': boots,
        'clothing': clothing,
        'hair': hair,
        'hat': hat,
        'back_layer': back_layer,
        'arm_layer': arm_layer,
        'hand_item': hand_item,
    }


# ── Part listing ───────────────────────────────────────────────────────────────

def list_parts():
    """Print a summary of all available parts."""
    if not PARTS_DIR.exists():
        print(f"Parts directory not found: {PARTS_DIR}")
        return
    print(f"\nAvailable NPC parts ({PARTS_DIR}):\n")
    for folder in sorted(PARTS_DIR.iterdir()):
        if folder.is_dir():
            files = sorted(f.stem for f in folder.glob('*.png') if 'DONT' not in f.name)
            print(f"  {folder.name}/  ({len(files)} parts)")
            for f in files[:8]:
                print(f"    {f}")
            if len(files) > 8:
                print(f"    ... and {len(files)-8} more")
    print()


# ── CLI ────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='Celadune NPC Compositor')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--spec',   metavar='FILE',   help='JSON spec file with layer paths')
    group.add_argument('--random', metavar='GENDER', help='Generate random NPC (male/female)')
    group.add_argument('--list',   action='store_true', help='List available parts')

    parser.add_argument('--out',  metavar='DIR',  help='Output directory (required for --spec/--random)')
    parser.add_argument('--seed', metavar='INT',  type=int, help='Random seed for reproducibility')
    parser.add_argument('--name', metavar='NAME', help='NPC name (stored in spec.json)')

    args = parser.parse_args()

    if args.list:
        list_parts()
        return

    if not args.out:
        parser.error('--out is required when generating an NPC')

    if args.spec:
        with open(args.spec) as f:
            spec = json.load(f)
    else:
        gender = args.random.lower()
        if gender not in ('male', 'female', 'random'):
            parser.error('--random must be "male", "female", or "random"')
        print(f"Building random {gender} NPC (seed={args.seed})...")
        spec = build_random_spec(gender=gender, seed=args.seed)
        if args.name:
            spec['name'] = args.name

    print("\nSpec:")
    for k, v in spec.items():
        if v and k not in ('seed', 'gender', 'name', '_walk_frames', '_idle_frames'):
            print(f"  {k}: {Path(v).name if isinstance(v, str) else v}")
        else:
            print(f"  {k}: {v}")

    generate_npc(spec, args.out)


if __name__ == '__main__':
    main()
