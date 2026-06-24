extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# Forest scene — porting reference (all values from Phaser main.js)
#
# Viewport:       1920 × 1080
# World:          5184 × 1080  (54 tiles × 96 px)
# GROUND_Y:       888           top surface of tiles
# PROP_BASE:      903           bottom anchor for props/buildings
# BLACK_TILE_Y:   927           GROUND_Y + 39 (soil visual baseline)
# Scene boundary: walk right past x≈5100 on ground → CityScene
# Hut door zone:  x=2274, y=823, 150×132px (hut.x+34, HUT_BASELINE_Y-80)
# NPC proximity:  ≤150 world-px to show tooltip / trigger dialogue
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 5184
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const PROP_BASE    := 903
const TILE_PX      := 96
const NPC_GROUND_Y := 798.0   # sprite center Y on floor (derived in NPC.gd)

# Hut door interaction zone (from Phaser: hut.x=2240, hut.x+34=2274, HUT_BASELINE_Y-80=823)
const HUT_DOOR_X   := 2274.0
const HUT_DOOR_Y   := 823.0
const HUT_DOOR_R   := 110.0   # interaction radius

# Tile frame indices (floor_tiles2.png: 9 cols × 18 rows, 96×96 each)
const T_TOP_L := 0;  const T_TOP_C := 1;  const T_TOP_R := 2;  const T_FILL := 10

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

# ── Runtime state ─────────────────────────────────────────────────────────────
var _player:        CharacterBody2D
var _camera:        Camera2D
var _music:         AudioStreamPlayer
var _jump_sfx:      AudioStreamPlayer
var _attack_sfx:    AudioStreamPlayer
var _door_sfx:      AudioStreamPlayer
var _parallax_bg:   ParallaxBackground
var _sky_layer:     ParallaxLayer   # for auto-drift
var _sky_drift:     float = 0.0

var _transitioning := false
var _player_health := 10
var _player_max_hp := 10

# HUD nodes
var _hp_bar_fg:   ColorRect
var _hp_label:    Label
var _menu_hint:   Label

# NPC tooltips
var _mirelle_tooltip: Label
var _aldric_tooltip:  Label
var _lena_tooltip:    Label
var _hut_tooltip:     Label
var _mirelle:         Node2D
var _aldric:          Node2D
var _lena:            Node2D

func _ready() -> void:
	_build_parallax()
	_build_ground_physics()
	_build_ground_tiles()
	_build_props()
	_spawn_player()
	_spawn_npcs()
	_build_camera()
	_build_audio()
	_build_hud()
	_fade_in()

# ── Parallax ──────────────────────────────────────────────────────────────────
func _build_parallax() -> void:
	_parallax_bg = ParallaxBackground.new()
	add_child(_parallax_bg)

	for i in range(BG_LAYERS.size()):
		var cfg: Dictionary = BG_LAYERS[i]
		var tex: Texture2D = load(cfg["path"])
		if not tex:
			continue
		var s := float(GAME_H) / float(tex.get_height())
		var w := tex.get_width() * s

		var layer := ParallaxLayer.new()
		layer.motion_scale    = Vector2(cfg["factor"], 0.0)
		layer.motion_mirroring = Vector2(w, 0.0)
		_parallax_bg.add_child(layer)

		var sp := Sprite2D.new()
		sp.texture        = tex
		sp.centered       = false
		sp.scale          = Vector2(s, s)
		sp.position       = Vector2(0.0, cfg["y_off"])
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(sp)

		if i == 0:
			_sky_layer = layer   # used for auto-drift

# ── Ground physics ────────────────────────────────────────────────────────────
func _build_ground_physics() -> void:
	var body  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size     = Vector2(WORLD_WIDTH * 2.0, 400.0)
	shape.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 200.0)
	shape.shape   = rect
	body.add_child(shape)
	add_child(body)

# ── Ground tiles (visual) ─────────────────────────────────────────────────────
func _build_ground_tiles() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := WORLD_WIDTH / TILE_PX   # 54

	for col in range(cols):
		var cx := col * TILE_PX + TILE_PX / 2

		var top_frame := T_TOP_C
		if col == 0:           top_frame = T_TOP_L
		elif col == cols - 1:  top_frame = T_TOP_R

		_tile(tile_tex, cx, GROUND_Y + TILE_PX / 2, top_frame, 12)

		var fill_rows := int(ceil(float(GAME_H - GROUND_Y) / TILE_PX)) + 1
		for row in range(1, fill_rows + 1):
			_tile(tile_tex, cx, GROUND_Y + TILE_PX * row + TILE_PX / 2, T_FILL, 2)

		var bg       := ColorRect.new()
		bg.color     = Color(0.102, 0.071, 0.031)
		bg.size      = Vector2(TILE_PX, GAME_H + 200 - GROUND_Y)
		bg.position  = Vector2(cx - TILE_PX / 2, GROUND_Y)
		bg.z_index   = 1
		add_child(bg)

func _tile(tex: Texture2D, cx: float, cy: float, frame: int, z: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas  = tex
	atlas.region = Rect2((frame % 9) * TILE_PX, (frame / 9) * TILE_PX, TILE_PX, TILE_PX)
	var sp := Sprite2D.new()
	sp.texture        = atlas
	sp.centered       = true
	sp.position       = Vector2(cx, cy)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index        = z
	add_child(sp)

# ── Props ─────────────────────────────────────────────────────────────────────
func _build_props() -> void:
	# Left camp area
	_prop("res://assets/props/broken_wagon.png",     360,  PROP_BASE, 7)
	_prop("res://assets/props/decor_small_tent.png", 610,  PROP_BASE, 7)
	_prop("res://assets/props/decor_wood_logs.png",  730,  PROP_BASE, 6)
	_prop("res://assets/props/decor_cauldron.png",   730,  PROP_BASE, 7)

	# Pumpkin patch
	for px in [1400, 1510, 1660, 1740, 1820]:
		_prop("res://assets/props/decor_pumpkin_large.png", px, PROP_BASE, 7)
	for px in [1460, 1700, 1780]:
		_prop("res://assets/props/decor_pumpkin_small.png", px, PROP_BASE, 7)

	_prop("res://assets/props/scarecrow.png",         1590, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_small.png", 1910, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 1960, PROP_BASE, 7)

	# Hut
	_prop("res://assets/buildings/forest_hut/building.png", 2240, PROP_BASE, 7)

	# Onion patches + grass in crops
	for ox in [2790, 2990, 3130, 3260]:
		_prop("res://assets/props/onion_patch.png", ox, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_small.png", 3060, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 3200, PROP_BASE, 7)

	# Right side flora
	_prop("res://assets/props/sunflowers.png", 3420, PROP_BASE, 7)
	_prop("res://assets/props/sunflowers.png", 3530, PROP_BASE, 7)
	_prop("res://assets/props/bush_large.png", 3700, PROP_BASE, 7)
	_prop("res://assets/props/bush_small.png", 3820, PROP_BASE, 7)

func _prop(path: String, x: float, base_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex:
		push_warning("Forest: missing prop: " + path)
		return
	var sp := Sprite2D.new()
	sp.texture        = tex
	sp.centered       = true
	sp.offset         = Vector2(0.0, -tex.get_height() * 0.5)
	sp.position       = Vector2(x, base_y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index        = z
	add_child(sp)

# ── Player ────────────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(300.0, 768.0)   # above ground — falls via gravity
	_player.jumped.connect(_on_player_jumped)
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)

# ── NPCs ──────────────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	var scene: PackedScene = load("res://scenes/NPC.tscn")

	_mirelle = _make_npc(scene, {
		"npc_name": "Mirelle", "walk_path": "res://assets/npcs/forest_lady/walk.png",
		"idle_path": "res://assets/npcs/forest_lady/idle.png",
		"patrol_min_x": 2420.0, "patrol_max_x": 2660.0,
		"patrol_speed": 95.0, "pause_ms": 5000.0,
	})
	_mirelle.position = Vector2(2420.0, NPC_GROUND_Y)
	add_child(_mirelle)

	_aldric = _make_npc(scene, {
		"npc_name": "Aldric", "walk_path": "res://assets/npcs/hut_wanderer/walk.png",
		"idle_path": "res://assets/npcs/hut_wanderer/idle.png",
		"patrol_min_x": 1860.0, "patrol_max_x": 2170.0,
		"patrol_speed": 48.0, "pause_ms": 3500.0,
	})
	_aldric.position = Vector2(2015.0, NPC_GROUND_Y)
	add_child(_aldric)

	_lena = _make_npc(scene, {
		"npc_name": "Lena", "walk_path": "res://assets/npcs/farm_worker/walk.png",
		"idle_path": "res://assets/npcs/farm_worker/idle.png",
		"patrol_min_x": 2950.0, "patrol_max_x": 3300.0,
		"patrol_speed": 40.0, "pause_ms": 4500.0,
	})
	_lena.position = Vector2(3050.0, NPC_GROUND_Y)
	add_child(_lena)

func _make_npc(scene: PackedScene, cfg: Dictionary) -> Node2D:
	var n = scene.instantiate()
	for key in cfg:
		n.set(key, cfg[key])
	return n

# ── Camera ────────────────────────────────────────────────────────────────────
func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0
	_camera.limit_right  = WORLD_WIDTH
	_camera.limit_top    = 0
	_camera.limit_bottom = GAME_H
	# Replicate Phaser: startFollow(player, true, lerpX=0.08, lerpY=0.08) + deadzone(264,144)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 5.0
	_camera.drag_horizontal_enabled    = true
	_camera.drag_vertical_enabled      = true
	# Deadzone margins as fractions of viewport: 264/2/1920, 144/2/1080
	_camera.drag_left_margin   = 0.069
	_camera.drag_right_margin  = 0.069
	_camera.drag_top_margin    = 0.067
	_camera.drag_bottom_margin = 0.067
	_player.add_child(_camera)

# ── Audio ─────────────────────────────────────────────────────────────────────
func _build_audio() -> void:
	_music      = _audio("res://assets/audio/celadune_forest.mp3", 0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",         0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3", 0.55, false)
	_door_sfx   = _audio("res://assets/sfx/dragon-studio-open-door-sfx-454245.mp3", 0.7,  false)

	# Fade music in on scene start (Phaser fades from 0 → 0.42 over 320ms)
	_music.play()
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", linear_to_db(0.42), 0.32)

func _audio(path: String, vol: float, loop: bool) -> AudioStreamPlayer:
	var p   := AudioStreamPlayer.new()
	var res := load(path) as AudioStream
	if not res:
		push_warning("Forest: missing audio: " + path)
	else:
		p.stream = res
		if res is AudioStreamMP3:
			(res as AudioStreamMP3).loop = loop
	p.volume_db = linear_to_db(vol)
	add_child(p)
	return p

func _on_player_jumped()   -> void: _jump_sfx.play()
func _on_player_attacked() -> void: _attack_sfx.play()

# ── HUD (fixed to screen — CanvasLayer ensures it ignores camera) ─────────────
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	# Health bar (Phaser: barX=24, barY=GAME_H-46=1034, barW=180, barH=16)
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46)
	bar_bg.size     = Vector2(180, 16)
	bar_bg.color    = Color(0.1, 0.04, 0.04, 0.85)
	hud.add_child(bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.position = Vector2(26, GAME_H - 44)
	_hp_bar_fg.size     = Vector2(176, 12)
	_hp_bar_fg.color    = Color(0.87, 0.2, 0.2)
	hud.add_child(_hp_bar_fg)

	var hp_lbl := Label.new()
	hp_lbl.text            = "HP"
	hp_lbl.position        = Vector2(24, GAME_H - 62)
	hp_lbl.add_theme_color_override("font_color", Color(0.87, 0.2, 0.2))
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hud.add_child(hp_lbl)

	_hp_label = Label.new()
	_hp_label.text     = "10 / 10"
	_hp_label.position = Vector2(212, GAME_H - 46)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hp_label.add_theme_font_size_override("font_size", 13)
	hud.add_child(_hp_label)

	# M Menu hint (Phaser: GAME_WIDTH-18, GAME_HEIGHT-20, origin 1,1)
	_menu_hint = Label.new()
	_menu_hint.text     = "M  Menu"
	_menu_hint.position = Vector2(GAME_W - 120, GAME_H - 32)
	_menu_hint.add_theme_color_override("font_color", Color(0.78, 0.87, 0.92))
	_menu_hint.add_theme_font_size_override("font_size", 18)
	hud.add_child(_menu_hint)

	# Tooltip labels (world-space, added to scene not HUD)
	_mirelle_tooltip = _tooltip("Mirelle")
	_aldric_tooltip  = _tooltip("Aldric")
	_lena_tooltip    = _tooltip("Lena")
	_hut_tooltip     = _tooltip("Mirelle's Farmhouse")

func _tooltip(text: String) -> Label:
	var lbl := Label.new()
	lbl.text    = text
	lbl.visible = false
	lbl.z_index = 30
	lbl.add_theme_color_override("font_color",    Color(0.97, 0.93, 0.84))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_font_size_override("font_size", 16)
	add_child(lbl)
	return lbl

# ── Fade-in overlay (Phaser: 3.5s on first load, black → transparent) ────────
func _fade_in() -> void:
	var overlay := ColorRect.new()
	overlay.color         = Color(0, 0, 0, 1)
	overlay.size          = Vector2(GAME_W, GAME_H)
	overlay.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	# Put in CanvasLayer so it covers everything
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)
	var tween := create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 1.5)
	tween.tween_callback(overlay.queue_free)

# ── Per-frame update ──────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _player:
		return

	# Sky auto-drift (Phaser: tilePositionX -= 0.1 per frame)
	_sky_drift -= 0.1
	if _sky_layer:
		_parallax_bg.scroll_offset = Vector2(_sky_drift, 0.0)

	_update_tooltips()
	_check_scene_boundaries()

func _update_tooltips() -> void:
	var px := _player.position.x
	var py := _player.position.y

	# NPC tooltips (≤150px)
	if _mirelle:
		var near := Vector2(px, py).distance_to(_mirelle.position) < 150.0
		_mirelle_tooltip.visible = near
		if near: _mirelle_tooltip.position = _mirelle.position + Vector2(-40, -110)

	if _aldric:
		var near := Vector2(px, py).distance_to(_aldric.position) < 150.0
		_aldric_tooltip.visible = near
		if near: _aldric_tooltip.position = _aldric.position + Vector2(-30, -110)

	if _lena:
		var near := Vector2(px, py).distance_to(_lena.position) < 150.0
		_lena_tooltip.visible = near
		if near: _lena_tooltip.position = _lena.position + Vector2(-20, -110)

	# Hut door tooltip
	var hut_dist := Vector2(px, py).distance_to(Vector2(HUT_DOOR_X, HUT_DOOR_Y))
	_hut_tooltip.visible = hut_dist < HUT_DOOR_R * 1.5
	if _hut_tooltip.visible:
		_hut_tooltip.position = Vector2(HUT_DOOR_X - 90, HUT_DOOR_Y - 80)

	# E / Enter to interact
	if Input.is_action_just_pressed("interact"):
		if hut_dist < HUT_DOOR_R:
			_enter_hut()
		elif _mirelle and Vector2(px, py).distance_to(_mirelle.position) < 150.0:
			pass  # TODO: open dialogue "mirelle"
		elif _aldric and Vector2(px, py).distance_to(_aldric.position) < 150.0:
			pass  # TODO: open dialogue "aldric"
		elif _lena and Vector2(px, py).distance_to(_lena.position) < 150.0:
			pass  # TODO: open dialogue "lena"

func _enter_hut() -> void:
	if _transitioning:
		return
	_transitioning = true
	_door_sfx.play()
	# TODO: transition to HutInteriorScene when it's built
	# For now just play the door sound and reset
	await get_tree().create_timer(0.5).timeout
	_transitioning = false

func _check_scene_boundaries() -> void:
	if _transitioning or not _player:
		return
	# Phaser: player walking right past world edge → CityScene
	# "if velocityX > 0 and blocked.right and player.x > WORLD_WIDTH - 150"
	if _player.position.x > WORLD_WIDTH - 120 and _player.velocity.x > 0:
		_transition_to("City")

func _transition_to(scene_name: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_player.set_physics_process(false)

	# Fade music out (220ms)
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", -80.0, 0.22)

	# Black overlay fade, then change scene
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size  = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)

	var t2 := create_tween()
	t2.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.22)
	t2.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + scene_name + ".tscn"))
