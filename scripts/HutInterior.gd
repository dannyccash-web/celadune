extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# HutInterior — tile-based room for Mirelle's farmhouse and city buildings.
# Room dimensions match Phaser HutInteriorScene:
#   TILE=64, COLS=30 (1920px wide)
#   RY=356, CEIL_Y=420, WALL_BOT=676, GY=708
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W  := 1920
const GAME_H  := 1080
const TILE    := 64
const COLS    := 30
const RY      := 356
const CEIL_Y  := 420
const WALL_BOT := 676
const GY      := 708
const DOOR_X  := 32
const DOOR_H  := 92
const WIN_H   := 128
const WIN_Y   := 484
const WALL_MID_Y := 548
const EXIT_R  := 90.0

var _player:        CharacterBody2D
var _camera:        Camera2D
var _music:         AudioStreamPlayer
var _door_sfx:      AudioStreamPlayer
var _jump_sfx:      AudioStreamPlayer
var _attack_sfx:    AudioStreamPlayer
var _transitioning: bool = false
var _exit_tip:      Label

# ── Config helpers (match avoids giant inline dict literal) ───────────────────
func _room_name() -> String:
	match Globals.interior_config_id:
		"bram_smithy":    return "Bram Alder's Smithy"
		"padrig_tavern":  return "Padrig's Tavern"
		"teren_house":    return "Teren Vale's House"
		"ysra_house":     return "Ysra Thorn's House"
		"oswin_shop":     return "Oswin's Shop"
		"rilla_house":    return "Rilla's House"
	return "Mirelle's Farmhouse"

func _window_type() -> String:
	if Globals.interior_config_id == "padrig_tavern": return "red"
	return "blue"

func _window_cols() -> Array:
	return [5, 15, 25]

func _return_scene() -> String:
	match Globals.interior_config_id:
		"bram_smithy", "padrig_tavern", "teren_house", "ysra_house", "oswin_shop", "rilla_house":
			return "City"
	return "Forest"

func _return_x() -> float:
	match Globals.interior_config_id:
		"bram_smithy":   return 909.0
		"padrig_tavern": return 1611.0
		"teren_house":   return 2144.0
		"ysra_house":    return 2700.0
		"oswin_shop":    return 3303.0
		"rilla_house":   return 3757.0
	return 2274.0

func _furniture() -> Array:
	match Globals.interior_config_id:
		"bram_smithy":
			return [
				{"key":"furnPicturePortrait","placement":"wall",   "col":10},
				{"key":"furnWallMirror",     "placement":"wall",   "col":20},
				{"key":"furnArmchairRed",    "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
				{"key":"furnArmchairRed",    "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedGreen",       "placement":"ground", "col":17},
				{"key":"furnSmallRedChest",  "placement":"ground", "col":27},
			]
		"padrig_tavern":
			return [
				{"key":"furnPictureFlower",  "placement":"wall",   "col":10},
				{"key":"furnPicturePortrait","placement":"wall",   "col":20},
				{"key":"furnArmchairYellow", "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
				{"key":"furnArmchairYellow", "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedYellow",      "placement":"ground", "col":17},
				{"key":"furnSmallRedChest",  "placement":"ground", "col":27},
			]
		"teren_house":
			return [
				{"key":"furnWallMirror",    "placement":"wall",   "col":10},
				{"key":"furnPictureFlower", "placement":"wall",   "col":20},
				{"key":"furnArmchairBlue",  "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",   "placement":"ground", "col": 8},
				{"key":"furnArmchairBlue",  "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedBlue",       "placement":"ground", "col":17},
				{"key":"furnCabinetDouble", "placement":"ground", "col":27},
			]
		"ysra_house":
			return [
				{"key":"furnPicturePortrait","placement":"wall",   "col":10},
				{"key":"furnWallMirror",     "placement":"wall",   "col":20},
				{"key":"furnArmchairGreen",  "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
				{"key":"furnArmchairGreen",  "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedGreen",       "placement":"ground", "col":17},
				{"key":"furnCabinetDouble",  "placement":"ground", "col":27},
			]
		"oswin_shop":
			return [
				{"key":"furnWallMirror",     "placement":"wall",   "col":10},
				{"key":"furnPictureFlower",  "placement":"wall",   "col":20},
				{"key":"furnArmchairYellow", "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
				{"key":"furnArmchairYellow", "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedYellow",      "placement":"ground", "col":17},
				{"key":"furnSmallRedChest",  "placement":"ground", "col":27},
			]
		"rilla_house":
			return [
				{"key":"furnPicturePortrait","placement":"wall",   "col":10},
				{"key":"furnPictureFlower",  "placement":"wall",   "col":20},
				{"key":"furnArmchairBlue",   "placement":"ground", "col": 7},
				{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
				{"key":"furnArmchairBlue",   "placement":"ground", "col":12, "flipX":true},
				{"key":"furnBedBlue",        "placement":"ground", "col":17},
				{"key":"furnSmallRedChest",  "placement":"ground", "col":27},
			]
	# mirelle_farmhouse (default)
	return [
		{"key":"furnPictureFlower",  "placement":"wall",   "col":10},
		{"key":"furnWallMirror",     "placement":"wall",   "col":20},
		{"key":"furnArmchairBlue",   "placement":"ground", "col": 7},
		{"key":"furnMantelShelf",    "placement":"ground", "col": 8},
		{"key":"furnArmchairBlue",   "placement":"ground", "col":12, "flipX":true},
		{"key":"furnBedRed",         "placement":"ground", "col":17},
		{"key":"furnSmallRedChest",  "placement":"ground", "col":27},
	]

func _furn_path(key: String) -> String:
	var F := "res://assets/props/furniture/"
	match key:
		"furnArmchairBlue":    return F + "sofa_teal.png"
		"furnArmchairRed":     return F + "sofa_red.png"
		"furnArmchairGreen":   return F + "sofa_green.png"
		"furnArmchairYellow":  return F + "sofa_yellow.png"
		"furnMantelShelf":     return F + "cabinet_dark.png"
		"furnBedRed":          return F + "bed_canopy.png"
		"furnBedBlue":         return F + "bed_canopy.png"
		"furnBedGreen":        return F + "bed_canopy.png"
		"furnBedYellow":       return F + "bed_canopy.png"
		"furnSmallRedChest":   return F + "chest_open.png"
		"furnCabinetDouble":   return F + "armoire.png"
		"furnPictureFlower":   return F + "picture_sm.png"
		"furnPicturePortrait": return F + "picture_med.png"
		"furnWallMirror":      return F + "mirror_tall.png"
	return ""

# ── Entry point ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_background()
	_build_room()
	_build_physics()
	_spawn_player()
	_build_camera()
	_build_audio()
	_build_hud()
	_build_exit_tip()
	_fade_in()

func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -1
	add_child(cl)
	var bg := ColorRect.new()
	bg.color    = Color(0.04, 0.03, 0.02)
	bg.size     = Vector2(GAME_W, GAME_H)
	cl.add_child(bg)

func _build_room() -> void:
	var P := "res://assets/props/interior/"
	var roof_tex  := _tex(P + "house_roof.png")
	var wall_tex  := _tex(P + "house_wall.png")
	var wbase_tex := _tex(P + "wall_base.png")
	var floor1    := _tex(P + "floor_tile_1.png")
	var floor2    := _tex(P + "floor_tile_2.png")
	var door_tex  := _tex(P + "door_open.png")
	var win_file  := "red_window_open.png" if _window_type() == "red" else "blue_window_open.png"
	var win_tex   := _tex(P + win_file)

	_fill_row(roof_tex,  RY,                    TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y,                TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 64,           TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 128,          TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 192,          TILE, 64, 2)
	_fill_row(wbase_tex, WALL_BOT,              TILE, 32, 2)

	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		if not t: continue
		var sp := Sprite2D.new()
		sp.texture = t; sp.centered = false
		sp.position = Vector2(c * TILE, GY)
		sp.scale = Vector2(float(TILE) / t.get_width(), 16.0 / t.get_height())
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 2; add_child(sp)

	for wc in _window_cols():
		var sky := ColorRect.new()
		sky.color = Color(0.78, 0.87, 0.91)
		sky.position = Vector2(wc * TILE, WIN_Y)
		sky.size = Vector2(TILE, WIN_H)
		sky.z_index = 1; add_child(sky)
		if win_tex:
			var ws := _sprite(win_tex, wc * TILE, WIN_Y, TILE, WIN_H)
			ws.z_index = 4; add_child(ws)

	if door_tex:
		var ds := _sprite(door_tex, DOOR_X - TILE * 0.5, GY + 16 - DOOR_H, TILE, DOOR_H)
		ds.z_index = 5; add_child(ds)

	for f in _furniture():
		var path := _furn_path(f["key"])
		if path == "": continue
		var ft := _tex(path)
		if not ft: continue
		var cx := f["col"] * TILE + TILE * 0.5
		var flip: bool = f.get("flipX", false)
		var sp := Sprite2D.new()
		sp.texture = ft; sp.flip_h = flip
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.centered = false
		if f["placement"] == "wall":
			sp.position = Vector2(cx - ft.get_width() * 0.5, WALL_MID_Y - ft.get_height() * 0.5)
			sp.z_index = 7
		else:
			sp.position = Vector2(cx - ft.get_width() * 0.5, GY - ft.get_height())
			sp.z_index = 8
		add_child(sp)

func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _sprite(tex: Texture2D, x: float, y: float, w: float, h: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false
	sp.position = Vector2(x, y)
	sp.scale = Vector2(w / tex.get_width(), h / tex.get_height())
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _fill_row(tex: Texture2D, y: float, tw: float, th: float, z: int) -> void:
	if not tex: return
	for c in range(COLS):
		var sp := _sprite(tex, c * tw, y, tw, th)
		sp.z_index = z; add_child(sp)

func _build_physics() -> void:
	_sbox(GAME_W * 0.5, GY + 40,    GAME_W, 80)
	_sbox(GAME_W * 0.5, CEIL_Y - 20, GAME_W, 40)
	_sbox(4,            GAME_H * 0.5, 8,     GAME_H)
	_sbox(GAME_W - 4,  GAME_H * 0.5, 8,     GAME_H)

func _sbox(cx: float, cy: float, w: float, h: float) -> void:
	var b := StaticBody2D.new(); var s := CollisionShape2D.new()
	var r := RectangleShape2D.new(); r.size = Vector2(w, h)
	s.position = Vector2(cx, cy); s.shape = r; b.add_child(s); add_child(b)

func _spawn_player() -> void:
	var ps: PackedScene = load("res://scenes/Player.tscn")
	if not ps: return
	_player = ps.instantiate()
	_player.position = Vector2(DOOR_X + 80, GY - 1)
	_player.jumped.connect(_on_jumped)
	_player.attacked.connect(_on_attacked)
	add_child(_player)

func _on_jumped()  -> void: if _jump_sfx:   _jump_sfx.play()
func _on_attacked() -> void: if _attack_sfx: _attack_sfx.play()

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left = 0; _camera.limit_right  = GAME_W
	_camera.limit_top  = 0; _camera.limit_bottom = GAME_H
	_player.add_child(_camera)
	_camera.make_current()

func _build_audio() -> void:
	_music     = _aud("res://assets/audio/celadune_forest.mp3",                            0.0,  true)
	_door_sfx  = _aud("res://assets/sfx/dragon-studio-open-door-sfx-454245.mp3",          0.7,  false)
	_jump_sfx  = _aud("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                  0.45, false)
	_attack_sfx = _aud("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",    0.55, false)
	if _music:
		create_tween().tween_property(_music, "volume_db", linear_to_db(0.18), 0.8)

func _aud(path: String, vol: float, loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); add_child(p)
	if not ResourceLoader.exists(path): return p
	var s := load(path) as AudioStream
	if not s: return p
	if loop and s is AudioStreamMP3: (s as AudioStreamMP3).loop = true
	p.stream = s; p.volume_db = linear_to_db(vol if vol > 0 else 0.001)
	if loop: p.play()
	return p

func _build_hud() -> void:
	var hud := CanvasLayer.new(); hud.layer = 10; add_child(hud)

	var title := Label.new()
	title.text = _room_name()
	title.position = Vector2(GAME_W * 0.5 - 200, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.87, 0.80, 0.62, 0.85))
	hud.add_child(title)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); hud.add_child(bar_bg)

	var hp_bar := ColorRect.new()
	hp_bar.color = Color(0.87, 0.2, 0.2)
	var pct := float(Globals.player_health) / float(Globals.player_max_health)
	hp_bar.position = Vector2(26, GAME_H - 44); hp_bar.size = Vector2(176 * pct, 12)
	hud.add_child(hp_bar)

	var hp_lbl := Label.new()
	hp_lbl.text = "%d / %d" % [Globals.player_health, Globals.player_max_health]
	hp_lbl.position = Vector2(212, GAME_H - 46)
	hp_lbl.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hud.add_child(hp_lbl)

func _build_exit_tip() -> void:
	_exit_tip = Label.new()
	_exit_tip.text    = "Exit  (E)"
	_exit_tip.visible = false
	_exit_tip.add_theme_color_override("font_color", Color(0.97, 0.93, 0.84))
	_exit_tip.add_theme_font_size_override("font_size", 18)
	_exit_tip.z_index = 30
	add_child(_exit_tip)

func _fade_in() -> void:
	var cl := CanvasLayer.new(); cl.layer = 100; add_child(cl)
	var ov := ColorRect.new(); ov.size = Vector2(GAME_W, GAME_H); ov.color = Color(0,0,0,1)
	cl.add_child(ov)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.4)
	tw.tween_callback(ov.queue_free)

func _process(_delta: float) -> void:
	if not _player or _transitioning: return
	var near := absf(_player.position.x - DOOR_X) < EXIT_R
	if _exit_tip:
		_exit_tip.visible = near
		if near: _exit_tip.position = Vector2(DOOR_X - 30, GY - 90)
	if near and Input.is_action_just_pressed("interact"):
		_exit_interior()

func _exit_interior() -> void:
	_transitioning = true
	if _door_sfx: _door_sfx.play()
	Globals.from_transition = true
	Globals.spawn_x = _return_x()
	var dest := _return_scene()
	var cl := CanvasLayer.new(); cl.layer = 100; add_child(cl)
	var ov := ColorRect.new(); ov.size = Vector2(GAME_W, GAME_H); ov.color = Color(0,0,0,0)
	cl.add_child(ov)
	var tw := create_tween()
	if _music: tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + dest + ".tscn"))
