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
- **Parts library:** assets/npc-parts/ (232 PNGs across 12 categories)
- **Compositor:** tools/npc_compositor.py
  - `python3 tools/npc_compositor.py --random male --seed 42 --name "Aldric" --out assets/npcs/my_npc/`
  - Produces walk.png (8 frames, 64×64) and idle.png (5 frames, 64×64)
- **Existing NPCs:** assets/npcs/hut_wanderer/ (Aldric, seed 42)
- **Adding a new NPC to the game:** follow the HUT_WANDERER pattern in main.js
- **Sprite orientation:** GandalfHardcore sprites face LEFT by default. Use `setFlipX(true)` when moving right, `setFlipX(false)` when moving left.

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
