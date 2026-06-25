extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Hut Interior scene
# Tile-based room builder matching Phaser's HutInteriorScene layout.
# Room: TILE=64, COLS=30 (1920px wide), centred vertically.
# Layers: ROOF(64) + 4×WALL(64) + WBASE(32) + FLOOR(16) = 368px tall
# RY = (1080 - 368) / 2 = 356   CEIL_Y = 420   WALL_BOT = 676   GY = 708
# Player spawns just inside the door; E near door exits back to originating scene.
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W   := 1920
const GAME_H   := 1080

# Room geometry (matches Phaser exactly)
const TILE     := 64
const COLS     := 30          # GAME_W / TILE
const ROOF_H   := 64
const WALL_H   := 64
const WBASE_H  := 32
const FLOOR_H  := 16
const ROOM_H   := ROOF_H + 4 * WALL_H + WBASE_H + FLOOR_H  # 368
const RY       := (GAME_H - ROOM_H) / 2   # 356
const CEIL_Y   := RY + ROOF_H             # 420
const WALL_BOT := CEIL_Y + 4 * WALL_H     # 676
const GY       := WALL_BOT + WBASE_H      # 708  floor surface

# Door (col 0)
const DOOR_X   := TILE / 2               # 32  col-0 centre
const DOOR_H   := 92                     # 46 native × 2
const EXIT_R   := 90.0

# Window
const WIN_H    := 128
const WIN_Y    := CEIL_Y + (4 * WALL_H - WIN_H) / 2   # 484

# Wall art height (centred on wall midpoint)
const WALL_MID_Y := CEIL_Y + (4 * WALL_H) / 2         # 548

# Phaser key → Godot asset path (furniture folder)
const FURN_PATH := "res://assets/props/furniture/"
const INT_PATH  := "res://assets/props/interior/"

const FURN_MAP := {
	"furnArmchairBlue":   FURN_PATH + "sofa_teal.png",
	"furnArmchairRed":    FURN_PATH + "sofa_red.png",
	"furnArmchairGreen":  FURN_PATH + "sofa_green.png",
	"furnArmchairYellow": FURN_PATH + "sofa_yellow.png",
	"furnMantelShelf":    FURN_PATH + "cabinet_dark.png",
	"furnBedRed":         FURN_PATH + "bed_canopy.png",
	"furnBedBlue":        FURN_PATH + "bed_canopy.png",
	"furnBedGreen":       FURN_PATH + "bed_canopy.png",
	"furnBedYellow":      FURN_PATH + "bed_canopy.png",
	"furnSmallRedChest":  FURN_PATH + "chest_open.png",
	"furnCabinetDouble":  FURN_PATH + "armoire.png",
	"furnPictureFlower":  FURN_PATH + "picture_sm.png",
	"furnPicturePortrait":FURN_PATH + "picture_med.png",
	"furnWallMirror":     FURN_PATH + "mirror_tall.png",
	"furnFlowerVase":     FURN_PATH + "flower_vase.png",
	"furnFloorLamp":      FURN_PATH + "floor_lamp.png",
	"furnChandelier":     FURN_PATH + "chandelier.png",
}

# Interior configs (mirrors Phaser MIRELLE_FARMHOUSE etc.)
# windowType: "blue" | "red"   windowCols: Array[int]
# furniture: Array of {key, placement, col, flipX?}
const CONFIGS := {
	"mirelle_farmhouse": {
		"name": "Mirelle's Farmhouse",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnPictureFlower",  "placement": "wall",   "col": 10},
			{"key": "furnWallMirror",     "placement": "wall",   "col": 20},
			{"key": "furnArmchairBlue",   "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairBlue",   "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedRed",         "placement": "ground", "col": 17},
			{"key": "furnSmallRedChest",  "placement": "ground", "col": 27},
		],
		"return_scene": "Forest",
		"return_x": 2274.0,
	},
	"bram_smithy": {
		"name": "Bram Alder's Smithy",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnPicturePortrait","placement": "wall",   "col": 10},
			{"key": "furnWallMirror",     "placement": "wall",   "col": 20},
			{"key": "furnArmchairRed",    "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairRed",    "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedGreen",       "placement": "ground", "col": 17},
			{"key": "furnSmallRedChest",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 909.0,
	},
	"padrig_tavern": {
		"name": "Padrig's Tavern",
		"window": "red",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnPictureFlower",  "placement": "wall",   "col": 10},
			{"key": "furnPicturePortrait","placement": "wall",   "col": 20},
			{"key": "furnArmchairYellow", "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairYellow", "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedYellow",      "placement": "ground", "col": 17},
			{"key": "furnSmallRedChest",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 1611.0,
	},
	"teren_house": {
		"name": "Teren Vale's House",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnWallMirror",     "placement": "wall",   "col": 10},
			{"key": "furnPictureFlower",  "placement": "wall",   "col": 20},
			{"key": "furnArmchairBlue",   "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairBlue",   "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedBlue",        "placement": "ground", "col": 17},
			{"key": "furnCabinetDouble",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 2144.0,
	},
	"ysra_house": {
		"name": "Ysra Thorn's House",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnPicturePortrait","placement": "wall",   "col": 10},
			{"key": "furnWallMirror",     "placement": "wall",   "col": 20},
			{"key": "furnArmchairGreen",  "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairGreen",  "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedGreen",       "placement": "ground", "col": 17},
			{"key": "furnCabinetDouble",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 2700.0,
	},
	"oswin_shop": {
		"name": "Oswin's Shop",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnWallMirror",     "placement": "wall",   "col": 10},
			{"key": "furnPictureFlower",  "placement": "wall",   "col": 20},
			{"key": "furnArmchairYellow", "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairYellow", "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedYellow",      "placement": "ground", "col": 17},
			{"key": "furnSmallRedChest",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 3303.0,
	},
	"rilla_house": {
		"name": "Rilla's House",
		"window": "blue",
		"window_cols": [5, 15, 25],
		"furniture": [
			{"key": "furnPicturePortrait","placement": "wall",   "col": 10},
			{"key": "furnPictureFlower",  "placement": "wall",   "col": 20},
			{"key": "furnArmchairBlue",   "placement": "ground", "col":  7},
			{"key": "furnMantelShelf",    "placement": "ground", "col":  8},
			{"key": "furnArmchairBlue",   "placement": "ground", "col": 12, "flipX": true},
			{"key": "furnBedBlue",        "placement": "ground", "col": 17},
			{"key": "furnSmallRedChest",  "placement": "ground", "col": 27},
		],
		"return_scene": "City",
		"return_x": 3757.0,
	},
}

var _player:        CharacterBody2D
var _camera:        Camera2D
var _music:         AudioStreamPlayer
var _door_sfx:      AudioStreamPlayer
var _jump_sfx:      AudioStreamPlayer
var _attack_sfx:    AudioStreamPlayer
var _transitioning: bool = false
var _exit_tip:      Label
var _hp_bar_fg:     ColorRect
var _hp_label:      Label

func _ready() -> void:
	var cfg_id: String = Globals.interior_config_id
	var cfg: Dictionary = CONFIGS.get(cfg_id, CONFIGS["mirelle_farmhouse"])
	_build_room(cfg)
	_build_ground_physics()
	_spawn_player()
	_build_camera()
	_build_audio()
	_build_hud(cfg["name"])
	_build_exit_tip()
	_fade_in()

func _build_room(cfg: Dictionary) -> void:
	# Black background behind the room
	var bg := ColorRect.new()
	bg.color    = Color(0.04, 0.03, 0.02)
	bg.size     = Vector2(GAME_W, GAME_H)
	bg.position = Vector2.ZERO
	bg.z_index  = -10
	add_child(bg)

	var roof_tex  := _tex(INT_PATH + "house_roof.png")
	var wall_tex  := _tex(INT_PATH + "house_wall.png")
	var wbase_tex := _tex(INT_PATH + "wall_base.png")
	var floor1    := _tex(INT_PATH + "floor_tile_1.png")
	var floor2    := _tex(INT_PATH + "floor_tile_2.png")

	var win_open := cfg["window"] == "red"
	var win_tex  := _tex(INT_PATH + ("red_window_open.png" if win_open else "blue_window_open.png"))
	var door_tex := _tex(INT_PATH + "door_open.png")

	# Structural rows
	_fill_row(roof_tex,  RY,                     TILE, ROOF_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H,            TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + WALL_H,   TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + 2*WALL_H, TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + 3*WALL_H, TILE, WALL_H,  2)
	_fill_row(wbase_tex, WALL_BOT,               TILE, WBASE_H, 2)

	# Alternating floor tiles
	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		var sp := Sprite2D.new()
		sp.texture        = t
		sp.centered       = false
		sp.region_enabled = true
		sp.region_rect    = Rect2(0, 0, t.get_width(), t.get_height())
		sp.position       = Vector2(c * TILE, GY)
		sp.scale          = Vector2(float(TILE) / t.get_width(), float(FLOOR_H) / t.get_height())
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index        = 2
		add_child(sp)

	# Windows: sky rectangle behind, then window graphic in front
	for wc in cfg["window_cols"]:
		var wx := wc * TILE
		var sky := ColorRect.new()
		sky.color    = Color(0.784, 0.867, 0.910)
		sky.position = Vector2(wx, WIN_Y)
		sky.size     = Vector2(TILE, WIN_H)
		sky.z_index  = 1
		add_child(sky)
		var wsp := _stretched_sprite(win_tex, wx, WIN_Y, TILE, WIN_H, false)
		wsp.z_index = 4
		add_child(wsp)

	# Door at col 0
	var dsp := _stretched_sprite(door_tex, DOOR_X, GY + FLOOR_H, TILE, DOOR_H, true)
	dsp.z_index = 5
	add_child(dsp)

	# Furniture
	for f in cfg["furniture"]:
		var key: String = f["key"]
		var path: String = FURN_MAP.get(key, "")
		if path == "":
			push_warning("HutInterior: unknown furniture key " + key)
			continue
		var ftex: Texture2D = load(path)
		if not ftex: continue
		var fc: int = f["col"]
		var cx: float = fc * TILE + TILE * 0.5  # centre of column
		var placement: String = f.get("placement", "ground")
		var flip: bool = f.get("flipX", false)
		var fsp := Sprite2D.new()
		fsp.texture        = ftex
		fsp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fsp.flip_h         = flip
		if placement == "wall":
			fsp.position = Vector2(cx, WALL_MID_Y)
			fsp.centered = true
			fsp.z_index  = 7
		else:  # ground
			fsp.position   = Vector2(cx, GY)
			fsp.centered   = false
			fsp.offset     = Vector2(-ftex.get_width() * 0.5, -ftex.get_height())
			fsp.z_index    = 8
		add_child(fsp)

func _fill_row(tex: Texture2D, y: float, tile_w: float, tile_h: float, z: int) -> void:
	for c in range(COLS):
		var sp := _stretched_sprite(tex, c * tile_w, y, tile_w, tile_h, false)
		sp.z_index = z
		add_child(sp)

func _stretched_sprite(tex: Texture2D, x: float, y: float, w: float, h: float, center_x: bool) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture        = tex
	sp.centered       = false
	sp.region_enabled = true
	sp.region_rect    = Rect2(0, 0, tex.get_width(), tex.get_height())
	sp.scale          = Vector2(w / tex.get_width(), h / tex.get_height())
	sp.position       = Vector2(x - w * 0.5 if center_x else x, y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D

func _build_ground_physics() -> void:
	# Floor collider
	var floor_body  := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect  := RectangleShape2D.new()
	floor_rect.size      = Vector2(GAME_W, 80.0)
	floor_shape.position = Vector2(GAME_W / 2.0, GY + 40.0)
	floor_shape.shape    = floor_rect
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	# Ceiling collider
	var ceil_body  := StaticBody2D.new()
	var ceil_shape := CollisionShape2D.new()
	var ceil_rect  := RectangleShape2D.new()
	ceil_rect.size      = Vector2(GAME_W, 40.0)
	ceil_shape.position = Vector2(GAME_W / 2.0, CEIL_Y - 20.0)
	ceil_shape.shape    = ceil_rect
	ceil_body.add_child(ceil_shape)
	add_child(ceil_body)

	# Left wall collider
	var lwall_body  := StaticBody2D.new()
	var lwall_shape := CollisionShape2D.new()
	var lwall_rect  := RectangleShape2D.new()
	lwall_rect.size      = Vector2(8.0, GAME_H)
	lwall_shape.position = Vector2(4.0, GAME_H / 2.0)
	lwall_shape.shape    = lwall_rect
	lwall_body.add_child(lwall_shape)
	add_child(lwall_body)

	# Right wall collider
	var rwall_body  := StaticBody2D.new()
	var rwall_shape := CollisionShape2D.new()
	var rwall_rect  := RectangleShape2D.new()
	rwall_rect.size      = Vector2(8.0, GAME_H)
	rwall_shape.position = Vector2(GAME_W - 4.0, GAME_H / 2.0)
	rwall_shape.shape    = rwall_rect
	rwall_body.add_child(rwall_shape)
	add_child(rwall_body)

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	# Spawn just inside the door at col-0, floor level
	_player.position = Vector2(DOOR_X + 80.0, GY - 1.0)
	_player.jumped.connect(func(): if _jump_sfx: _jump_sfx.play())
	_player.attacked.connect(func(): if _attack_sfx: _attack_sfx.play())
	add_child(_player)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0
	_camera.limit_right  = GAME_W
	_camera.limit_top    = 0
	_camera.limit_bottom = GAME_H
	_player.add_child(_camera)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var res := load("res://assets/audio/celadune_forest.mp3") as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream = res
	_music.volume_db = linear_to_db(0.0)
	add_child(_music)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.18), 0.5)

	_door_sfx = AudioStreamPlayer.new()
	var dsfx := load("res://assets/sfx/dragon-studio-open-door-sfx-454245.mp3") as AudioStream
	if dsfx: _door_sfx.stream = dsfx
	_door_sfx.volume_db = linear_to_db(0.7)
	add_child(_door_sfx)

	_jump_sfx = AudioStreamPlayer.new()
	var jsfx := load("res://assets/sfx/jump.mp3") as AudioStream
	if jsfx: _jump_sfx.stream = jsfx
	_jump_sfx.volume_db = linear_to_db(0.4)
	add_child(_jump_sfx)

	_attack_sfx = AudioStreamPlayer.new()
	var asfx := load("res://assets/sfx/attack.mp3") as AudioStream
	if asfx: _attack_sfx.stream = asfx
	_attack_sfx.volume_db = linear_to_db(0.55)
	add_child(_attack_sfx)

func _build_hud(room_name: String) -> void:
	var hud := CanvasLayer.new(); hud.layer = 10; add_child(hud)

	# Room name
	var title := Label.new()
	title.text     = room_name
	title.position = Vector2(GAME_W / 2 - 180, 20)
	title.add_theme_font_override("font", Globals.FONT_TITLE)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.87, 0.80, 0.62, 0.85))
	hud.add_child(title)

	# HP bar background
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); hud.add_child(bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.position = Vector2(26, GAME_H - 44); _hp_bar_fg.size = Vector2(176, 12)
	_hp_bar_fg.color = Color(0.87, 0.2, 0.2); hud.add_child(_hp_bar_fg)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"; hp_lbl.position = Vector2(24, GAME_H - 62)
	hp_lbl.add_theme_color_override("font_color", Color(0.87, 0.2, 0.2))
	hp_lbl.add_theme_font_size_override("font_size", 13); hud.add_child(hp_lbl)

	_hp_label = Label.new()
	_hp_label.text = "%d / %d" % [Globals.player_health, Globals.player_max_health]
	_hp_label.position = Vector2(212, GAME_H - 46)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hp_label.add_theme_font_size_override("font_size", 13); hud.add_child(_hp_label)

func _build_exit_tip() -> void:
	_exit_tip = Label.new()
	_exit_tip.text    = "Exit  (E)"
	_exit_tip.visible = false
	_exit_tip.z_index = 30
	_exit_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_exit_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_exit_tip.add_theme_constant_override("shadow_offset_x", 2)
	_exit_tip.add_theme_constant_override("shadow_offset_y", 2)
	_exit_tip.add_theme_font_size_override("font_size", 18)
	add_child(_exit_tip)

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.4)
	tw.tween_callback(ov.queue_free)

func _process(_delta: float) -> void:
	if not _player: return
	var dist := absf(_player.position.x - float(DOOR_X))
	var near := dist < EXIT_R
	_exit_tip.visible = near
	if near:
		_exit_tip.position = Vector2(DOOR_X - 30, GY - 90)
	if near and Input.is_action_just_pressed("interact"):
		_exit_interior()

func _exit_interior() -> void:
	if _transitioning: return
	_transitioning = true
	if _door_sfx: _door_sfx.play()

	var cfg_id := Globals.interior_config_id
	var cfg: Dictionary = CONFIGS.get(cfg_id, CONFIGS["mirelle_farmhouse"])
	var return_scene: String = cfg.get("return_scene", "Forest")
	var return_x: float = cfg.get("return_x", 2274.0)

	Globals.from_transition = true
	Globals.spawn_x = return_x

	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + return_scene + ".tscn"))
