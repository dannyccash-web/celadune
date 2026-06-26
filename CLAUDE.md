# Celadune — Project Context (fresh rebuild)

A clean Godot 4.6 platformer foundation. Built so that walls, floors, doors,
room transitions, and the character controller already work — leaving story,
world, and content as the main work.

## Repository
- **GitHub:** https://github.com/dannyccash-web/celadune
- **Live site:** https://dannyccash-web.github.io/celadune/
- **Deploy:** GitHub Actions (`.github/workflows/deploy.yml`) builds the project
  headless with Godot 4.6.1 and publishes `web-build/` to Pages on push to `main`
  (~2-3 min).

## Tech stack
- **Engine:** Godot 4.6.1, GL Compatibility renderer (best for web).
- **Entry point:** `scenes/Game.tscn` → `scripts/Game.gd`.
- **Autoload:** `scripts/Globals.gd` (cross-room state, abilities, spawn target).

## Architecture (how the pieces fit)
- **Game.gd** extends MetSys's `MetSysGame`. It owns the persistent **Player**
  (NOT a child of any room, so it survives transitions) and lets MetSys swap rooms
  in/out as the player crosses the world grid. The `ScrollingRoomTransitions`
  module does the actual room swap + camera scroll.
- **Player.gd** is a complete platformer controller: run w/ acceleration,
  variable-height jump, coyote time, jump buffering, double jump, wall slide,
  wall jump, dash. Tune the constants at the top — never the logic. Abilities are
  gated through `Globals.abilities` so you can unlock them as the game progresses.
- **Rooms** (`scenes/rooms/`) are plain scenes made of `StaticBody2D` platforms
  (collision = floors/walls) plus tiling `Sprite2D` visuals. Each room has a
  **`RoomInstance`** node (registers it with MetSys) and a stable scene **UID**.
  The room's open edges are where the player crosses into the next cell.
- **Transitions are edge-based** — no hand-placed doors. Walk off the open edge of
  a room into an adjacent grid cell that holds a different scene, and MetSys
  scrolls the next room in. (`Door.gd`/`Door.tscn` still exist, unused, if you
  ever want explicit doorways again.)

### Add a new room (the map-driven way)
1. Duplicate `scenes/rooms/Room2.tscn`, rename the root node, give it a fresh
   scene **UID** (Godot does this when you Save As).
2. Lay out `StaticBody2D` platforms; leave the edge(s) open where it connects.
3. In Godot, **Project Settings > Plugins > enable MetSys**, open the **Map** tab,
   draw a new cell next to an existing one, and **assign your new scene** to it.
   Open the shared border so the player can cross. That's it — the transition works.
4. (Text alternative) add a `[x,y,z]` cell block in `world/MapData.txt` whose
   scene line is your room's `uid://...`, matching the pattern already there.

## Controls
Move: A/D or arrows · Jump: Space/W · Dash: Shift · Talk: E · Travel: walk off the screen edge

## Dialogue & NPCs (write story without code)
- **Dialogue.gd** is an autoload that shows a bottom text box, types lines out,
  advances on E/Space, and pauses the game while open. Call it from anywhere:
  `Dialogue.start("Eldrin", ["Line one.", "Line two."], on_done)`.
- **NPC.tscn / NPC.gd** is a talkable character. Drop it in a room and fill in
  the Inspector — no scripting:
  - `Speaker Name`, `Lines` (one entry per text-box line).
  - `Set Flag On End` — story flag set when the talk finishes.
  - `Gate Flag` + `Lines After` — if the flag is set, the NPC says `Lines After`
    instead, so characters can react to what the player has done.
- **Story flags** live in `Globals` (`set_flag` / `has_flag`). Use them to gate
  dialogue, doors, or anything else. The example NPC "Eldrin" in Room1 shows the
  pattern (sets `met_eldrin`, then greets you differently next time).

## MetroidvaniaSystem (MetSys) — the world-map layer (now ACTIVE)
The MIT framework by KoBeWi is installed under `addons/MetroidvaniaSystem/` and is
now the backbone of the game at runtime (autoloaded as `MetSys`). It drives room
transitions and will power the minimap/save features when we add them.

- **Runtime** needs only the `MetSys` autoload — no editor plugin required for the
  web build. Settings: `world/MetSysSettings.tres` (theme + `in_game_cell_size`
  = 1280×720, matching one screen per cell) → `world/MapData.txt` (the world grid).
- **To edit the world visually**, open the project in Godot and enable the **MetSys**
  plugin (Project Settings > Plugins). A **Map** tab appears: draw cells, assign
  room scenes, open borders. Saving writes `world/MapData.txt`.
- The two starter cells `[0,0,0]`→Room1 and `[1,0,0]`→Room2 (connected on their
  shared border) are the working example.
- Transition style: `Game.gd` uses `ScrollingRoomTransitions`. Swap to
  `RoomTransitions` (instant cut) by changing the one `add_module(...)` line.
- Wiki: https://github.com/KoBeWi/Metroidvania-System/wiki

## Art
Placeholder pixel art (player, tiles, door) is generated programmatically and
lives in `assets/`. Replace the PNGs with real art any time — `Player.gd` builds
its animations from `assets/sprites/player_*.png` at runtime, so just keep the
frame counts (idle 2, run 4, jump 1) or update them in `_build_animations()`.

## Git workflow
**CRITICAL:** Never run git from the FUSE-mounted project path. Always clone to
`/tmp`, copy changed files in, then commit and push:
```bash
rm -rf /tmp/celadune_push
git clone https://<token>@github.com/dannyccash-web/celadune.git /tmp/celadune_push
# copy changed files into /tmp/celadune_push/
cd /tmp/celadune_push
git config user.email "dannyccash@gmail.com"
git config user.name "Danny Cash"
git add -A && git commit -m "..." && git push origin main
```
Token is embedded in the `.git/config` remote URL.
