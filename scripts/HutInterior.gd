extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Hut Interior scene
# Tile-based room matching Phaser HutInteriorScene layout.
# TILE=64, COLS=30 (1920px). Layers: ROOF(64)+4×WALL(64)+WBASE(32)+FLOOR(16)
# RY=356  CEIL_Y=420  WALL_BOT=676  GY=708
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W   := 1920
const GAME_H   := 1080
const TILE     := 64
const COLS     := 30
const ROOF_H   := 64
const WALL_H   := 64
const WBASE_H  := 32
const FLOOR_H  := 16
const RY       := 356   # (1080 - 368) / 2
const CEIL_Y   := 420   # RY + ROOF_H
const WALL_BOT := 676   # CEIL_Y + 4*WALL_H
const GY       := 708   # WALL_BOT + WBASE_H  — floor surface
const DOOR_X   := 32    # col-0 centre
const DOOR_H   := 92
const WIN_H    := 128
const WIN_Y    := 484   # CEIL_Y + (4*WALL_H - WIN_H)/2
const WALL_MID_Y := 548 # CEIL_Y + (4*WALL_H)/2
const EXIT_R   := 90.0

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

# ── Furniture key → asset path ────────────────────────────────────────────────
func _furn_path(key: String) -> String:
	var F := "res://assets/props/furniture/"
	var map := {
		"furnArmchairBlue":    F + "sofa_teal.png",
		"furnArmchairRed":     F + "sofa_red.png",
		"furnArmchairGreen":   F + "sofa_green.png",
		"furnArmchairYellow":  F + "sofa_yellow.png",
		"furnMantelShelf":     F + "cabinet_dark.png",
		"furnBedRed":          F + "bed_canopy.png",
		"furnBedBlue":         F + "bed_canopy.png",
		"furnBedGreen":        F + "bed_canopy.png",
		"furnBedYellow":       F + "bed_canopy.png",
		"furnSmallRedChest":   F + "chest_open.png",
		"furnCabinetDouble":   F + "armoire.png",
		"furnPictureFlower":   F + "picture_sm.png",
		"furnPicturePortrait": F + "picture_med.png",
		"furnWallMirror":      F + "mirror_tall.png",
		"furnFlowerVase":      F + "flower_vase.png",
		"furnFloorLamp":       F + "floor_lamp.png",
		"furnChandelier":      F + "chandelier.png",
	}
	return map.get(key, "")

# ── Building configs (mirrors Phaser MIRELLE_FARMHOUSE etc.) ──────────────────
func _get_config(cfg_id: String) -> Dictionary:
	var configs := {
		"mirelle_farmhouse": {
			"name": "Mirelle's Farmhouse", "window": "blue",
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
			"return_scene": "Forest", "return_x": 2274.0,
		},
		"bram_smithy": {
			"name": "Bram Alder's Smithy", "window": "blue",
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
			"return_scene": "City", "return_x": 909.0,
		},
		"padrig_tavern": {
			"name": "Padrig's Tavern", "window": "red",
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
			"return_scene": "City", "return_x": 1611.0,
		},
		"teren_house": {
			"name": "Teren Vale's House", "window": "blue",
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
			"return_scene": "City", "return_x": 2144.0,
		},
		"ysra_house": {
			"name": "Ysra Thorn's House", "window": "blue",
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
			"return_scene": "City", "return_x": 2700.0,
		},
		"oswin_shop": {
			"name": "Oswin's Shop", "window": "blue",
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
			"return_scene": "City", "return_x": 3303.0,
		},
		"rilla_house": {
			"name": "Rilla's House", "window": "blue",
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
			"return_scene": "City", "return_x": 3757.0,
		},
	}
	return configs.get(cfg_id, configs["mirelle_farmhouse"])

func _ready() -> void:
	var cfg := _get_config(Globals.interior_config_id)
	_build_room(cfg)
	_build_ground_physics()
	_spawn_player()
	_build_camera()
	_build_audio()
	_build_hud(cfg["name"])
	_build_exit_tip()
	_fade_in()

func _build_room(cfg: Dictionary) -> void:
	# Black background
	var bg := ColorRect.new()
	bg.color    = Color(0.04, 0.03, 0.02)
	bg.size     = Vector2(GAME_W, GAME_H)
	bg.position = Vector2.ZERO
	bg.z_index  = -10
	add_child(bg)

	var P := "res://assets/props/interior/"
	var roof_tex  : Texture2D = load(P + "house_roof.png")
	var wall_tex  : Texture2D = load(P + "house_wall.png")
	var wbase_tex : Texture2D = load(P + "wall_base.png")
	var floor1    : Texture2D = load(P + "floor_tile_1.png")
	var floor2    : Texture2D = load(P + "floor_tile_2.png")
	var door_tex  : Texture2D = load(P + "door_open.png")
	var win_path  := P + ("red_window_open.png" if cfg["window"] == "red" else "blue_window_open.png")
	var win_tex   : Texture2D = load(win_path)

	# Structural rows
	_fill_row(roof_tex,  RY,                     TILE, ROOF_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H,            TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + WALL_H,   TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + 2*WALL_H, TILE, WALL_H,  2)
	_fill_row(wall_tex,  RY + ROOF_H + 3*WALL_H, TILE, WALL_H,  2)
	_fill_row(wbase_tex, WALL_BOT,               TILE, WBASE_H, 2)

	# Alternating floor
	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		if not t: continue
		var sp := Sprite2D.new()
		sp.texture        = t
		sp.centered       = false
		sp.position       = Vector2(c * TILE, GY)
		sp.scale          = Vector2(float(TILE) / t.get_width(), float(FLOOR_H) / t.get_height())
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index        = 2
		add_child(sp)

	# Windows
	for wc in cfg["window_cols"]:
		var wx := wc * TILE
		var sky := ColorRect.new()
		sky.color    = Color(0.784, 0.867, 0.910)
		sky.position = Vector2(wx, WIN_Y)
		sky.size     = Vector2(TILE, WIN_H)
		sky.z_index  = 1
		add_child(sky)
		if win_tex:
			var wsp := _scaled_sprite(win_tex, wx, WIN_Y, TILE, WIN_H)
			wsp.z_index = 4
			add_child(wsp)

	# Door at col 0
	if door_tex:
		var dsp := _scaled_sprite(door_tex, DOOR_X - TILE * 0.5, GY + FLOOR_H - DOOR_H, TILE, DOOR_H)
		dsp.z_index = 5
		add_child(dsp)

	# Furniture
	for f in cfg["furniture"]:
		var path := _furn_path(f["key"])
		if path == "": continue
		var ftex: Texture2D = load(path)
		if not ftex: continue
		var fc: int = f["col"]
		var cx: float = fc * TILE + TILE * 0.5
		var placement: String = f.get("placement", "ground")
		var flip: bool = f.get("flipX", false)
		var fsp := Sprite2D.new()
		fsp.texture        = ftex
		fsp.flip_h         = flip
		fsp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fsp.centered       = false
		if placement == "wall":
			fsp.position = Vector2(cx - ftex.get_width() * 0.5, WALL_MID_Y - ftex.get_height() * 0.5)
			fsp.z_index  = 7
		else:
			fsp.position = Vector2(cx - ftex.get_width() * 0.5, GY - ftex.get_height())
			fsp.z_index  = 8
		add_child(fsp)

func _scaled_sprite(tex: Texture2D, x: float, y: float, w: float, h: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture        = tex
	sp.centered       = false
	sp.position       = Vector2(x, y)
	sp.scale          = Vector2(w / tex.get_width(), h / tex.get_height())
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _fill_row(tex: Texture2D, y: float, tile_w: float, tile_h: float, z: int) -> void:
	if not tex: return
	for c in range(COLS):
		var sp := _scaled_sprite(tex, c * tile_w, y, tile_w, tile_h)
		sp.z_index = z
		add_child(sp)

func _build_ground_physics() -> void:
	_static_box(GAME_W / 2.0, GY + 40.0,           GAME_W, 80.0)   # floor
	_static_box(GAME_W / 2.0, CEIL_Y - 20.0,        GAME_W, 40.0)   # ceiling
	_static_box(4.0,           GAME_H / 2.0,         8.0,   GAME_H)  # left wall
	_static_box(GAME_W - 4.0,  GAME_H / 2.0,         8.0,   GAME_H)  # right wall

func _static_box(cx: float, cy: float, w: float, h: float) -> void:
	var body  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size       = Vector2(w, h)
	shape.position  = Vector2(cx, cy)
	shape.shape     = rect
	body.add_child(shape)
	add_child(body)

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(DOOR_X + 80.0, GY - 1.0)
	_player.jumped.connect(func(): if _jump_sfx: _jump_sfx.play())
	_player.attacked.connect(func(): if _attack_sfx: _attack_sfx.play())
	add_child(_player)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0; _camera.limit_right  = GAME_W
	_camera.limit_top    = 0; _camera.limit_bottom = GAME_H
	_player.add_child(_camera)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var res := load("res://assets/audio/celadune_forest.mp3") as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream = res
	_music.volume_db = linear_to_db(0.0)
	add_child(_music); _music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.18), 0.5)

	_door_sfx = AudioStreamPlayer.new()
	var dsfx := load("res://assets/sfx/dragon-studio-open-door-sfx-454245.mp3") as AudioStream
	if dsfx: _door_sfx.stream = dsfx
	_door_sfx.volume_db = linear_to_db(0.7); add_child(_door_sfx)

	_jump_sfx = AudioStreamPlayer.new()
	var jsfx := load("res://assets/sfx/jump.mp3") as AudioStream
	if jsfx: _jump_sfx.stream = jsfx
	_jump_sfx.volume_db = linear_to_db(0.4); add_child(_jump_sfx)

	_attack_sfx = AudioStreamPlayer.new()
	var asfx := load("res://assets/sfx/attack.mp3") as AudioStream
	if asfx: _attack_sfx.stream = asfx
	_attack_sfx.volume_db = linear_to_db(0.55); add_child(_attack_sfx)

func _build_hud(room_name: String) -> void:
	var hud := CanvasLayer.new(); hud.layer = 10; add_child(hud)
	var title := Label.new()
	title.text = room_name
	title.position = Vector2(GAME_W / 2.0 - 180.0, 20)
	title.add_theme_font_override("font", Globals.FONT_TITLE)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.87, 0.80, 0.62, 0.85))
	hud.add_child(title)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); hud.add_child(bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.position = Vector2(26, GAME_H - 44); _hp_bar_fg.size = Vector2(176, 12)
	_hp_bar_fg.color = Color(0.87, 0.2, 0.2); hud.add_child(_hp_bar_fg)

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
	var near := absf(_player.position.x - float(DOOR_X)) < EXIT_R
	_exit_tip.visible = near
	if near: _exit_tip.position = Vector2(DOOR_X - 30, GY - 90)
	if near and Input.is_action_just_pressed("interact"):
		_exit_interior()

func _exit_interior() -> void:
	if _transitioning: return
	_transitioning = true
	if _door_sfx: _door_sfx.play()
	var cfg := _get_config(Globals.interior_config_id)
	Globals.from_transition = true
	Globals.spawn_x = cfg.get("return_x", 2274.0)
	var return_scene: String = cfg.get("return_scene", "Forest")
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + return_scene + ".tscn"))
