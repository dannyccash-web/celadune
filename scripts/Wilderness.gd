extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Wilderness scene — east of Millhaven (City)
# World 5184 × 1080  |  Flat terrain (green tiles)  |  6 slimes
# Player enters from City right edge (spawn_x=120), exits left back to City.
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 5184
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const TILE_PX      := 96

# Green tileset (frames from floor_tiles2.png)
const T_TOP_C := 1; const T_FILL := 10

const SLIME_GROUND_Y  := 838.0
const PLAYER_ATTACK_R := 160.0

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

# ── Nodes ─────────────────────────────────────────────────────────────────────
var _player:      CharacterBody2D
var _camera:      Camera2D
var _parallax_bg: ParallaxBackground
var _sky_layer:   ParallaxLayer
var _sky_drift:   float = 0.0

var _slimes:            Array = []
var _player_invincible: float = 0.0

var _music:      AudioStreamPlayer
var _jump_sfx:   AudioStreamPlayer
var _attack_sfx: AudioStreamPlayer
var _hurt_sfx:   AudioStreamPlayer

var _hp_bar_fg: ColorRect
var _hp_label:  Label
var _hud_layer: CanvasLayer

var _menu_panel:    Node
var _menu_open:     bool = false
var _transitioning: bool = false

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_sky_bg()    # solid background fallback in case parallax is slow to render
	_build_parallax()
	_build_ground()
	_spawn_player()
	_spawn_slimes()
	_build_camera()
	_build_audio()
	_build_hud()
	_build_menu()
	_fade_in()

# ── Solid sky background (prevents gray canvas if parallax is slow) ───────────

func _build_sky_bg() -> void:
	var sky := ColorRect.new()
	sky.color    = Color(0.35, 0.52, 0.74)   # mid-blue sky
	sky.size     = Vector2(GAME_W, GROUND_Y)
	sky.position = Vector2.ZERO
	sky.z_index  = -5
	add_child(sky)

# ── Parallax ──────────────────────────────────────────────────────────────────

func _build_parallax() -> void:
	_parallax_bg = ParallaxBackground.new()
	add_child(_parallax_bg)
	for i in range(BG_LAYERS.size()):
		var cfg: Dictionary = BG_LAYERS[i]
		var tex: Texture2D = load(cfg["path"])
		if not tex: continue
		var s := float(GAME_H) / float(tex.get_height())
		var layer := ParallaxLayer.new()
		layer.motion_scale     = Vector2(cfg["factor"], 0.0)
		layer.motion_mirroring = Vector2(ceil(tex.get_width() * s) + 2.0, 0.0)
		_parallax_bg.add_child(layer)
		var sp := Sprite2D.new()
		sp.texture = tex; sp.centered = false
		sp.scale   = Vector2(s, s); sp.position = Vector2(0, cfg["y_off"])
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(sp)
		if i == 0: _sky_layer = layer

# ── Ground (flat — same physics approach as Forest/City) ──────────────────────

func _build_ground() -> void:
	# Single flat physics body
	var body  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size      = Vector2(WORLD_WIDTH * 2.0, 400.0)
	shape.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 200.0)
	shape.shape    = rect
	body.add_child(shape)
	add_child(body)

	# Visual tiles
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := WORLD_WIDTH / TILE_PX
	for col in range(cols):
		var cx := col * TILE_PX + TILE_PX / 2
		_tile(tile_tex, cx, GROUND_Y + TILE_PX / 2, T_TOP_C, 12)
		var fill_rows := int(ceil(float(GAME_H - GROUND_Y) / TILE_PX)) + 1
		for row in range(1, fill_rows + 1):
			_tile(tile_tex, cx, GROUND_Y + TILE_PX * row + TILE_PX / 2, T_FILL, 2)
		var bg := ColorRect.new()
		bg.color    = Color(0.102, 0.071, 0.031)
		bg.size     = Vector2(TILE_PX, GAME_H + 200.0 - GROUND_Y)
		bg.position = Vector2(cx - TILE_PX / 2, GROUND_Y)
		bg.z_index  = 1; add_child(bg)

func _tile(tex: Texture2D, cx: float, cy: float, frame: int, z: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas  = tex
	atlas.region = Rect2((frame % 9) * TILE_PX, (frame / 9) * TILE_PX, TILE_PX, TILE_PX)
	var sp := Sprite2D.new(); sp.texture = atlas; sp.centered = true
	sp.position = Vector2(cx, cy); sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = z; add_child(sp)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(Globals.spawn_x, 835.0)
	_player.jumped.connect(_on_player_jumped)
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)

# ── Slimes ────────────────────────────────────────────────────────────────────

func _spawn_slimes() -> void:
	var slime_script: GDScript = load("res://scripts/Slime.gd")
	var sheets := [
		"res://assets/enemies/slime_blue.png",
		"res://assets/enemies/slime_green.png",
		"res://assets/enemies/slime_red.png",
	]
	var spawn_xs := [800.0, 1400.0, 2100.0, 2800.0, 3500.0, 4200.0]
	for i in range(spawn_xs.size()):
		var sx := spawn_xs[i]
		var slime = slime_script.new()
		slime.slime_sheet  = sheets[i % sheets.size()]
		slime.ground_y     = SLIME_GROUND_Y
		slime.patrol_min_x = max(100.0, sx - 500.0)
		slime.patrol_max_x = min(float(WORLD_WIDTH - 100), sx + 500.0)
		slime.position     = Vector2(sx, SLIME_GROUND_Y)
		slime.hit_player.connect(_on_slime_hit_player)
		add_child(slime)
		_slimes.append(slime)

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
	_music      = _audio("res://assets/audio/celadune_theme.mp3",                               0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                    0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",       0.55, false)
	_hurt_sfx   = _audio("res://assets/sfx/freesound_community-male_hurt7-48124.mp3",          0.6,  false)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.28), 0.32)

func _audio(path: String, vol: float, loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
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
	_check_attack_hits()

func _check_attack_hits() -> void:
	if not _player: return
	for slime in _slimes:
		if not is_instance_valid(slime): continue
		if _player.position.distance_to(slime.position) < PLAYER_ATTACK_R:
			slime.take_hit()
	_slimes = _slimes.filter(func(s): return is_instance_valid(s))

func _on_slime_hit_player() -> void:
	if _player_invincible > 0.0: return
	_player_invincible = 1.0
	Globals.player_health = maxi(0, Globals.player_health - 1)
	_hurt_sfx.play()
	_refresh_hud()
	var spr: AnimatedSprite2D = _player.get_node_or_null("Sprite")
	if spr:
		var tw := create_tween()
		tw.tween_property(spr, "modulate", Color(2, 0.3, 0.3, 1), 0.08)
		tw.tween_property(spr, "modulate", Color(1, 1, 1, 1), 0.18)

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

func _refresh_hud() -> void:
	var pct := float(Globals.player_health) / float(Globals.player_max_health)
	_hp_bar_fg.size.x = 176.0 * pct
	_hp_label.text    = "%d / %d" % [Globals.player_health, Globals.player_max_health]

# ── Menu ──────────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var mp_script: GDScript = load("res://scripts/MenuPanel.gd")
	_menu_panel = mp_script.new()
	add_child(_menu_panel)
	_menu_panel.closed.connect(_on_menu_closed)

func _open_menu() -> void:
	_menu_open = true
	_player.set_physics_process(false)
	_menu_panel.open()

func _on_menu_closed() -> void:
	_menu_open = false
	if _player: _player.set_physics_process(true)

# ── Fade-in ───────────────────────────────────────────────────────────────────

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.5)
	tw.tween_callback(ov.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# Per-frame
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _player: return

	_sky_drift -= 12.0 * delta
	if _sky_layer: _sky_layer.motion_offset = Vector2(_sky_drift, 0.0)

	if _player_invincible > 0.0:
		_player_invincible -= delta

	if _menu_open: return

	if Input.is_action_just_pressed("menu_toggle"):
		_open_menu(); return

	_check_boundaries()

func _check_boundaries() -> void:
	if _transitioning or not _player: return
	# Left edge → back to City
	if _player.position.x < 80 and _player.velocity.x < 0:
		Globals.from_transition = true
		Globals.spawn_x = 4728.0   # CITY_WORLD_WIDTH (4800) - 72
		_transition_to("City")

func _transition_to(scene_name: String) -> void:
	if _transitioning: return
	_transitioning = true
	_player.set_physics_process(false)
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.22)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.22)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + scene_name + ".tscn"))
