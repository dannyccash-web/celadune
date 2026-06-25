extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# City scene
# World 4800 × 1080  |  GROUND_Y = 888  |  GREEN tile set
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 4800
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const PROP_BASE    := 915   # building base anchor (BLACK_TILE_GROUND_Y 927 - 12)
const TILE_PX      := 96

# Green tileset (same as forest)
const T_TOP_L := 0; const T_TOP_C := 1; const T_TOP_R := 2; const T_FILL := 10

const NPC_GROUND_Y  := 798.0
const NPC_TALK_R    := 150.0
const SLIME_GROUND_Y := 838.0
const PLAYER_ATTACK_R := 180.0  # world-px reach of player attack

# Dog
const DOG_SCALE    := 3.1
const DOG_FRAME_SZ := 32
const DOG_WALK_ROW := 0
const DOG_FIRST_FR := 6
const DOG_LAST_FR  := 11
const DOG_GROUND_Y := 838.0
const DOG_MIN_X    := 400.0
const DOG_MAX_X    := 4400.0
const DOG_SPEED    := 58.0
const DOG_FLEE_SPD := 240.0

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

# Building placements [asset_path, center_x]
const BUILDINGS := [
	["res://assets/buildings/city_archway/building.png",     380],
	["res://assets/buildings/city_blacksmith/building.png",  960],
	["res://assets/buildings/city_tavern/building.png",     1540],
	["res://assets/buildings/city_house_1/building.png",    2120],
	["res://assets/buildings/city_house_3/building.png",    2700],
	["res://assets/buildings/city_magic_shop/building.png", 3280],
	["res://assets/buildings/city_house_2/building.png",    3860],
]

# Door interaction zones: [building_x, door_center_x, label, interior_config_id]
const DOOR_ZONES := [
	[960,  909,  "Blacksmith",  "bram_smithy"],
	[1540, 1611, "Tavern",      "padrig_tavern"],
	[2120, 2144, "House",       "teren_house"],
	[2700, 2700, "House",       "ysra_house"],
	[3280, 3303, "Magic Shop",  "oswin_shop"],
	[3860, 3757, "House",       "rilla_house"],
]

# ── Nodes ─────────────────────────────────────────────────────────────────────
var _player:      CharacterBody2D
var _camera:      Camera2D
var _parallax_bg: ParallaxBackground
var _sky_layer:   ParallaxLayer
var _sky_drift:   float = 0.0

# NPCs (all 6)
var _npcs: Array = []          # Array of Node2D
var _npc_names: Array = []     # Parallel name strings

# Dog
var _dog_node:   Node2D
var _dog_sprite: AnimatedSprite2D
var _dog_dir:    int   = 1
var _dog_pause:  float = 0.0
var _dog_flee:   bool  = false
var _dog_gone:   bool  = false

# Slimes
var _slimes: Array = []
var _player_invincible: float = 0.0   # seconds of invincibility after being hit

# Audio
var _music:      AudioStreamPlayer
var _jump_sfx:   AudioStreamPlayer
var _attack_sfx: AudioStreamPlayer
var _hurt_sfx:   AudioStreamPlayer
var _bark_sfx:   AudioStreamPlayer

# HUD
var _hp_bar_fg: ColorRect
var _hp_label:  Label
var _hud_layer: CanvasLayer

# Door tooltips (world-space)
var _door_tips: Array = []

# Dialogue & menu
var _dialogue_box:     Node
var _menu_panel:       Node
var _dialogue_seq:     Array  = []
var _dialogue_idx:     int    = 0
var _active_npc:       String = ""
var _talking_npc_idx:  int    = -1
var _dialogue_state:   String = ""
var _city_portrait:    SpriteFrames = null

# State
var _transitioning:  bool = false
var _dialogue_open:  bool = false
var _menu_open:      bool = false

# Item popup
var _popup_label: Label
var _popup_timer: float = 0.0

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_parallax()
	_build_ground_physics()
	_build_ground_tiles()
	_build_city_wall()
	_build_buildings()
	_build_door_zones()
	_build_animated_props()
	_build_decor_props()
	_spawn_player()
	_spawn_npcs()
	_spawn_dog()
	_spawn_slimes()
	_build_camera()
	_build_audio()
	_build_hud()
	_build_dialogue()
	_build_menu()
	_build_popup()
	_fade_in()

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

# ── City wall ─────────────────────────────────────────────────────────────────
# Brick wall spans full width at y=726, height=184. Archway at x=380 covers gap visually.

func _build_city_wall() -> void:
	var tex: Texture2D = load("res://assets/props/brick_wall.png")
	if not tex: return
	const WALL_Y  := 726
	const WALL_H  := 184
	# Two sections around the archway gap (gap center=380, half-width=100)
	_tiled_wall(tex, 0, WALL_Y, 280, WALL_H, 5)
	_tiled_wall(tex, 480, WALL_Y, WORLD_WIDTH - 480, WALL_H, 5)

func _tiled_wall(tex: Texture2D, x: int, y: int, w: int, h: int, z: int) -> void:
	var sp := Sprite2D.new()
	sp.texture         = tex
	sp.centered        = false
	sp.region_enabled  = true
	sp.region_rect     = Rect2(0, 0, w, h)
	sp.texture_repeat  = CanvasItem.TEXTURE_REPEAT_ENABLED
	sp.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position        = Vector2(x, y)
	sp.z_index         = z
	add_child(sp)

# ── Buildings ─────────────────────────────────────────────────────────────────

func _build_buildings() -> void:
	for b in BUILDINGS:
		var tex: Texture2D = load(b[0])
		if not tex: push_warning("City: missing " + b[0]); continue
		var sp := Sprite2D.new()
		sp.texture  = tex; sp.centered = true
		sp.offset   = Vector2(0, -tex.get_height() * 0.5)
		sp.position = Vector2(b[1], PROP_BASE)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index  = 7; add_child(sp)

# ── Door zones (tooltips) ─────────────────────────────────────────────────────

func _build_door_zones() -> void:
	for dz in DOOR_ZONES:
		var lbl := Label.new()
		lbl.text    = str(dz[2]) + "  (E)"
		lbl.visible = false
		lbl.z_index = 30
		lbl.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.add_theme_font_size_override("font_size", 16)
		add_child(lbl)
		_door_tips.append({"label": lbl, "door_x": float(dz[1]), "config_id": str(dz[3])})

# ── Animated props (furnace and cooking area near tavern) ─────────────────────

func _build_animated_props() -> void:
	_anim_prop("res://assets/props/furnace_animated.png", 6,  64, 64, 1130, PROP_BASE, 9)
	_anim_prop("res://assets/props/cooking_area.png",    12, 64, 64, 1350, PROP_BASE, 9)

func _anim_prop(path: String, frame_count: int, fw: int, fh: int, x: float, base_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex: return
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("play")
	sf.set_animation_loop("play", true)
	sf.set_animation_speed("play", 8.0)
	for i in range(frame_count):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame("play", a)
	anim.sprite_frames = sf
	anim.play("play")
	# Position: anchor bottom of sprite at base_y
	anim.position = Vector2(x, base_y - fh / 2)
	anim.z_index  = z
	add_child(anim)

# ── Decor props ───────────────────────────────────────────────────────────────

func _build_decor_props() -> void:
	# Around blacksmith
	_prop("res://assets/props/decor_crate_large.png",  800,  PROP_BASE, 7)
	_prop("res://assets/props/decor_barrel_large.png", 870,  PROP_BASE, 7)
	_prop("res://assets/props/decor_crate.png",        1070, PROP_BASE, 7)
	# Near tavern
	_prop("res://assets/props/decor_stool.png",       1460, PROP_BASE, 7)
	_prop("res://assets/props/table_apples.png",      1610, PROP_BASE, 7)
	_prop("res://assets/props/decor_pottery.png",     1700, PROP_BASE, 7)
	# Central plaza
	_prop("res://assets/props/statue.png",            2420, PROP_BASE, 7)
	_prop("res://assets/props/decor_barrels_duo.png", 2560, PROP_BASE, 7)
	# Right side
	_prop("res://assets/props/decor_crate_small.png", 3100, PROP_BASE, 7)
	_prop("res://assets/props/decor_barrel_round.png",3180, PROP_BASE, 7)

func _prop(path: String, x: float, base_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex: push_warning("City: missing prop " + path); return
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

# ── NPCs (6 city NPCs) ────────────────────────────────────────────────────────

func _spawn_npcs() -> void:
	var scene: PackedScene = load("res://scenes/NPC.tscn")

	# [name, folder, x, min_x, max_x, speed]
	var configs := [
		["Bram Alder", "npc_city_1",    900.0,  550.0,  1380.0, 48.0],
		["Ysra Thorn", "npc_city_2",   3100.0, 2750.0,  3700.0, 46.0],
		["Teren Vale", "npc_city_3",   2000.0, 1600.0,  2560.0, 50.0],
		["Padrig",     "npc_tavern_chef", 1540.0, 1360.0, 1720.0, 38.0],
		["Oswin",      "npc_city_4",   1250.0,  700.0,  1900.0, 46.0],
		["Rilla",      "npc_city_5",   3450.0, 3000.0,  4200.0, 44.0],
	]

	for cfg in configs:
		var name: String   = cfg[0]
		var folder: String = cfg[1]
		var npc = _make_npc(scene, {
			"npc_name":      name,
			"walk_path":     "res://assets/npcs/" + folder + "/walk.png",
			"idle_path":     "res://assets/npcs/" + folder + "/idle.png",
			"patrol_min_x":  cfg[3],
			"patrol_max_x":  cfg[4],
			"patrol_speed":  cfg[5],
			"pause_ms":      3500.0,
		})
		npc.position = Vector2(cfg[2], NPC_GROUND_Y)
		add_child(npc)
		_npcs.append(npc)
		_npc_names.append(name)

func _make_npc(scene: PackedScene, cfg: Dictionary) -> Node2D:
	var n = scene.instantiate()
	for key in cfg:
		n.set(key, cfg[key])
	return n

# ── Dog (grey variant) ────────────────────────────────────────────────────────

func _spawn_dog() -> void:
	if Globals.city_dog_fled: return
	var dog_tex: Texture2D = load("res://assets/npcs/dog/sheet_grey.png")
	if not dog_tex: return

	_dog_node = Node2D.new()
	_dog_node.position = Vector2(2200.0, DOG_GROUND_Y)
	_dog_node.z_index  = 8
	add_child(_dog_node)

	_dog_sprite = AnimatedSprite2D.new()
	_dog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dog_sprite.scale  = Vector2(DOG_SCALE, DOG_SCALE)
	_dog_sprite.flip_h = true

	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 8.0)
	for i in range(DOG_FIRST_FR, DOG_LAST_FR + 1):
		var a := AtlasTexture.new()
		a.atlas  = dog_tex
		a.region = Rect2(i * DOG_FRAME_SZ, DOG_WALK_ROW * DOG_FRAME_SZ, DOG_FRAME_SZ, DOG_FRAME_SZ)
		sf.add_frame("walk", a)
	_dog_sprite.sprite_frames = sf
	_dog_sprite.play("walk")
	_dog_node.add_child(_dog_sprite)

# ── Slimes (east of city, past the last building) ────────────────────────────

func _spawn_slimes() -> void:
	var slime_script: GDScript = load("res://scripts/Slime.gd")

	# [sheet_path, center_x, patrol_range_half]
	var configs := [
		["res://assets/enemies/slime_green.png",  4200.0, 140.0],
		["res://assets/enemies/slime_blue.png",   4380.0, 120.0],
		["res://assets/enemies/slime_red.png",    4560.0, 100.0],
		["res://assets/enemies/slime_red.png", 4680.0,  90.0],
		["res://assets/enemies/slime_green.png",  4300.0, 160.0],
	]

	for cfg in configs:
		var slime = slime_script.new()
		slime.slime_sheet  = cfg[0]
		slime.ground_y     = SLIME_GROUND_Y
		slime.patrol_min_x = cfg[1] - cfg[2]
		slime.patrol_max_x = cfg[1] + cfg[2]
		slime.position     = Vector2(cfg[1], SLIME_GROUND_Y)
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
	_music      = _audio("res://assets/audio/celadune_city.mp3",                                         0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                              0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",                 0.55, false)
	_hurt_sfx   = _audio("res://assets/sfx/freesound_community-male_hurt7-48124.mp3",                    0.6,  false)
	_bark_sfx   = _audio("res://assets/sfx/freesound_community-dog-bark2-92560.mp3",                     0.55, false)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.42), 0.32)

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
	# Only flee if dog is within 200px — matches Phaser's distance check
	if _dog_node and not _dog_flee and not _dog_gone:
		if absf(_player.position.x - _dog_node.position.x) < 200.0:
			_trigger_dog_flee()
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
	# Brief visual flash on player sprite
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

# ── Dialogue & menu setup ─────────────────────────────────────────────────────

func _build_dialogue() -> void:
	var db_script: GDScript = load("res://scripts/DialogueBox.gd")
	_dialogue_box = db_script.new()
	add_child(_dialogue_box)
	_dialogue_box.choice_confirmed.connect(_on_dialogue_choice)
	_dialogue_box.dismissed.connect(_on_dialogue_dismissed)

func _build_menu() -> void:
	var mp_script: GDScript = load("res://scripts/MenuPanel.gd")
	_menu_panel = mp_script.new()
	add_child(_menu_panel)
	_menu_panel.closed.connect(_on_menu_closed)

func _build_popup() -> void:
	var cl := CanvasLayer.new(); cl.layer = 70; add_child(cl)
	_popup_label = Label.new()
	_popup_label.visible = false
	_popup_label.add_theme_font_override("font", Globals.FONT_TITLE)
	_popup_label.add_theme_font_size_override("font_size", 32)
	_popup_label.add_theme_color_override("font_color",        Color(1.0, 0.95, 0.50))
	_popup_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_popup_label.add_theme_constant_override("shadow_offset_x", 2)
	_popup_label.add_theme_constant_override("shadow_offset_y", 2)
	cl.add_child(_popup_label)

func show_item_popup(text: String) -> void:
	_popup_label.text = "+ " + text
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
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.5)
	tw.tween_callback(ov.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# Per-frame
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _player: return

	_sky_drift -= 0.1
	if _sky_layer: _parallax_bg.scroll_offset = Vector2(_sky_drift, 0.0)

	if _popup_timer > 0.0:
		_popup_timer -= delta
		if _popup_timer <= 0.0: _popup_label.visible = false

	if _player_invincible > 0.0:
		_player_invincible -= delta

	if _dialogue_open or _menu_open: return

	_update_tooltips()
	_update_dog(delta)

	if Input.is_action_just_pressed("menu_toggle"):
		_open_menu(); return

	_check_boundaries()

func _update_tooltips() -> void:
	var px := _player.position.x
	var py := _player.position.y

	# Building door tooltips
	var near_door_config: String = ""
	var near_door_x: float = 0.0
	for dt in _door_tips:
		var lbl: Label = dt["label"]
		var door_x: float = dt["door_x"]
		var near := absf(px - door_x) < 100.0
		lbl.visible = near
		if near:
			lbl.position = Vector2(door_x - 70, GROUND_Y - 130)
			near_door_config = dt["config_id"]
			near_door_x = door_x

	# E to enter building
	if Input.is_action_just_pressed("interact") and near_door_config != "":
		_enter_building(near_door_config); return

	# NPC tooltips + interact
	if Input.is_action_just_pressed("interact"):
		for i in range(_npcs.size()):
			var npc: Node2D = _npcs[i]
			if not npc: continue
			if Vector2(px, py).distance_to(npc.position) < NPC_TALK_R:
				_open_city_npc_dialogue(i); return

func _update_dog(delta: float) -> void:
	if not _dog_node or _dog_gone: return
	if _dog_pause > 0.0:
		_dog_pause -= delta; return

	var spd: float = DOG_FLEE_SPD if _dog_flee else DOG_SPEED
	_dog_node.position.x += _dog_dir * spd * delta
	_dog_sprite.flip_h = _dog_dir < 0  # flip when going LEFT (sprite faces right natively)

	if _dog_flee:
		if _dog_node.position.x < DOG_MIN_X - 200 or _dog_node.position.x > DOG_MAX_X + 200:
			_dog_node.queue_free(); _dog_node = null
			_dog_gone = true; Globals.city_dog_fled = true
		return

	if _dog_dir > 0 and _dog_node.position.x >= DOG_MAX_X:
		_dog_node.position.x = DOG_MAX_X; _dog_dir = -1
		_dog_pause = randf_range(1.5, 4.0)
	elif _dog_dir < 0 and _dog_node.position.x <= DOG_MIN_X:
		_dog_node.position.x = DOG_MIN_X; _dog_dir = 1
		_dog_pause = randf_range(1.5, 4.0)

func _trigger_dog_flee() -> void:
	if not _dog_node or _dog_flee or _dog_gone: return
	_dog_flee = true; _bark_sfx.play()
	_dog_dir = 1 if _dog_node.position.x > _player.position.x else -1
	Globals.change_reputation(-0.5)

# ══════════════════════════════════════════════════════════════════════════════
# Dialogue
# ══════════════════════════════════════════════════════════════════════════════

func _open_city_npc_dialogue(npc_idx: int) -> void:
	_talking_npc_idx = npc_idx
	var name: String = _npc_names[npc_idx]
	var folder_map := {
		"Bram Alder":  "npc_city_1",
		"Ysra Thorn":  "npc_city_2",
		"Teren Vale":  "npc_city_3",
		"Padrig":      "npc_tavern_chef",
		"Oswin":       "npc_city_4",
		"Rilla":       "npc_city_5",
	}
	var folder: String = folder_map.get(name, "npc_city_1")
	_city_portrait = DialogueBox.make_portrait_frames("res://assets/npcs/" + folder + "/idle.png", 5)
	var rep := Globals.player_reputation

	_dialogue_open = true
	_player.set_physics_process(false)
	if _talking_npc_idx >= 0 and _talking_npc_idx < _npcs.size():
		_npcs[_talking_npc_idx].pause_patrol()

	match name:
		"Bram Alder":
			_active_npc     = "city1"
			if rep <= 2:
				_dialogue_state = "city1End"
				var line := "You've got a reputation, stranger. I'd rather not be seen talking to you. Move along." if rep == 1 else "I know your type. Don't cause trouble in Millhaven."
				_dialogue_box.show_line("Bram Alder", line, ["..."], _city_portrait)
			else:
				_dialogue_state = "city1Greet"
				var lines := {
					3: "New face in Millhaven. What brings you through?",
					4: "Welcome to " + Globals.TOWN_NAME + ". Quiet place, the way folk here like it. Most are farmers and traders.",
					5: "Ah, a traveler! " + Globals.TOWN_NAME + " isn't much, but it's honest. Looking for anything in particular?",
					6: "Good to see a respectable face! " + Globals.TOWN_NAME + "'s been busy with harvest coming in.",
					7: "By the saints — Caelan himself in " + Globals.TOWN_NAME + "! Folk speak well of you around here.",
				}
				_dialogue_box.show_line("Bram Alder", lines.get(rep, lines[4]), ["Just passing through."], _city_portrait)

		"Ysra Thorn":
			_active_npc = "city2"
			if rep <= 2:
				_dialogue_state = "city2End"
				var line := "I don't deal with people of poor character. Away with you." if rep == 1 else "I've no patience for troublemakers. Keep walking."
				_dialogue_box.show_line("Ysra Thorn", line, ["..."], _city_portrait)
			else:
				_dialogue_state = "city2Greet"
				var lines := {
					3: "The roads north of the mill get dangerous. Not that it's my business to warn you.",
					4: "Passable roads for now, but I'd keep an eye on the north track past the mill. Strange marks in the mud lately.",
					5: "Glad you're passing through. Something's been prowling the north fields. You look like you can handle yourself.",
					6: "Take care on the north road — strange tracks near the mill. Good to have someone capable around.",
					7: "You know these roads better than most by now. Still — the north track has been unsettled. Watch yourself.",
				}
				_dialogue_box.show_line("Ysra Thorn", lines.get(rep, lines[4]), ["I appreciate the warning."], _city_portrait)

		"Teren Vale":
			_active_npc = "city3"
			if rep <= 2:
				_dialogue_state = "city3End"
				var line := "Get away from me." if rep == 1 else "I've nothing to say to someone like you."
				_dialogue_box.show_line("Teren Vale", line, ["..."], _city_portrait)
			else:
				_dialogue_state = "city3Greet"
				var lines := {
					3: "Not much of a talker today. Is something the matter?",
					4: Globals.TOWN_NAME + "'s been here longer than the king's tax collectors, and it'll outlast them too. Things are quiet, for now.",
					5: "Good to see a new face that doesn't look like trouble! Harvest was decent, mill's running again.",
					6: "Always glad when decent folk pass through. Trade's picked up since the mill wheel got fixed.",
					7: "They ought to put your name on the town gate, friend. " + Globals.TOWN_NAME + "'s better for having you around.",
				}
				_dialogue_box.show_line("Teren Vale", lines.get(rep, lines[4]), ["Good to know."], _city_portrait)

		"Padrig":
			_active_npc = "padrig"
			_open_padrig_dialogue(rep)

		"Oswin":
			_active_npc = "city4"
			if rep <= 2:
				_dialogue_state = "city4End"
				var line := "Not interested in talking." if rep == 1 else "Got nothing for you. Move on."
				_dialogue_box.show_line("Oswin", line, ["..."], _city_portrait)
			else:
				_dialogue_state = "city4Greet"
				var lines := {
					3: "Business is slow today. Can't say I'm feeling chatty.",
					4: "Market day's Thursday — that's when " + Globals.TOWN_NAME + " really comes alive.",
					5: "Good day! There's always something to trade in " + Globals.TOWN_NAME + " if you know who to ask.",
					6: "A pleasure to meet you! Business picks up when good folk pass through.",
					7: "Caelan! An honor. I'll have to tell my wife I spoke with you today.",
				}
				_dialogue_box.show_line("Oswin", lines.get(rep, lines[4]), ["Good to know."], _city_portrait)

		"Rilla":
			_active_npc = "city5"
			if rep <= 2:
				_dialogue_state = "city5End"
				var line := "Don't talk to me." if rep == 1 else "I have nothing to say to you."
				_dialogue_box.show_line("Rilla", line, ["..."], _city_portrait)
			else:
				_dialogue_state = "city5Greet"
				var lines := {
					3: "Not the best day for visitors, honestly.",
					4: "It's a decent enough town if you give it a chance. " + Globals.TOWN_NAME + " grows on you.",
					5: "Welcome! Don't let the size fool you — there's plenty of life here.",
					6: "What a lovely day! The baker just pulled fresh bread out. " + Globals.TOWN_NAME + " smells wonderful right now.",
					7: "Oh, Caelan! I've heard so much. " + Globals.TOWN_NAME + " is lucky to have people like you stopping by.",
				}
				_dialogue_box.show_line("Rilla", lines.get(rep, lines[4]), ["Thanks, always nice to hear."], _city_portrait)

func _open_padrig_dialogue(rep: int) -> void:
	# Player has onions — quest delivery
	if Globals.has_item("Onions"):
		var lines := {
			1: "Those Mirelle's onions? Fine. Here's the 5 gold. Now get out of my kitchen.",
			2: "Mirelle's onions. Here — take the 5 gold. Tell her I'm grateful.",
			3: "Mirelle's onions? Good. Here, take the 5 gold for her.",
			4: "Mirelle's onions! Best in the valley. Here's the 5 gold as promised — make sure she gets it.",
			5: "You brought Mirelle's onions! Wonderful. Here are 5 gold — give them to her with my thanks.",
			6: "Mirelle's onions, fresh as ever! My kitchen will thank you. Here's 5 gold — tell her she's a treasure.",
			7: "Caelan with Mirelle's onions — my kitchen smells like heaven already. Here's 5 gold, not a coin short!",
		}
		Globals.remove_item("Onions")
		Globals.story_flags["chef_onions_delivered"] = true
		Globals.quest_state = "paymentPending"
		Globals.add_gold(5)
		show_item_popup("5 Gold")
		_dialogue_state = "chefThanks"
		_dialogue_box.show_line("Padrig", lines.get(rep, lines[4]), ["I'll get this to Mirelle."], _city_portrait)
		return

	# After delivery — already complete
	if Globals.story_flags.get("chef_onions_delivered", false):
		var lines := {
			1: "You again. Kitchen's not open to troublemakers.",
			2: "You're back. Don't cause problems in here.",
			3: "The stew's on if you need it. Don't linger.",
			4: "The kitchen still smells better for Mirelle's onions. Tell her I haven't forgotten.",
			5: "Good to see you again! Stew's hot and the bread just came out.",
			6: "Welcome back! I've got a table saved. The lamb stew is particularly good today.",
			7: "Caelan! I was hoping you'd stop by. Drinks are on me — sit down!",
		}
		_dialogue_state = "chefAfter"
		_dialogue_box.show_line("Padrig", lines.get(rep, lines[4]), ["Thanks, Padrig."], _city_portrait)
		return

	# Standard greeting
	var lines := {
		1: "I run a respectable establishment. I'll have to ask you to leave.",
		2: "I've heard things. The kitchen's not a place for trouble.",
		3: "What'll it be? Make it quick.",
		4: "Welcome to the " + Globals.TOWN_NAME + " Tavern! Best stew in the valley, if I say so myself.",
		5: "Come in, come in! Fire's going and the stew's on. What can I get you?",
		6: "Wonderful to see you! Fresh lamb stew today. Sit yourself down.",
		7: "Caelan! The man himself! I'll tell the whole town — come in, drinks on me!",
	}
	_dialogue_state = "chefGreeting"
	_dialogue_box.show_line("Padrig", lines.get(rep, lines[4]), ["Maybe another time."], _city_portrait)

func _on_dialogue_choice(_idx: int) -> void:
	# All city NPC dialogues are single-line terminal — always close
	_dialogue_box.close()

func _on_dialogue_dismissed() -> void:
	if _talking_npc_idx >= 0 and _talking_npc_idx < _npcs.size():
		_npcs[_talking_npc_idx].resume_patrol()
	_talking_npc_idx = -1
	_dialogue_open   = false
	_active_npc      = ""
	_dialogue_state  = ""
	_dialogue_seq    = []
	if _player: _player.set_physics_process(true)

# ── Menu ──────────────────────────────────────────────────────────────────────

func _open_menu() -> void:
	_menu_open = true
	_player.set_physics_process(false)
	_menu_panel.open()

func _on_menu_closed() -> void:
	_menu_open = false
	if _player: _player.set_physics_process(true)

# ── Scene boundaries ──────────────────────────────────────────────────────────

func _enter_building(config_id: String) -> void:
	if _transitioning: return
	Globals.interior_config_id = config_id
	Globals.from_transition    = true
	_transition_to("HutInterior")

func _check_boundaries() -> void:
	if _transitioning or not _player: return
	if _player.position.x < 80 and _player.velocity.x < 0:
		Globals.from_transition = true
		Globals.spawn_x = 5000.0
		_transition_to("Forest")
	# Right edge → Wilderness (matches Phaser: right off City → WildernessScene)
	if _player.position.x > 4680.0 and _player.velocity.x > 0:
		Globals.from_transition = true
		Globals.spawn_x = 120.0
		_transition_to("Wilderness")

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
