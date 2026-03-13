# Phaser forest prototype

## Run locally

Because browsers can block local file loading for Phaser assets, run this from a small local web server.

### Python 3

```bash
cd phaser_prototype
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000
```

## Controls

- Left arrow: move left
- Right arrow: move right
- Up arrow: jump

## Included

- Proportionally scaled parallax forest background
- One row of enlarged ground tiles
- LPC character walk, idle, and jump animation
- Camera follow
- Light atmospheric overlays
