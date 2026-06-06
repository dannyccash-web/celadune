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
- Hat: **10% chance** unless specified
- Hair: assigned only if **no hat** (hat covers hair)
- Back layer (cape/backpack/lantern): **10% chance** unless specified
- Gloves (arm_layer): **10% chance** unless specified
- Hand item: **10% chance** unless specified
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

## Building system (layer-based compositor)

### Asset library
- **Location:** assets/building-parts/v2/ — pre-scaled 1.5x PNG layers
  - Bases: Small_Base_1/2.png (384×192), Large_Base_1/2.png (480×192)
  - Upper floors: Small_Upper_Floor_1.png (384×192), Small_Upper_Floor_2.png (384×144), Large_Upper_Floor_1.png (480×192), Large_Upper_Floor_2.png (480×145) — varying heights
  - Roofs: Small_Roof_1/2/3/4.png (384×192), Large_Roof_1/2/3/4.png (480×192)
  - Doors: Door_1/2/3.png (144×192)
  - Windows: Window_1/2.png (384×144) — overlay for upper floor

### Compositor
- **Script:** tools/building_compositor.py
- **Random building:** `python3 tools/building_compositor.py --random --seed 42 --name "Old Cottage" --out assets/buildings/old_cottage/`
- **From spec:** `python3 tools/building_compositor.py --spec spec.json --out assets/buildings/my_building/`
- **List assets:** `python3 tools/building_compositor.py --list`
- **Output:** building.png (single static RGBA PNG, no runtime scaling), spec.json

### Building rules
- **Size class:** 50/50 random — small (384px wide) or large (480px wide)
- **Base:** random pick from matching size class (2 variants each)
- **Door:** 144×192px, composited onto base at random X position
- **Upper floor:** always present; matching size class (varying heights: 144–192px)
- **Window:** random pick from 2 variants, overlaid centered on upper floor
- **Roof:** always present; random pick from matching size class (4 variants each), sits flush on upper floor
- **Final height:** varies by upper floor height (528–576px)

### Adding a new building to the game
1. Generate: `python3 tools/building_compositor.py --random --seed N --name "Name" --out assets/buildings/my_building/`
2. Load in `preload()`: `this.load.image('myBuilding', 'assets/buildings/my_building/building.png')`
3. Place in scene: `this.add.image(x, y, 'myBuilding').setOrigin(0.5, 1).setDepth(8)`

### Expanding the asset library
Drop new PNGs into assets/building-parts/v2/ following the naming convention (e.g. Small_Base_3.png, Door_4.png) and add the filename to the ASSETS dict in building_compositor.py.

## Key scene info
- **PrototypeScene** = forest/overworld scene (first scene after hero select)
  - Hut at x=2240, Mirelle (forestLady) patrols x=2420–2660
  - Aldric (hutWanderer) patrols x=1860–2170, in front of the hut
- **CityScene** = city scene (reached by walking right off the forest map)
- **HutInteriorScene** = inside Mirelle's hut (entered via hut door)

## Cache busting
main.js is loaded with a `?v=N` query string in index.html. Bump the version
number whenever making significant changes so users don't get stale cached JS.
Current version: v=23
