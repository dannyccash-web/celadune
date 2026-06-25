extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Wilderness scene — enemy test area east of Millhaven
# Matches Phaser's WildernessScene exactly:
#   - Variable heightmap terrain (sinusoidal, max 1-tile steps, smoothed 6 passes)
#   - 6 slimes at x=[800,1400,2100,2800,3500,4200], cycling blue/green/red
#   - Slime AI: idle patrol → chase within 350px → jump-attack within 180px
#   - Player damage: 1 HP, 1s i-frames, knockback, blink, screen shake
#   - Player death → respawn at startX after 1.2s
#   - No NPCs, no dog, no quest system
#   - Left edge → City, no right transition
#   - Music: forest theme at volume 0.35
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 5184
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const TILE_PX      := 96

const T_TOP_L := 0; const T_TOP_C := 1; const T_TOP_R := 2
const T_FILL  := 10; const T_LEFT_FILL := 9; const T_RIGHT_FILL := 11

const SLIME_SCALE      := 3.0
const SLIME_FRAME_W    := 32
const SLIME_FRAME_H    := 32
const SLIME_WALK_SPEED := 55.0
const SLIME_CHASE_SPD  := 80.0
const SLIME_JUMP_VX    := 220.0
const SLIME_JUMP_VY    := -520.0
const SLIME_CHASE_DIST := 350.0
const SLIME_JUMP_DIST  := 180.0
const SLIME_HIT_RADIUS := 54.0   # 18 world-px × SCALE=3
const SLIME_HIT_CD     := 1.2
const PLAYER_ATTACK_R  := 160.0

const PLAYER_IFRAMES   := 1.0    # seconds after being hit
const PLAYER_RESPAWN_T := 1.2

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

# Slime configs: [sheet_path, spawn_x, patrol_half]
const SLIME_CONFIGS := [
	["res://assets/enemies/slime_blue.png",   800.0,  500.0],
	["res://assets/enemies/slime_green.png", 1400.0,  500.0],
	["res://assets/enemies/slime_red.png",   2100.0,  500.0],
	["res://assets/enemies/slime_blue.png",  2800.0,  500.0],
	["res://assets/enemies/slime_green.png", 3500.0,  500.0],
	["res://assets/enemies/slime_red.png",   4200.0,  500.0],
]

# ── State ─────────────────────────────────────────────────────────────────────
var _player:        CharacterBody2D
var _camera:        Camera2D
var _parallax_bg:   ParallaxBackground
var _sky_layer:     ParallaxLayer
var _sky_drift:     float = 0.0

var _music:       AudioStreamPlayer
var _jump_sfx:    AudioStreamPlayer
var _attack_sfx:  AudioStreamPlayer
var _hurt_sfx:    AudioStreamPlayer

var _hp_bar_fg:   ColorRect
var _hp_label:    Label
var _hud_layer:   CanvasLayer

var _menu_panel:  Node
var _menu_open:   bool = false

var _slimes:      Array = []
var _terrain:     Array = []   # heightmap: tile col → step count (0 or 1)

var _player_invincible: float = 0.0
var _player_dead:       bool  = false
var _respawn_timer:     float = 0.0
var _start_x:           float = 120.0
var _transitioning:     bool  = false

# ── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_compute_terrain()
	_build_parallax()
	_build_ground_physics()
	_build_ground_tiles()
	_spawn_player()
	_spawn_slimes()
	_build_camera()
	_build_audio()
	_build_hud()
	_build_menu()
	_fade_in()

# ── Terrain heightmap ──────────────────────────────────────────────────────────
# Mirrors Phaser WildernessScene.computeTerrainHeightmap() exactly:
# raw[i] = round(sin(x*0.0013)*2 + sin(x*0.0022)*1 + sin(x*0.0041)*0.5 + 0.5)
# clamped to [0,1], then smoothed 6 passes so max step = 1, first/last 3 cols flat.

func _compute_terrain() -> void:
	var cols := int(ceil(float(WORLD_WIDTH) / TILE_PX)) + 4
	_terrain.resize(cols)
	for i in range(cols):
		var x := float(i * TILE_PX)
		var v := sin(x * 0.0013) * 2.0 + sin(x * 0.0022) * 1.0 + sin(x * 0.0041) * 0.5
		_terrain[i] = int(clampf(roundf(v + 0.5), 0.0, 1.0))
	# 6 smoothing passes
	for _pass in range(6):
		for i in range(1, cols):
			if _terrain[i] > _terrain[i-1] + 1:
				_terrain[i] = _terrain[i-1] + 1
		for i in range(cols - 2, -1, -1):
			if _terrain[i] > _terrain[i+1] + 1:
				_terrain[i] = _terrain[i+1] + 1
	# Flat edges
	for i in range(3):
		_terrain[i] = 0
	for i in range(cols - 3, cols):
		_terrain[i] = 0

func _surface_y(tile_col: int) -> float:
	var h := _terrain[clampi(tile_col, 0, _terrain.size() - 1)]
	return GROUND_Y - h * TILE_PX

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
		layer.motion_mirroring = Vector2(tex.get_width() * s, 0.0)
		_parallax_bg.add_child(layer)
		var sp := Sprite2D.new()
		sp.texture = tex; sp.centered = false
		sp.scale   = Vector2(s, s); sp.position = Vector2(0, cfg["y_off"])
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(sp)
		if i == 0: _sky_layer = layer

# ── Ground physics ────────────────────────────────────────────────────────────

func _build_ground_physics() -> void:
	var cols := int(ceil(float(WORLD_WIDTH) / TILE_PX))
	for col in range(cols):
		var cx := float(col * TILE_PX + TILE_PX / 2)
		var sy := _surface_y(col)
		# Surface collider
		var body := StaticBody2D.new()
		var cshape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE_PX, 48.0)
		cshape.position = Vector2(cx, sy + 2.0 + 24.0)
		cshape.shape = rect
		body.add_child(cshape)
		add_child(body)
		# Cliff wall colliders at step boundaries
		if col > 0:
			var prev_y := _surface_y(col - 1)
			if prev_y > sy:
				var wall_h := (prev_y - sy) + 48.0
				var wb := StaticBody2D.new()
				var ws := CollisionShape2D.new()
				var wr := RectangleShape2D.new()
				wr.size = Vector2(8.0, wall_h)
				ws.position = Vector2(float(col * TILE_PX), sy + wall_h / 2.0)
				ws.shape = wr
				wb.add_child(ws)
				add_child(wb)
		if col < cols - 1:
			var next_y := _surface_y(col + 1)
			if next_y > sy:
				var wall_h := (next_y - sy) + 48.0
				var wb := StaticBody2D.new()
				var ws := CollisionShape2D.new()
				var wr := RectangleShape2D.new()
				wr.size = Vector2(8.0, wall_h)
				ws.position = Vector2(float((col + 1) * TILE_PX), sy + wall_h / 2.0)
				ws.shape = wr
				wb.add_child(ws)
				add_child(wb)

# ── Ground tiles ──────────────────────────────────────────────────────────────

func _build_ground_tiles() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := int(ceil(float(WORLD_WIDTH) / TILE_PX))
	for col in range(cols):
		var cx := float(col * TILE_PX + TILE_PX / 2)
		var sy := _surface_y(col)
		var prev_y := _surface_y(max(0, col - 1))
		var next_y := _surface_y(min(cols - 1, col + 1))
		# Top tile frame
		var top_frame := T_TOP_C
		if prev_y > sy and next_y >= sy:  top_frame = T_TOP_L
		elif next_y > sy and prev_y >= sy: top_frame = T_TOP_R
		_tile(tile_tex, cx, sy + TILE_PX / 2, top_frame, 12)
		# Fill rows
		var fill_rows := int(ceil(float(GAME_H - sy) / TILE_PX)) + 1
		var left_cliff  := int(max(0, round((prev_y - sy) / TILE_PX)))
		var right_cliff := int(max(0, round((next_y - sy) / TILE_PX)))
		for row in range(1, fill_rows + 1):
			var ff := T_FILL
			if left_cliff > 0 and row <= left_cliff:    ff = T_LEFT_FILL
			elif right_cliff > 0 and row <= right_cliff: ff = T_RIGHT_FILL
			_tile(tile_tex, cx, sy + TILE_PX * row + TILE_PX / 2, ff, 2)
		# Dark fill bg
		var bg := ColorRect.new()
		bg.color    = Color(0.102, 0.071, 0.031)
		bg.size     = Vector2(TILE_PX, GAME_H + 200 - sy)
		bg.position = Vector2(cx - TILE_PX / 2, sy)
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
	_start_x = Globals.spawn_x if Globals.from_transition else 120.0
	Globals.from_transition = false
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(_start_x, 835.0)
	_player.jumped.connect(_on_player_jumped)
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)

# ── Slimes ────────────────────────────────────────────────────────────────────

func _spawn_slimes() -> void:
	for cfg in SLIME_CONFIGS:
		var sheet: String = cfg[0]
		var sx: float     = cfg[1]
		var half: float   = cfg[2]
		var col_idx := int(sx / TILE_PX)
		var ground := _surface_y(col_idx) - SLIME_FRAME_H * SLIME_SCALE * 0.5
		var slime  := _make_slime(sheet, sx, ground, sx - half, sx + half)
		add_child(slime)
		_slimes.append(slime)

func _make_slime(sheet: String, x: float, y: float, min_x: float, max_x: float) -> Node2D:
	var node := Node2D.new()
	node.position = Vector2(x, y)
	node.z_index  = 8
	node.set_meta("min_x", min_x)
	node.set_meta("max_x", max_x)
	node.set_meta("hp", 2)
	node.set_meta("max_hp", 2)
	node.set_meta("state", "idle")   # idle | chasing | jumping | dying
	node.set_meta("dir", 1)
	node.set_meta("patrol_timer", 0.0)
	node.set_meta("jump_cd", 0.0)
	node.set_meta("hit_cd", 0.0)

	# Sprite
	var tex: Texture2D = load(sheet)
	var sp := AnimatedSprite2D.new()
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale = Vector2(SLIME_SCALE, SLIME_SCALE)
	sp.flip_h = true

	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	# idle (frames 0-4), jump (frames 8-15), death (frames 16-20)
	_slime_anim(sf, tex, "idle",  0, 5, 6.0, true)
	_slime_anim(sf, tex, "jump",  8, 8, 10.0, false)
	_slime_anim(sf, tex, "death",16, 5, 8.0, false)
	sp.sprite_frames = sf
	sp.play("idle")
	node.add_child(sp)
	node.set_meta("sprite", sp)

	# HP bar bg
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.2, 0.2, 0.2)
	bar_bg.size     = Vector2(30, 4)
	bar_bg.position = Vector2(-15, -SLIME_FRAME_H * SLIME_SCALE - 8)
	node.add_child(bar_bg)
	node.set_meta("bar_bg", bar_bg)

	# HP bar fg (colour by sheet)
	var bar_col := Color(0.267, 0.667, 1.0)
	if "green" in sheet: bar_col = Color(0.267, 0.933, 0.4)
	elif "red"   in sheet: bar_col = Color(1.0, 0.333, 0.2)
	var bar_fg := ColorRect.new()
	bar_fg.color    = bar_col
	bar_fg.size     = Vector2(30, 4)
	bar_fg.position = Vector2(-15, -SLIME_FRAME_H * SLIME_SCALE - 8)
	node.add_child(bar_fg)
	node.set_meta("bar_fg", bar_fg)

	return node

func _slime_anim(sf: SpriteFrames, tex: Texture2D, name: String, start: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(name)
	sf.set_animation_loop(name, loop)
	sf.set_animation_speed(name, fps)
	for i in range(count):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2((start + i) * SLIME_FRAME_W, 0, SLIME_FRAME_W, SLIME_FRAME_H)
		sf.add_frame(name, a)

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
	_music      = _audio("res://assets/audio/celadune_forest.mp3",                               0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                      0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",         0.55, false)
	_hurt_sfx   = _audio("res://assets/sfx/freesound_community-male_hurt7-48124.mp3",            0.6,  false)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.35), 0.32)

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
	_check_attack_hits()

func _check_attack_hits() -> void:
	if not _player: return
	for slime in _slimes:
		if not is_instance_valid(slime): continue
		if slime.get_meta("state") == "dying": continue
		if _player.position.distance_to(slime.position) < PLAYER_ATTACK_R:
			_slime_take_hit(slime)
	_slimes = _slimes.filter(func(s): return is_instance_valid(s))

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
	_hp_label.text = "%d / %d" % [Globals.player_health, Globals.player_max_health]
	_hp_label.position = Vector2(212, GAME_H - 46)
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

	# Sky drift
	_sky_drift -= 0.1
	if _sky_layer: _parallax_bg.scroll_offset = Vector2(_sky_drift, 0.0)

	if _player_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_do_respawn()
		return

	if _player_invincible > 0.0:
		_player_invincible -= delta

	if _menu_open: return

	_update_slimes(delta)

	if Input.is_action_just_pressed("menu_toggle"):
		_open_menu(); return

	_check_boundaries()
	_check_slime_contact()

func _check_slime_contact() -> void:
	if _player_invincible > 0.0 or _player_dead: return
	for slime in _slimes:
		if not is_instance_valid(slime): continue
		if slime.get_meta("state") == "dying": continue
		if _player.position.distance_to(slime.position) < SLIME_HIT_RADIUS:
			_player_take_hit(slime)
			break

func _player_take_hit(slime: Node2D) -> void:
	_player_invincible = PLAYER_IFRAMES
	Globals.player_health = maxi(0, Globals.player_health - 1)
	_hurt_sfx.play()
	_refresh_hud()

	# Knockback away from slime with upward pop
	var kb_dir := 1.0 if _player.position.x >= slime.position.x else -1.0
	_player.velocity.x = kb_dir * 300.0
	_player.velocity.y = -240.0

	# Red flash on player sprite
	var spr: AnimatedSprite2D = _player.get_node_or_null("Sprite")
	if spr:
		var tw := create_tween()
		tw.tween_property(spr, "modulate", Color(2, 0.3, 0.3, 1), 0.08)
		tw.tween_property(spr, "modulate", Color(1, 1, 1, 1), 0.18)

	# I-frame blink
	var blink_tw := create_tween()
	blink_tw.tween_property(_player, "modulate:a", 0.15, 0.09)
	blink_tw.tween_property(_player, "modulate:a", 1.0,  0.09)
	blink_tw.set_loops(5)

	# Screen shake
	if _camera:
		_camera.position_smoothing_enabled = false
		var shake_tw := create_tween()
		for i in range(6):
			shake_tw.tween_callback(func():
				_camera.offset = Vector2(randf_range(-6, 6), randf_range(-4, 4)))
			shake_tw.tween_interval(0.033)
		shake_tw.tween_callback(func():
			_camera.offset = Vector2.ZERO
			_camera.position_smoothing_enabled = true)

	if Globals.player_health <= 0:
		_on_player_death()

func _on_player_death() -> void:
	_player_dead = true
	_player_invincible = 0.0
	_player.modulate    = Color(1, 0.27, 0.27, 1)
	_player.velocity    = Vector2.ZERO
	_player.set_physics_process(false)
	_respawn_timer = PLAYER_RESPAWN_T

func _do_respawn() -> void:
	_player_dead = false
	Globals.player_health = Globals.player_max_health
	_refresh_hud()
	_player.modulate = Color(1, 1, 1, 1)
	_player.position = Vector2(_start_x, 835.0)
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(true)
	_player_invincible = 0.5

# ── Slime AI ──────────────────────────────────────────────────────────────────

func _update_slimes(delta: float) -> void:
	for slime in _slimes:
		if not is_instance_valid(slime): continue
		_update_slime(slime, delta)

func _update_slime(slime: Node2D, delta: float) -> void:
	var state:    String = slime.get_meta("state")
	var sp:       AnimatedSprite2D = slime.get_meta("sprite")
	var min_x:    float = slime.get_meta("min_x")
	var max_x:    float = slime.get_meta("max_x")
	var jump_cd:  float = slime.get_meta("jump_cd")
	var hit_cd:   float = slime.get_meta("hit_cd")

	# Cool down timers
	if jump_cd > 0.0: slime.set_meta("jump_cd", jump_cd - delta)
	if hit_cd  > 0.0: slime.set_meta("hit_cd",  hit_cd  - delta)

	if state == "dying": return

	var px := _player.position.x
	var py := _player.position.y
	var dist := slime.position.distance_to(Vector2(px, py))

	# Update HP bar position to follow slime
	var bar_bg: ColorRect = slime.get_meta("bar_bg")
	var bar_fg: ColorRect = slime.get_meta("bar_fg")
	bar_bg.global_position = slime.position + Vector2(-15, -SLIME_FRAME_H * SLIME_SCALE - 8)
	bar_fg.global_position = bar_bg.global_position

	if state == "jumping":
		# Simulate gravity manually (slime is a plain Node2D, not CharacterBody)
		var vx: float = slime.get_meta("vel_x")
		var vy: float = slime.get_meta("vel_y")
		vy += 1800.0 * delta
		slime.position.x += vx * delta
		slime.position.y += vy * delta
		slime.set_meta("vel_y", vy)
		# Land when at or below terrain
		var col := int(slime.position.x / TILE_PX)
		var surf := _surface_y(col) - SLIME_FRAME_H * SLIME_SCALE * 0.5
		if slime.position.y >= surf and vy > 0:
			slime.position.y = surf
			slime.set_meta("state", "idle")
			slime.set_meta("jump_cd", randf_range(1.2, 2.5))
			sp.play("idle")
		return

	if dist < SLIME_CHASE_DIST:
		# Chase player
		slime.set_meta("state", "chasing")
		var dir_x := 1 if px > slime.position.x else -1
		slime.set_meta("dir", dir_x)
		sp.flip_h = dir_x > 0
		slime.position.x += dir_x * SLIME_CHASE_SPD * delta
		# Clamp to patrol range
		slime.position.x = clampf(slime.position.x, min_x, max_x)
		# Snap to terrain
		var col := int(slime.position.x / TILE_PX)
		slime.position.y = _surface_y(col) - SLIME_FRAME_H * SLIME_SCALE * 0.5

		# Jump if close enough and cooldown ready
		var jcd: float = slime.get_meta("jump_cd")
		if dist < SLIME_JUMP_DIST and jcd <= 0.0:
			slime.set_meta("state", "jumping")
			slime.set_meta("jump_cd", 2.0)
			var jvx := float(dir_x) * SLIME_JUMP_VX
			slime.set_meta("vel_x", jvx)
			slime.set_meta("vel_y", SLIME_JUMP_VY)
			sp.play("jump")
		elif sp.animation != "idle":
			sp.play("idle")
	else:
		# Idle patrol
		slime.set_meta("state", "idle")
		var patrol_t: float = slime.get_meta("patrol_timer")
		patrol_t -= delta
		if patrol_t <= 0.0:
			var old_dir: int = slime.get_meta("dir")
			slime.set_meta("dir", -old_dir)
			slime.set_meta("patrol_timer", randf_range(1.5, 4.0))
		else:
			slime.set_meta("patrol_timer", patrol_t)
		var pd: int = slime.get_meta("dir")
		if slime.position.x <= min_x: slime.set_meta("dir", 1);  pd = 1
		if slime.position.x >= max_x: slime.set_meta("dir", -1); pd = -1
		sp.flip_h = pd > 0
		slime.position.x += float(pd) * SLIME_WALK_SPEED * delta
		slime.position.x = clampf(slime.position.x, min_x, max_x)
		var col := int(slime.position.x / TILE_PX)
		slime.position.y = _surface_y(col) - SLIME_FRAME_H * SLIME_SCALE * 0.5
		if sp.animation != "idle": sp.play("idle")

func _slime_take_hit(slime: Node2D) -> void:
	var hit_cd: float = slime.get_meta("hit_cd")
	if hit_cd > 0.0: return
	slime.set_meta("hit_cd", 0.4)

	var hp: int = slime.get_meta("hp") - 1
	slime.set_meta("hp", hp)

	# White flash
	var sp: AnimatedSprite2D = slime.get_meta("sprite")
	var tw := create_tween()
	tw.tween_property(sp, "modulate", Color(2, 2, 2, 1), 0.06)
	tw.tween_property(sp, "modulate", Color(1, 1, 1, 1), 0.10)

	# Update HP bar
	var max_hp: int = slime.get_meta("max_hp")
	var bar_fg: ColorRect = slime.get_meta("bar_fg")
	bar_fg.size.x = 30.0 * (float(max(0, hp)) / float(max_hp))

	# Knockback away from player
	var dir_x := 1.0 if slime.position.x >= _player.position.x else -1.0
	if slime.get_meta("state") != "jumping":
		slime.set_meta("vel_x", dir_x * 280.0)
		slime.set_meta("vel_y", -200.0)
		slime.set_meta("state", "jumping")
		slime.set_meta("jump_cd", 0.6)
		sp.play("jump")

	if hp <= 0:
		_kill_slime(slime)

func _kill_slime(slime: Node2D) -> void:
	slime.set_meta("state", "dying")
	var bar_bg: Node = slime.get_meta("bar_bg")
	var bar_fg: Node = slime.get_meta("bar_fg")
	bar_bg.queue_free()
	bar_fg.queue_free()
	var sp: AnimatedSprite2D = slime.get_meta("sprite")
	sp.play("death")
	sp.animation_finished.connect(func(): slime.queue_free(), CONNECT_ONE_SHOT)

# ── Scene boundaries ──────────────────────────────────────────────────────────

func _check_boundaries() -> void:
	if _transitioning or not _player: return
	if _player.position.x < 80 and _player.velocity.x < 0:
		Globals.from_transition = true
		Globals.spawn_x = 4680.0   # right side of City
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
