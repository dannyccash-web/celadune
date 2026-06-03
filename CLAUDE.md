# Celadune — Project Context

## Repository
- **GitHub:** https://github.com/dannyccash-web/celadune
- **Live site:** https://dannyccash-web.github.io/celadune/
- **Deploy:** GitHub Pages (auto-deploys from `main` branch, ~1-2 min delay)

## Git workflow
After making any changes to the project, commit and push to GitHub so the live site updates:

```bash
cd ~/Documents/Claude/Projects/Celadune
git add -A
git commit -m "<description of changes>"
git push origin main
```

If the push is rejected due to a stale lock file, remove it first:
```bash
rm ~/Documents/Claude/Projects/Celadune/.git/refs/remotes/origin/main.lock
```

## GitHub credentials
- Token is stored in macOS Keychain / git credential manager — no manual entry needed after first push.
- If prompted, use your GitHub username + a Personal Access Token (Settings → Developer settings → Personal access tokens).

## Tech stack
- **Engine:** Phaser 3 (loaded from CDN in index.html)
- **Entry point:** main.js (single file, all scenes)
- **Assets:** assets/ folder — sprites, audio, tiles, UI, NPCs
- **No build step** — plain JS served as static files via GitHub Pages

## NPC system (GandalfHardcore modular sprites)

### Parts library
- **Location:** assets/npc-parts/ — 13 categories, ~256 PNGs total
  - skin/ (10: Male Skin1–5, Female Skin1–5)
  - hair_male/ (33), hair_female/ (35)
  - hats_male/ (22), hats_female/ (19)
  - clothing_male/ (26), clothing_female/ (24)
  - back_layers/ (11: capes, backpacks, shields, lanterns — gender-neutral)
  - arm_layers_male/ (7), arm_layers_female/ (7) — gloves
  - hand_items_male/ (18), hand_items_female/ (20) — weapons, tools, flowers
  - character_effects/ (24: blood, buff, debuff, hearts, stars, lines — runtime overlays, not used in compositor)

### Compositor
- **Script:** tools/npc_compositor.py
- **Random NPC (random gender):** `python3 tools/npc_compositor.py --random random --seed 42 --name "Name" --out assets/npcs/my_npc/`
- **Random NPC (specific gender):** `python3 tools/npc_compositor.py --random male --seed 42 --name "Aldric" --out assets/npcs/my_npc/`
- **From spec:** `python3 tools/npc_compositor.py --spec spec.json --out assets/npcs/my_npc/`
- **List parts:** `python3 tools/npc_compositor.py --list`
- **Output:** walk.png (8 frames, 64×64), idle.png (5 frames, 64×64), spec.json

### Layer order (back → front)
back_layer → skin → boots → pants → shirt → clothing → arm_layer → hand_item → hair → hat

### Random generation rules
- Gender: randomly chosen (50/50) unless `--random male` or `--random female` is specified
- Skin: randomly chosen from matching gender pool
- Shirt: full pool including plain white variants
- Hair: always assigned
- Hat: **10% chance** unless specified
- Back layer (cape/backpack/lantern): **10% chance** unless specified
- Gloves (arm_layer): **10% chance** unless specified
- Hand item: **OFF by default** — only assigned if explicitly set in a spec
- Boots always assigned; pants always assigned

### Sprite orientation
GandalfHardcore sprites face **LEFT** by default.
- `setFlipX(true)` when moving RIGHT
- `setFlipX(false)` when moving left

### Animation format
Single-row strips (not LPC grid). Use `createGandalfNpcAnimations` helper in main.js.
- walk.png: 8 frames → `${key}-walk` animation, frameRate 10
- idle.png: 5 frames → `${key}-idle` animation, frameRate 4
- Direction handled by setFlipX, NOT separate left/right animation keys

### Existing NPCs
| NPC | Key | Asset folder | Seed | Notes |
|-----|-----|-------------|------|-------|
| Mirelle | forestLady | assets/npcs/forest_lady/ | custom | Silver hair recolored; red corset, white skirt |
| Aldric | hutWanderer | assets/npcs/hut_wanderer/ | 42 | Patrols x=1860–2170 in front of hut |
| Bram Alder | npcCity1 | assets/npcs/npc_city_1/ | 117 | City NPC |
| Ysra Thorn | npcCity2 | assets/npcs/npc_city_2/ | 200 | City NPC, female |
| Teren Vale | npcCity3 | assets/npcs/npc_city_3/ | 124 | City NPC |
| Padrig | npcTavernChef | assets/npcs/npc_tavern_chef/ | 141 | Tavern chef |

### Adding a new NPC to the game
1. Generate sprite: `python3 tools/npc_compositor.py --random random --seed N --name "Name" --out assets/npcs/my_npc/`
2. Add a config constant like `HUT_WANDERER` in main.js
3. Call `createGandalfNpcAnimations(this, config)` in `createAnimations()`
4. Load spritesheets in `preload()` with frameWidth: 64, frameHeight: 64
5. Spawn sprite, set depth 8, play idle anim, setFlipX(true) to start facing right
6. Add patrol logic following the `updateHutWanderer()` pattern

### Depth hierarchy
- Player: depth 10
- All NPCs: depth 8
- Props (hut, wagon): depth 7
- Ground front tiles: depth 12

## Building system (GandalfHardcore modular buildings)

### Source sheets
- `assets/House Tiles.png` — Two stone house variants (each 184×224px, 32px tile grid)
- `assets/House outside Tiles 32x32 v2.png` — Two complete hall buildings + parts strip

### Parts library
- **Location:** assets/building-parts/
  - roofs/ (2: roof_stone_v1, roof_stone_v2 — 184×64px each)
  - walls/ (6: wall_stone_upper_v1/v2 — 184×96px; wall_stone_lower_v1/v2 — 184×64px; wall_teal_wide — 96×96px; wall_teal_narrow — 64×64px)
  - accessories/ (1: column_capital — 32×48px)
- **Complete sprites:** assets/buildings/ — open_hall.png, stone_hall.png, stone_house_v1.png, stone_house_v2.png

### Compositor
- **Script:** tools/building_compositor.py
- **Random stone house:** `python3 tools/building_compositor.py --random stone_house --seed 42 --name "Old Cottage" --out assets/buildings/my_building/`
- **Random complete building:** `python3 tools/building_compositor.py --random complete --seed 7 --out assets/buildings/my_building/`
- **From spec:** `python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/`
- **List parts:** `python3 tools/building_compositor.py --list`
- **Output:** building.png (single static RGBA PNG), spec.json

### Layer order for stone_house (top → bottom)
roof → upper_wall → lower_wall

All stone_house parts are **184px wide** — required for vertical stacking to work. Parts from different families (teal panels at 96px/64px) cannot be mixed with stone_house parts.

### Building types
- `stone_house` — composited from interchangeable parts; all parts must be 184px wide
- `complete` — random pick from a pre-assembled sprite (open_hall, stone_hall, stone_house_v1/v2)

### Adding a new building to the game
1. Generate sprite: `python3 tools/building_compositor.py --random stone_house --seed N --name "Name" --out assets/buildings/my_building/`
2. Load the image in `preload()`: `this.load.image('myBuilding', 'assets/buildings/my_building/building.png')`
3. Place in scene: `this.add.image(x, y, 'myBuilding').setDepth(7).setOrigin(0.5, 1)`
4. Depth 7 = props layer (same as hut, wagon)

### Expanding the parts library
To add new parts: drop PNGs into the appropriate subfolder under assets/building-parts/. Width must match the family (184px for stone_house). The compositor picks randomly from all files in each subfolder, so new parts are available immediately with no code changes.

## Key scene info
- **PrototypeScene** = forest/overworld scene (first scene after hero select)
  - Hut at x=2240, Mirelle (forestLady) patrols x=2420–2660
  - Aldric (hutWanderer) patrols x=1860–2170, in front of the hut
- **CityScene** = city scene (reached by walking right off the forest map)
- **HutInteriorScene** = inside Mirelle's hut (entered via hut door)

## Cache busting
main.js is loaded with a `?v=N` query string in index.html. Bump the version
number whenever making significant changes so users don't get stale cached JS.
Current version: v=17
