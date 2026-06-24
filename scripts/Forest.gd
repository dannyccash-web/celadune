extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# Forest scene — coordinate reference
#
# Viewport:   1920 × 1080  (matches original Phaser game exactly)
# World:      5184 × 1080  (54 tiles × 96 px each)
# GROUND_Y:   888           Top of the surface tile row — player/NPC feet land here
# BLACK_TILE_GROUND_Y: 927  GROUND_Y + 39 — visual baseline for prop placement
# PROP_BASE:  903           BLACK_TILE_GROUND_Y - 24 — bottom of props/buildings
#
# All X/Y values below are taken directly from the original Phaser main.js.
# Props use setOrigin(0.5, 1) equivalent: Sprite2D is anchored bottom-center.
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 5184
const GAME_HEIGHT  := 1080
const GROUND_Y     := 888     # top surface of tiles / where physics floor sits
const PROP_BASE    := 903     # bottom of props and buildings (BLACK_TILE_GROUND_Y - 24)
const TILE_PX      := 96

# NPC Y position when standing on GROUND_Y.
# Derived from Phaser: sprite_center.y = 888 - (offset_y + body_h - frame_h/2) * scale
#   = 888 - (28 + 34 - 32) * 3.0 = 888 - 90 = 798
const NPC_GROUND_Y := 798.0

# Tile frame indices in floor_tiles2.png (9 columns × 18 rows, 96×96 each)
# green set: top-left=0, top-center=1, top-right=2, fill=10
const T_TOP_L := 0
const T_TOP_C := 1
const T_TOP_R := 2
const T_FILL  := 10

# Parallax scroll factors — identical to Phaser scrollFactor values
# 0 = fixed to camera (far background), 1 = moves with world (no parallax)
const BG_LAYERS := [
	{ "key": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "key": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "key": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "key": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "key": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

var _player: CharacterBody2D
var _camera: Camera2D

func _ready() -> void:
	_build_parallax()
	_build_ground()
	_build_ground_tiles()
	_build_props()
	_spawn_player()
	_spawn_npcs()
	_build_camera()

# ── Parallax background ───────────────────────────────────────────────────────
func _build_parallax() -> void:
	var pb := ParallaxBackground.new()
	add_child(pb)

	for cfg in BG_LAYERS:
		var tex: Texture2D = load(cfg["key"])
		if not tex:
			continue

		# Scale so image fills exactly GAME_HEIGHT vertically (same as Phaser)
		var scale_factor := float(GAME_HEIGHT) / float(tex.get_height())
		var scaled_w     := tex.get_width() * scale_factor

		var layer := ParallaxLayer.new()
		layer.motion_scale    = Vector2(cfg["factor"], 0.0)
		layer.motion_mirroring = Vector2(scaled_w, 0.0)
		pb.add_child(layer)

		var sp := Sprite2D.new()
		sp.texture        = tex
		sp.centered       = false
		sp.scale          = Vector2(scale_factor, scale_factor)
		sp.position       = Vector2(0.0, cfg["y_off"])
		# Background images use linear filtering (bilinear, not pixel-art nearest)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(sp)

# ── Ground physics ────────────────────────────────────────────────────────────
func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	add_child(ground)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	# Thick enough to never fall through; top edge at GROUND_Y
	rect.size = Vector2(WORLD_WIDTH * 2.0, 400.0)
	shape.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 200.0)
	shape.shape = rect
	ground.add_child(shape)

# ── Ground tiles (visual) ─────────────────────────────────────────────────────
# Matches Phaser's createGround() — 54 columns, green tile set, scale 1.0
func _build_ground_tiles() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := WORLD_WIDTH / TILE_PX  # = 54

	for col in range(cols):
		var cx := col * TILE_PX + TILE_PX / 2  # center x of this column

		# Choose corner frame vs flat
		var top_frame := T_TOP_C
		if col == 0:
			top_frame = T_TOP_L
		elif col == cols - 1:
			top_frame = T_TOP_R

		# Surface tile — top at GROUND_Y, centered horizontally
		_place_tile(tile_tex, cx, GROUND_Y + TILE_PX / 2, top_frame, 12)

		# Fill tiles down to bottom of screen
		var fill_rows := int(ceil(float(GAME_HEIGHT - GROUND_Y) / TILE_PX)) + 1
		for row in range(1, fill_rows + 1):
			_place_tile(tile_tex, cx, GROUND_Y + TILE_PX * row + TILE_PX / 2, T_FILL, 2)

		# Dark background fill behind tiles (matches Phaser's 0x1a1208 rectangle)
		var bg := ColorRect.new()
		bg.color    = Color(0.102, 0.071, 0.031)  # 0x1a1208
		bg.size     = Vector2(TILE_PX, GAME_HEIGHT + 200 - GROUND_Y)
		bg.position = Vector2(cx - TILE_PX / 2, GROUND_Y)
		bg.z_index  = 1
		add_child(bg)

func _place_tile(tex: Texture2D, cx: float, cy: float, frame_idx: int, z: int) -> void:
	var col_n := frame_idx % 9
	var row_n := frame_idx / 9
	var atlas := AtlasTexture.new()
	atlas.atlas  = tex
	atlas.region = Rect2(col_n * TILE_PX, row_n * TILE_PX, TILE_PX, TILE_PX)

	var sp := Sprite2D.new()
	sp.texture        = atlas
	sp.centered       = true
	sp.position       = Vector2(cx, cy)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index        = z
	add_child(sp)

# ── Props ─────────────────────────────────────────────────────────────────────
# All props use setOrigin(0.5, 1) in Phaser → bottom-center anchor.
# In Godot: Sprite2D.centered = true, offset.y = -texture_height/2
# so the sprite bottom sits at position.y = PROP_BASE (or as specified).
func _build_props() -> void:
	# Broken wagon + small tent + cauldron (left side, start of world)
	# NOTE: broken_wagon.png is 698×347 — already large, displayed at 1.0×
	_prop("res://assets/props/broken_wagon.png",     360, PROP_BASE, 7)
	_prop("res://assets/props/decor_small_tent.png", 610, PROP_BASE, 7)
	_prop("res://assets/props/decor_wood_logs.png",  730, PROP_BASE, 6)
	_prop("res://assets/props/decor_cauldron.png",   730, PROP_BASE, 7)

	# Pumpkin patch (left of scarecrow)
	# NOTE: pumpkin sprites are 32×32 — small props, intentional at 1920 width
	_prop("res://assets/props/decor_pumpkin_large.png", 1400, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_small.png", 1460, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_large.png", 1510, PROP_BASE, 7)

	# Scarecrow
	# NOTE: scarecrow.png is 68×70 — small prop, intentional
	_prop("res://assets/props/scarecrow.png", 1590, PROP_BASE, 7)

	# More pumpkins right of scarecrow
	_prop("res://assets/props/decor_pumpkin_large.png", 1660, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_small.png", 1700, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_large.png", 1740, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_small.png", 1780, PROP_BASE, 7)
	_prop("res://assets/props/decor_pumpkin_large.png", 1820, PROP_BASE, 7)

	# Grass stalks left of hut
	# NOTE: decor_grass_large.png is 64×64 — small, intentional ground decoration
	_prop("res://assets/props/decor_grass_small.png", 1910, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 1960, PROP_BASE, 7)

	# Forest hut — centerpiece of the scene at X=2240
	# forest_hut/building.png is 384×576, displayed at 1.0× (pre-baked)
	_prop("res://assets/buildings/forest_hut/building.png", 2240, PROP_BASE, 7)

	# Onion patch (right of hut) — onion_patch.png is 1361×262 (very wide strip)
	_prop("res://assets/props/onion_patch.png", 2790, PROP_BASE, 7)
	_prop("res://assets/props/onion_patch.png", 2990, PROP_BASE, 7)
	_prop("res://assets/props/onion_patch.png", 3130, PROP_BASE, 7)
	_prop("res://assets/props/onion_patch.png", 3260, PROP_BASE, 7)

	# Grass mixed into the crop area
	_prop("res://assets/props/decor_grass_small.png", 3060, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 3200, PROP_BASE, 7)

	# Sunflowers and bushes — right side of farm
	# NOTE: sunflowers.png is 92×67, bush_large 59×25 — small props, intentional
	_prop("res://assets/props/sunflowers.png",  3420, PROP_BASE, 7)
	_prop("res://assets/props/sunflowers.png",  3530, PROP_BASE, 7)
	_prop("res://assets/props/bush_large.png",  3700, PROP_BASE, 7)
	_prop("res://assets/props/bush_small.png",  3820, PROP_BASE, 7)

func _prop(path: String, x: float, baseline_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex:
		push_warning("Forest: missing prop texture: " + path)
		return
	var sp := Sprite2D.new()
	sp.texture        = tex
	sp.centered       = true
	# Bottom-center anchor: shift sprite up by half its height
	sp.offset         = Vector2(0.0, -tex.get_height() / 2.0)
	sp.position       = Vector2(x, baseline_y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index        = z
	add_child(sp)

# ── Player ────────────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	_player = scene.instantiate()
	# Start above ground — gravity brings it down (mirrors Phaser's spawn at Y=768)
	_player.position = Vector2(300.0, 768.0)
	add_child(_player)

# ── NPCs ──────────────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	var npc_scene: PackedScene = load("res://scenes/NPC.tscn")

	# Mirelle (forestLady) — patrols X 2420–2660, scale 3.0
	var mirelle: Node2D = npc_scene.instantiate()
	mirelle.npc_name    = "Mirelle"
	mirelle.walk_path   = "res://assets/npcs/forest_lady/walk.png"
	mirelle.idle_path   = "res://assets/npcs/forest_lady/idle.png"
	mirelle.walk_frames = 8
	mirelle.idle_frames = 5
	mirelle.npc_scale   = 3.0
	mirelle.patrol_min_x = 2420.0
	mirelle.patrol_max_x = 2660.0
	mirelle.patrol_speed = 95.0   # Phaser setVelocityX(95)
	mirelle.pause_ms    = 5000.0
	mirelle.frame_w     = 64
	mirelle.frame_h     = 64
	mirelle.position    = Vector2(2420.0, NPC_GROUND_Y)
	add_child(mirelle)

	# Aldric (hutWanderer) — patrols X 1860–2170, scale 3.0
	var aldric: Node2D = npc_scene.instantiate()
	aldric.npc_name    = "Aldric"
	aldric.walk_path   = "res://assets/npcs/hut_wanderer/walk.png"
	aldric.idle_path   = "res://assets/npcs/hut_wanderer/idle.png"
	aldric.walk_frames = 8
	aldric.idle_frames = 5
	aldric.npc_scale   = 3.0
	aldric.patrol_min_x = 1860.0
	aldric.patrol_max_x = 2170.0
	aldric.patrol_speed = 48.0
	aldric.pause_ms    = 3500.0
	aldric.frame_w     = 64
	aldric.frame_h     = 64
	aldric.position    = Vector2(2015.0, NPC_GROUND_Y)
	add_child(aldric)

	# Farm worker (Lena) — patrols X 2950–3300, scale 3.0
	var lena: Node2D = npc_scene.instantiate()
	lena.npc_name    = "Lena"
	lena.walk_path   = "res://assets/npcs/farm_worker/walk.png"
	lena.idle_path   = "res://assets/npcs/farm_worker/idle.png"
	lena.walk_frames = 8
	lena.idle_frames = 5
	lena.npc_scale   = 3.0
	lena.patrol_min_x = 2950.0
	lena.patrol_max_x = 3300.0
	lena.patrol_speed = 40.0
	lena.pause_ms    = 4500.0
	lena.frame_w     = 64
	lena.frame_h     = 64
	lena.position    = Vector2(3050.0, NPC_GROUND_Y)
	add_child(lena)

# ── Camera ────────────────────────────────────────────────────────────────────
func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0
	_camera.limit_right  = WORLD_WIDTH
	_camera.limit_top    = 0
	_camera.limit_bottom = GAME_HEIGHT
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 5.0
	_player.add_child(_camera)
