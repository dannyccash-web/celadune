extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Forest (overworld) scene
# World 5184 × 1080  |  GROUND_Y = 888  |  54 tiles × 96 px
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 5184
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const PROP_BASE    := 903
const TILE_PX      := 96
const NPC_GROUND_Y := 798.0

const HUT_DOOR_X   := 2274.0
const HUT_DOOR_Y   := 823.0
const HUT_DOOR_R   := 110.0
const NPC_TALK_R   := 150.0

const T_TOP_L := 0; const T_TOP_C := 1; const T_TOP_R := 2; const T_FILL := 10

const DOG_SCALE     := 3.1
const DOG_FRAME_SZ  := 32
const DOG_WALK_ROW  := 0
const DOG_FIRST_FR  := 6
const DOG_LAST_FR   := 11
const DOG_GROUND_Y  := 838.0   # 888 - (32*3.1)/2
const DOG_MIN_X     := 350.0
const DOG_MAX_X     := 3100.0
const DOG_SPEED     := 62.0
const DOG_FLEE_SPD  := 240.0

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

# ── Nodes ─────────────────────────────────────────────────────────────────────
var _player:        CharacterBody2D
var _camera:        Camera2D
var _parallax_bg:   ParallaxBackground
var _sky_layer:     ParallaxLayer
var _sky_drift:     float = 0.0

# NPCs
var _mirelle: Node2D
var _aldric:  Node2D
var _lena:    Node2D

# Dog
var _dog_node:   Node2D       # contains AnimatedSprite2D
var _dog_sprite: AnimatedSprite2D
var _dog_dir:    int   = 1
var _dog_pause:  float = 0.0
var _dog_flee:   bool  = false
var _dog_gone:   bool  = false

# Audio
var _music:      AudioStreamPlayer
var _jump_sfx:   AudioStreamPlayer
var _attack_sfx: AudioStreamPlayer
var _door_sfx:   AudioStreamPlayer
var _hurt_sfx:   AudioStreamPlayer
var _bark_sfx:   AudioStreamPlayer

# HUD
var _hp_bar_fg: ColorRect
var _hp_label:  Label
var _hud_layer: CanvasLayer

# Tooltip labels (world-space)
var _mirelle_tip: Label
var _aldric_tip:  Label
var _lena_tip:    Label
var _hut_tip:     Label

# Dialogue & menu
var _dialogue_box:   Node
var _menu_panel:     Node
var _dialogue_seq:   Array = []
var _dialogue_idx:   int   = 0
var _active_npc:     String = ""
var _dialogue_state: String = ""
var _mirelle_portrait: SpriteFrames = null

# State
var _intro_complete: bool = false
var _transitioning:  bool = false
var _dialogue_open:  bool = false
var _menu_open:      bool = false

# Item popup
var _popup_label: Label
var _popup_timer: float = 0.0
var _popup_layer: CanvasLayer

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_parallax()
	_build_ground_physics()
	_build_ground_tiles()
	_build_props()
	_spawn_player()
	_spawn_npcs()
	_spawn_dog()
	_build_camera()
	_build_audio()
	_build_hud()
	_build_dialogue()
	_build_menu()
	_build_popup()
	_fade_in()
	_run_intro()   # async — runs in background

# ── Parallax ──────────────────────────────────────────────────────────────────

func _build_parallax() -> void:
	_parallax_bg = ParallaxBackground.new()
	add_child(_parallax_bg)
	for i in range(BG_LAYERS.size()):
		var cfg: Dictionary = BG_LAYERS[i]
		var tex: Texture2D = load(cfg["path"])
		if not tex: continue
		var s  := float(GAME_H) / float(tex.get_height())
		var layer := ParallaxLayer.new()
		layer.motion_scale     = Vector2(cfg["factor"], 0.0)
		layer.motion_mirroring = Vector2(tex.get_width() * s, 0.0)
		_parallax_bg.add_child(layer)
		var sp := Sprite2D.new()
		sp.texture = tex; sp.centered = false; sp.scale = Vector2(s, s)
		sp.position = Vector2(0.0, cfg["y_off"])
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(sp)
		if i == 0: _sky_layer = layer

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

# ── Ground tiles ──────────────────────────────────────────────────────────────

func _build_ground_tiles() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := WORLD_WIDTH / TILE_PX
	for col in range(cols):
		var cx := col * TILE_PX + TILE_PX / 2
		var top := T_TOP_C
		if col == 0:          top = T_TOP_L
		elif col == cols - 1: top = T_TOP_R
		_tile(tile_tex, cx, GROUND_Y + TILE_PX / 2, top, 12)
		var fill_rows := int(ceil(float(GAME_H - GROUND_Y) / TILE_PX)) + 1
		for row in range(1, fill_rows + 1):
			_tile(tile_tex, cx, GROUND_Y + TILE_PX * row + TILE_PX / 2, T_FILL, 2)
		var bg := ColorRect.new()
		bg.color    = Color(0.102, 0.071, 0.031)
		bg.size     = Vector2(TILE_PX, GAME_H + 200 - GROUND_Y)
		bg.position = Vector2(cx - TILE_PX / 2, GROUND_Y)
		bg.z_index  = 1; add_child(bg)

func _tile(tex: Texture2D, cx: float, cy: float, frame: int, z: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas  = tex
	atlas.region = Rect2((frame % 9) * TILE_PX, (frame / 9) * TILE_PX, TILE_PX, TILE_PX)
	var sp := Sprite2D.new(); sp.texture = atlas; sp.centered = true
	sp.position = Vector2(cx, cy); sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = z; add_child(sp)

# ── Props ─────────────────────────────────────────────────────────────────────

func _build_props() -> void:
	_prop("res://assets/props/broken_wagon.png",     360,  PROP_BASE, 7)
	_prop("res://assets/props/decor_small_tent.png", 610,  PROP_BASE, 7)
	_prop("res://assets/props/decor_wood_logs.png",  730,  PROP_BASE, 6)
	_prop("res://assets/props/decor_cauldron.png",   730,  PROP_BASE, 7)
	for px in [1400, 1510, 1660, 1740, 1820]:
		_prop("res://assets/props/decor_pumpkin_large.png", px, PROP_BASE, 7)
	for px in [1460, 1700, 1780]:
		_prop("res://assets/props/decor_pumpkin_small.png", px, PROP_BASE, 7)
	_prop("res://assets/props/scarecrow.png",         1590, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_small.png", 1910, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 1960, PROP_BASE, 7)
	_prop("res://assets/buildings/forest_hut/building.png", 2240, PROP_BASE, 7)
	for ox in [2790, 2990, 3130, 3260]:
		_prop("res://assets/props/onion_patch.png", ox, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_small.png", 3060, PROP_BASE, 7)
	_prop("res://assets/props/decor_grass_large.png", 3200, PROP_BASE, 7)
	_prop("res://assets/props/sunflowers.png", 3420, PROP_BASE, 7)
	_prop("res://assets/props/sunflowers.png", 3530, PROP_BASE, 7)
	_prop("res://assets/props/bush_large.png", 3700, PROP_BASE, 7)
	_prop("res://assets/props/bush_small.png", 3820, PROP_BASE, 7)

func _prop(path: String, x: float, base_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex: push_warning("Forest: missing prop " + path); return
	var sp := Sprite2D.new(); sp.texture = tex; sp.centered = true
	sp.offset         = Vector2(0.0, -tex.get_height() * 0.5)
	sp.position       = Vector2(x, base_y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = z; add_child(sp)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(Globals.spawn_x, 835.0)
	_player.jumped.connect(_on_player_jumped)
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)

# ── NPCs ──────────────────────────────────────────────────────────────────────

func _spawn_npcs() -> void:
	var scene: PackedScene = load("res://scenes/NPC.tscn")
	_mirelle = _make_npc(scene, {
		"npc_name": "Mirelle",
		"walk_path": "res://assets/npcs/forest_lady/walk.png",
		"idle_path": "res://assets/npcs/forest_lady/idle.png",
		"patrol_min_x": 2420.0, "patrol_max_x": 2660.0,
		"patrol_speed": 95.0, "pause_ms": 5000.0,
	})
	_mirelle.position = Vector2(2530.0, NPC_GROUND_Y)
	add_child(_mirelle)

	_aldric = _make_npc(scene, {
		"npc_name": "Aldric",
		"walk_path": "res://assets/npcs/hut_wanderer/walk.png",
		"idle_path": "res://assets/npcs/hut_wanderer/idle.png",
		"patrol_min_x": 1860.0, "patrol_max_x": 2170.0,
		"patrol_speed": 48.0, "pause_ms": 3500.0,
	})
	_aldric.position = Vector2(2015.0, NPC_GROUND_Y)
	add_child(_aldric)

	_lena = _make_npc(scene, {
		"npc_name": "Lena",
		"walk_path": "res://assets/npcs/farm_worker/walk.png",
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

# ── Dog ───────────────────────────────────────────────────────────────────────

func _spawn_dog() -> void:
	if Globals.farm_dog_fled: return
	var dog_tex: Texture2D = load("res://assets/npcs/dog/sheet.png")
	if not dog_tex: return

	_dog_node = Node2D.new()
	_dog_node.position = Vector2(750.0, DOG_GROUND_Y)
	_dog_node.z_index  = 8
	add_child(_dog_node)

	_dog_sprite = AnimatedSprite2D.new()
	_dog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dog_sprite.scale = Vector2(DOG_SCALE, DOG_SCALE)
	_dog_sprite.flip_h = true  # starts facing right

	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 8.0)
	for i in range(DOG_FIRST_FR, DOG_LAST_FR + 1):
		var a := AtlasTexture.new()
		a.atlas  = dog_tex
		var _fpr_local := 192 / DOG_FRAME_SZ; a.region = Rect2((i % _fpr_local) * DOG_FRAME_SZ, (i / _fpr_local) * DOG_FRAME_SZ, DOG_FRAME_SZ, DOG_FRAME_SZ)
		sf.add_frame("walk", a)
	_dog_sprite.sprite_frames = sf
	_dog_sprite.play("walk")

	_dog_node.add_child(_dog_sprite)

# ── Camera ────────────────────────────────────────────────────────────────────

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0; _camera.limit_right  = WORLD_WIDTH
	_camera.limit_top    = 0; _camera.limit_bottom = GAME_H
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 5.0
	_camera.drag_horizontal_enabled = true; _camera.drag_vertical_enabled = true
	_camera.drag_left_margin  = 0.069; _camera.drag_right_margin  = 0.069
	_camera.drag_top_margin   = 0.067; _camera.drag_bottom_margin = 0.067
	_player.add_child(_camera)

# ── Audio ─────────────────────────────────────────────────────────────────────

func _build_audio() -> void:
	_music      = _audio("res://assets/audio/celadune_forest.mp3",                                       0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                              0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",                 0.55, false)
	_door_sfx   = _audio("res://assets/sfx/dragon-studio-open-door-sfx-454245.mp3",                     0.7,  false)
	_hurt_sfx   = _audio("res://assets/sfx/freesound_community-male_hurt7-48124.mp3",                    0.6,  false)
	_bark_sfx   = _audio("res://assets/sfx/freesound_community-dog-bark2-92560.mp3",                     0.55, false)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.42), 0.32)

func _audio(path: String, vol: float, loop: bool) -> AudioStreamPlayer:
	var p   := AudioStreamPlayer.new()
	var res := load(path) as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = loop
		p.stream = res
	p.volume_db = linear_to_db(vol)
	add_child(p)
	return p

func _on_player_jumped()   -> void: _jump_sfx.play()
func _on_player_attacked() -> void:
	_attack_sfx.play()
	# Only flee if dog is within 400px — matches Phaser's "nearby" check
	if _dog_node and not _dog_flee and not _dog_gone:
		if absf(_player.position.x - _dog_node.position.x) < 400.0:
			_trigger_dog_flee()

# ── HUD ───────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new(); _hud_layer.layer = 10; add_child(_hud_layer)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); _hud_layer.add_child(bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.position = Vector2(26, GAME_H - 44); _hp_bar_fg.size = Vector2(176, 12)
	_hp_bar_fg.color = Color(0.87, 0.2, 0.2); _hud_layer.add_child(_hp_bar_fg)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"; hp_lbl.position = Vector2(24, GAME_H - 62)
	hp_lbl.add_theme_color_override("font_color", Color(0.87, 0.2, 0.2))
	hp_lbl.add_theme_font_size_override("font_size", 13); _hud_layer.add_child(hp_lbl)

	_hp_label = Label.new()
	_hp_label.text = "10 / 10"; _hp_label.position = Vector2(212, GAME_H - 46)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hp_label.add_theme_font_size_override("font_size", 13); _hud_layer.add_child(_hp_label)

	var mhint := Label.new()
	mhint.text = "M  Menu"; mhint.position = Vector2(GAME_W - 120, GAME_H - 32)
	mhint.add_theme_color_override("font_color", Color(0.78, 0.87, 0.92))
	mhint.add_theme_font_size_override("font_size", 18); _hud_layer.add_child(mhint)

	# Tooltips (world-space)
	_mirelle_tip = _tooltip("Mirelle")
	_aldric_tip  = _tooltip("Aldric")
	_lena_tip    = _tooltip("Lena")
	_hut_tip     = _tooltip("Mirelle's Farmhouse")

func _tooltip(text: String) -> Label:
	var lbl := Label.new(); lbl.text = text; lbl.visible = false; lbl.z_index = 30
	lbl.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_font_size_override("font_size", 16)
	add_child(lbl); return lbl

func _refresh_hud() -> void:
	var pct := float(Globals.player_health) / float(Globals.player_max_health)
	_hp_bar_fg.size.x = 176.0 * pct
	_hp_label.text    = "%d / %d" % [Globals.player_health, Globals.player_max_health]

# ── Dialogue UI ───────────────────────────────────────────────────────────────

func _build_dialogue() -> void:
	var db_script: GDScript = load("res://scripts/DialogueBox.gd")
	_dialogue_box = db_script.new()
	add_child(_dialogue_box)
	_dialogue_box.choice_confirmed.connect(_on_dialogue_choice)
	_dialogue_box.dismissed.connect(_on_dialogue_dismissed)

# ── Menu UI ───────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var mp_script: GDScript = load("res://scripts/MenuPanel.gd")
	_menu_panel = mp_script.new()
	add_child(_menu_panel)
	_menu_panel.closed.connect(_on_menu_closed)

# ── Item popup ────────────────────────────────────────────────────────────────

func _build_popup() -> void:
	_popup_layer = CanvasLayer.new(); _popup_layer.layer = 70; add_child(_popup_layer)
	_popup_label = Label.new()
	_popup_label.visible = false
	_popup_label.add_theme_font_override("font", Globals.FONT_TITLE)
	_popup_label.add_theme_font_size_override("font_size", 32)
	_popup_label.add_theme_color_override("font_color",        Color(1.0, 0.95, 0.50))
	_popup_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_popup_label.add_theme_constant_override("shadow_offset_x", 2)
	_popup_label.add_theme_constant_override("shadow_offset_y", 2)
	_popup_layer.add_child(_popup_label)

func show_item_popup(text: String) -> void:
	_popup_label.text    = "+ " + text
	_popup_label.visible = true
	_popup_label.position = Vector2(GAME_W / 2 - 80, GAME_H / 2 - 160)
	_popup_timer = 2.8
	var tw := create_tween()
	tw.tween_property(_popup_label, "position:y", GAME_H / 2 - 220, 2.8)

# ── Fade-in ───────────────────────────────────────────────────────────────────

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 1.2)
	tw.tween_callback(ov.queue_free)

# ── Intro sequence ────────────────────────────────────────────────────────────

func _run_intro() -> void:
	if Globals.from_transition:
		Globals.from_transition = false
		_intro_complete = true
		return
	_intro_complete = false
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO
	var spr: AnimatedSprite2D = _player.get_node("Sprite")
	spr.play("death")
	spr.frame = 2
	spr.pause()
	await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(self): return
	spr.play("rise")
	await spr.animation_finished
	if not is_instance_valid(self): return
	_player.set_physics_process(true)
	spr.play("idle")
	_intro_complete = true

# ══════════════════════════════════════════════════════════════════════════════
# Per-frame
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _player: return
	if not _intro_complete: return

	# Sky drift
	_sky_drift -= 0.1
	if _sky_layer: _parallax_bg.scroll_offset = Vector2(_sky_drift, 0.0)

	# Popup timer
	if _popup_timer > 0.0:
		_popup_timer -= delta
		if _popup_timer <= 0.0:
			_popup_label.visible = false

	if _dialogue_open or _menu_open: return

	_update_tooltips(delta)
	_update_dog(delta)

	# M key or Esc → menu
	if Input.is_action_just_pressed("menu_toggle") and not _dialogue_open:
		_open_menu(); return

	_check_scene_boundaries()

func _update_tooltips(_delta: float) -> void:
	var px := _player.position.x
	var py := _player.position.y

	_update_tip(_mirelle_tip, _mirelle, px, py, Vector2(-40, -110))
	_update_tip(_aldric_tip,  _aldric,  px, py, Vector2(-30, -110))
	_update_tip(_lena_tip,    _lena,    px, py, Vector2(-20, -110))

	var hd := Vector2(px, py).distance_to(Vector2(HUT_DOOR_X, HUT_DOOR_Y))
	_hut_tip.visible = hd < HUT_DOOR_R * 1.5
	if _hut_tip.visible:
		_hut_tip.position = Vector2(HUT_DOOR_X - 90, HUT_DOOR_Y - 80)

	if Input.is_action_just_pressed("interact"):
		if hd < HUT_DOOR_R:
			_enter_hut()
		elif _mirelle and Vector2(px, py).distance_to(_mirelle.position) < NPC_TALK_R:
			_open_mirelle_dialogue()
		elif _aldric and Vector2(px, py).distance_to(_aldric.position) < NPC_TALK_R:
			_open_aldric_dialogue()
		elif _lena and Vector2(px, py).distance_to(_lena.position) < NPC_TALK_R:
			_open_lena_dialogue()

func _update_tip(lbl: Label, npc: Node2D, px: float, py: float, off: Vector2) -> void:
	if not npc: lbl.visible = false; return
	var near := Vector2(px, py).distance_to(npc.position) < NPC_TALK_R
	lbl.visible = near
	if near: lbl.position = npc.position + off

# ── Dog AI ────────────────────────────────────────────────────────────────────

func _update_dog(delta: float) -> void:
	if not _dog_node or _dog_gone: return

	if _dog_pause > 0.0:
		_dog_pause -= delta
		return

	var spd: float = DOG_FLEE_SPD if _dog_flee else DOG_SPEED
	_dog_node.position.x += _dog_dir * spd * delta
	_dog_sprite.flip_h = _dog_dir > 0

	if _dog_flee:
		# Remove once off bounds
		if _dog_node.position.x < DOG_MIN_X - 200 or _dog_node.position.x > DOG_MAX_X + 200:
			_dog_node.queue_free()
			_dog_node   = null
			_dog_gone   = true
			Globals.farm_dog_fled = true
		return

	# Normal patrol
	if _dog_dir > 0 and _dog_node.position.x >= DOG_MAX_X:
		_dog_node.position.x = DOG_MAX_X
		_dog_dir   = -1
		_dog_pause = randf_range(1.5, 4.0)
	elif _dog_dir < 0 and _dog_node.position.x <= DOG_MIN_X:
		_dog_node.position.x = DOG_MIN_X
		_dog_dir   = 1
		_dog_pause = randf_range(1.5, 4.0)

func _trigger_dog_flee() -> void:
	if not _dog_node or _dog_flee or _dog_gone: return
	_dog_flee = true
	_bark_sfx.play()
	# Flee away from player
	_dog_dir = 1 if _dog_node.position.x > _player.position.x else -1
	Globals.change_reputation(-0.5)

# ══════════════════════════════════════════════════════════════════════════════
# Dialogue
# ══════════════════════════════════════════════════════════════════════════════

func _open_dialogue_direct(npc_id: String, npc_node: Node2D) -> void:
	_dialogue_open = true
	_active_npc    = npc_id
	_dialogue_state = ""
	_player.set_physics_process(false)
	if npc_node: npc_node.pause_patrol()

func _npc_for_id(npc_id: String) -> Node2D:
	match npc_id:
		"mirelle": return _mirelle
		"aldric":  return _aldric
		"lena":    return _lena
	return null

# ── Mirelle dialogue (full Phaser state machine) ──────────────────────────────

func _open_mirelle_dialogue() -> void:
	if not _mirelle: return
	var rep := Globals.player_reputation
	_mirelle_portrait = DialogueBox.make_portrait_frames("res://assets/npcs/forest_lady/idle.png", 5)
	_open_dialogue_direct("mirelle", _mirelle)

	if rep == 1:
		_dialogue_state = "mirelleHostile"
		_dialogue_box.show_line("Mirelle",
			"I want nothing from you right now, Caelan. You've brought nothing but trouble lately. Come back when things have settled.",
			["...Understood."], _mirelle_portrait)
		return

	if Globals.story_flags.get("mirelle_quest_complete", false):
		var after_lines := {
			2: "I still have doubts about you, Caelan. But you did deliver those onions.",
			3: "You did your job. That's all I ask.",
			4: "Thank you again for delivering the onions, Caelan. You did right by me.",
			5: "The farm is in good hands with you here, Caelan. Truly.",
			6: "Every day I am grateful to have you looking after this place.",
			7: "There is no one I'd trust more with this farm. You're a good man.",
		}
		_dialogue_state = "mirelleAfterQuest"
		_dialogue_box.show_line("Mirelle", after_lines.get(rep, after_lines[4]),
			["Take care, Mirelle."], _mirelle_portrait)
		return

	if Globals.quest_state == "paymentPending":
		_dialogue_state = "mirellePaymentChoice"
		_dialogue_box.show_line("Mirelle",
			"Caelan! Did Padrig have the payment ready?",
			["Here are your 5 gold, Mirelle.", "I'm afraid he couldn't pay today."],
			_mirelle_portrait)
		return

	if Globals.quest_state == "accepted":
		_dialogue_state = "mirelleReminder"
		_dialogue_box.show_line("Mirelle",
			"You still have the onions — Padrig is waiting at the tavern in Millhaven. He pays 5 gold on delivery.",
			["I'll bring them soon."], _mirelle_portrait)
		return

	if Globals.quest_state == "onionsEaten":
		_dialogue_state = "mirelleReminder"
		_dialogue_box.show_line("Mirelle",
			"...Did you eat the onions? I had a bad feeling about those.",
			["Sorry, Mirelle."], _mirelle_portrait)
		return

	# Default: rep-scaled quest offer
	var greet_lines := {
		2: "Caelan. I'm not entirely sure where we stand right now, but I still have work to be done. I have a bundle of onions for Padrig at the tavern in Millhaven — he pays 5 gold on delivery. Will you take them?",
		3: "Caelan. I could use your help. Padrig at the Millhaven tavern is expecting a bundle of onions — he pays 5 gold. Would you take them over?",
		4: "Caelan, just who I needed. I have a fresh bundle of onions ready for Padrig the chef at the tavern in Millhaven. He pays 5 gold on delivery. Would you bring them over?",
		5: "Caelan, good timing! I have onions ready for Padrig in Millhaven — 5 gold on delivery. Could you run them over?",
		6: "You're a good man, Caelan. I have a bundle of onions for Padrig at the Millhaven tavern — he always pays well, 5 gold. Would you mind bringing them?",
		7: "Caelan! No one I'd rather trust with this. Padrig at the Millhaven tavern is expecting a bundle of onions — 5 gold on delivery. Will you take them?",
	}
	_dialogue_state = "mirelleOffer"
	_dialogue_box.show_line("Mirelle", greet_lines.get(rep, greet_lines[4]),
		["Sure, I'll bring them.", "Not just now, Mirelle."], _mirelle_portrait)

# ── Aldric dialogue ───────────────────────────────────────────────────────────

func _open_aldric_dialogue() -> void:
	if not _aldric: return
	var rep := Globals.player_reputation
	var portrait := DialogueBox.make_portrait_frames("res://assets/npcs/hut_wanderer/idle.png", 5)
	_open_dialogue_direct("aldric", _aldric)
	var lines := {
		1: "I know what people are saying about you. Best keep moving.",
		2: "Something about you doesn't sit right. I'd rather be left alone.",
		3: "Morning. Not really in the mood for conversation.",
		4: "Just keeping an eye on the road. Quiet so far — suits me fine.",
		5: "Good day! All quiet on this stretch. Glad to see a friendly face.",
		6: "Always good to see you around here. The woods feel safer when you're about.",
		7: "Hah! They ought to name this road after you, Caelan.",
	}
	var choices := ["..."] if rep <= 2 else ["Good to see you too."]
	_dialogue_state = "aldricGreet"
	_dialogue_box.show_line("Aldric", lines.get(rep, lines[4]), choices, portrait)

# ── Lena dialogue ─────────────────────────────────────────────────────────────

func _open_lena_dialogue() -> void:
	if not _lena: return
	var rep := Globals.player_reputation
	var portrait := DialogueBox.make_portrait_frames("res://assets/npcs/farm_worker/idle.png", 5)
	_open_dialogue_direct("lena", _lena)
	var lines := {
		1: "Stay away from me. I don't want any trouble.",
		2: "I don't know you. Don't bother me while I'm working.",
		3: "Just here tending the crops. Don't mind me.",
		4: "The harvest is looking decent this season. Keep an eye out for rabbits though — they've been getting into the patch.",
		5: "Good to see you around! These onions need watching. The rabbits have been relentless lately.",
		6: "What a nice day for the fields! Mirelle says the onions are coming in beautifully.",
		7: "Caelan! Always glad when you're around. Mirelle says the same. The whole farm feels safer with you here.",
	}
	var choices := ["..."] if rep <= 2 else ["I'll keep an eye out."]
	_dialogue_state = "lenaGreet"
	_dialogue_box.show_line("Lena", lines.get(rep, lines[4]), choices, portrait)

# ── Choice & dismissal handlers ───────────────────────────────────────────────

func _on_dialogue_choice(idx: int) -> void:
	match _dialogue_state:
		"mirelleOffer":
			if idx == 0:  # "Sure, I'll bring them."
				Globals.quest_state = "accepted"
				Globals.add_item({"name": "Onions", "texture": "", "actions": ["Eat"]})
				show_item_popup("Onions")
				_dialogue_state = "mirelleQuestAccepted"
				_dialogue_box.show_line("Mirelle",
					"Thank you, Caelan. Padrig is at the tavern in Millhaven — he will know they are mine. Make sure he pays the full 5 gold.",
					["I'll head there now."], _mirelle_portrait)
			else:  # "Not just now, Mirelle."
				Globals.quest_state = "declined"
				_dialogue_state = "mirelleQuestDeclined"
				_dialogue_box.show_line("Mirelle",
					"All right. Come find me when you have a moment — the onions won't keep forever.",
					["Will do."], _mirelle_portrait)

		"mirellePaymentChoice":
			if idx == 0:  # "Here are your 5 gold, Mirelle."
				if Globals.spend_gold(5):
					Globals.change_reputation(0.5)
					Globals.story_flags["mirelle_quest_complete"] = true
					Globals.story_flags["gold_given_to_mirelle"]  = true
					Globals.quest_state = "complete"
					_dialogue_state     = "mirelleGoldGiven"
					_dialogue_box.show_line("Mirelle",
						"Every coin — thank you, Caelan. Honest as ever. I am glad to have you looking after this place.",
						["Glad to help, Mirelle."], _mirelle_portrait)
				else:
					_dialogue_state = "mirelleNoGold"
					_dialogue_box.show_line("Mirelle",
						"It sounds like the road may have parted you from it. Come back when you have it sorted.",
						["I will."], _mirelle_portrait)
			else:  # "I'm afraid he couldn't pay today." (lie)
				Globals.change_reputation(-0.5)
				Globals.story_flags["mirelle_quest_complete"] = true
				Globals.story_flags["gold_given_to_mirelle"]  = false
				Globals.quest_state = "complete"
				_dialogue_state     = "mirelleLied"
				_dialogue_box.show_line("Mirelle",
					"...I see. Well. I'll manage without it. Thank you for making the trip at least.",
					["..."], _mirelle_portrait)

		_:
			# All terminal states (mirelleHostile, mirelleAfterQuest, mirelleReminder,
			# mirelleQuestAccepted, mirelleQuestDeclined, mirelleGoldGiven,
			# mirelleNoGold, mirelleLied, aldricGreet, lenaGreet)
			_dialogue_box.close()

func _on_dialogue_dismissed() -> void:
	var npc := _npc_for_id(_active_npc)
	if npc: npc.resume_patrol()
	_dialogue_open  = false
	_active_npc     = ""
	_dialogue_state = ""
	_dialogue_seq   = []
	if _player: _player.set_physics_process(true)

# ══════════════════════════════════════════════════════════════════════════════
# Menu
# ══════════════════════════════════════════════════════════════════════════════

func _open_menu() -> void:
	_menu_open = true
	_player.set_physics_process(false)
	_menu_panel.open()

func _on_menu_closed() -> void:
	_menu_open = false
	if _player: _player.set_physics_process(true)

# ══════════════════════════════════════════════════════════════════════════════
# Scene transitions
# ══════════════════════════════════════════════════════════════════════════════

func _enter_hut() -> void:
	if _transitioning: return
	_transitioning = true
	_door_sfx.play()
	Globals.from_transition = true
	Globals.spawn_x = HUT_DOOR_X
	_transition_to("HutInterior")

func _check_scene_boundaries() -> void:
	if _transitioning or not _player: return
	if _player.position.x > WORLD_WIDTH - 120 and _player.velocity.x > 0:
		Globals.from_transition = true
		Globals.spawn_x = 180.0
		_transition_to("City")

func _transition_to(scene_name: String) -> void:
	if _transitioning and scene_name != "HutInterior": return
	_transitioning = true
	_player.set_physics_process(false)
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.22)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.22)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + scene_name + ".tscn"))
