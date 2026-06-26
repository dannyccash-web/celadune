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
- **Game.gd** owns the persistent **Player** and swaps **room** scenes in/out of
  a `World` node. The player is NOT a child of any room, so it survives
  transitions.
- **Player.gd** is a complete platformer controller: run w/ acceleration,
  variable-height jump, coyote time, jump buffering, double jump, wall slide,
  wall jump, dash. Tune the constants at the top — never the logic. Abilities are
  gated through `Globals.abilities` so you can unlock them as the game progresses.
- **Door.gd** (Area2D) connects rooms. Set `target_room` (a .tscn path) and
  `target_spawn` (a Marker2D name in that room). Press **E** in the doorway, or
  set `auto_enter = true` for walk-through screen-edge passages.
- **Rooms** (`scenes/rooms/`) are plain scenes made of `StaticBody2D` platforms
  (collision = floors/walls) plus tiling `Sprite2D` visuals, `Marker2D` spawn
  points, and one or more `Door` instances.

### Add a new room
1. Duplicate `scenes/rooms/Room2.tscn`, rename the root node.
2. Lay out `StaticBody2D` platforms (each: a `CollisionShape2D` + a `Sprite2D`).
3. Add `Marker2D` spawn points; name them to match the doors that target them.
4. Add a `Door` instance; set `target_room` + `target_spawn`.

## Controls
Move: A/D or arrows · Jump: Space/W · Dash: Shift · Use door: E

## MetroidvaniaSystem (MetSys) — the world-map layer
The MIT framework by KoBeWi is installed under `addons/MetroidvaniaSystem/`
(map editor, room/transition system, minimap, save data). It is **not enabled by
default** so the web build has zero dependency on it.

To use the in-editor Map Editor for designing the interconnected world:
1. Open the project in Godot, go to **Project > Project Settings > Plugins** and
   enable **MetSys**.
2. Its settings live in `world/MetSysSettings.tres` (theme + `world/MapData.txt`).
3. See the MetSys wiki: https://github.com/KoBeWi/Metroidvania-System/wiki

When you're ready to drive transitions through MetSys instead of the simple
`Door`/`Game` manager, make `Game.gd` extend
`addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd` and add the
`RoomTransitions` module (the sample in the MetSys repo shows the pattern).

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
