extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# City scene — Phaser CityScene port
# World: 4800 × 1080  (CITY_WORLD_WIDTH = 4800)
# Same GROUND_Y = 888, brown tileset (T_TOP_C = 55, T_FILL = 64)
# Buildings: archway=380, blacksmith=960, tavern=1540, house1=2120,
#            house3=2700, magic_shop=3280, house2=3860  (baseY = 927-12 = 915)
# Transition: walk left past x≈80 → Forest; walk right past x≈4720 → Wilderness
# ══════════════════════════════════════════════════════════════════════════════

const WORLD_WIDTH  := 4800
const GAME_W       := 1920
const GAME_H       := 1080
const GROUND_Y     := 888
const PROP_BASE    := 915   # BLACK_TILE_GROUND_Y(927) - 12
const TILE_PX      := 96

# Brown tileset frame indices
const T_TOP_L := 54; const T_TOP_C := 55; const T_TOP_R := 56; const T_FILL := 64

const BG_LAYERS := [
	{ "path": "res://assets/bg/forest_sky.png",      "factor": 0.10, "y_off": -100 },
	{ "path": "res://assets/bg/forest_mountain.png", "factor": 0.26, "y_off": -172 },
	{ "path": "res://assets/bg/forest_back.png",     "factor": 0.42, "y_off": -172 },
	{ "path": "res://assets/bg/forest_mid.png",      "factor": 0.58, "y_off": -172 },
	{ "path": "res://assets/bg/forest_short.png",    "factor": 0.90, "y_off": -172 },
]

var _player:      CharacterBody2D
var _camera:      Camera2D
var _music:       AudioStreamPlayer
var _transitioning := false
var _sky_drift:   float = 0.0
var _parallax_bg: ParallaxBackground
var _sky_layer:   ParallaxLayer

func _ready() -> void:
	_build_parallax()
	_build_ground_physics()
	_build_ground_tiles()
	_build_city_buildings()
	_spawn_player()
	_build_camera()
	_build_audio()
	_build_hud()
	_fade_in()

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

func _build_ground_physics() -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size     = Vector2(WORLD_WIDTH * 2.0, 400.0)
	shape.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 200.0)
	shape.shape   = rect
	body.add_child(shape)
	add_child(body)

func _build_ground_tiles() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/floor_tiles2.png")
	var cols := WORLD_WIDTH / TILE_PX
	for col in range(cols):
		var cx := col * TILE_PX + TILE_PX / 2
		var top := T_TOP_C
		if col == 0: top = T_TOP_L
		elif col == cols - 1: top = T_TOP_R
		_tile(tile_tex, cx, GROUND_Y + TILE_PX / 2, top, 12)
		var fill_rows := int(ceil(float(GAME_H - GROUND_Y) / TILE_PX)) + 1
		for row in range(1, fill_rows + 1):
			_tile(tile_tex, cx, GROUND_Y + TILE_PX * row + TILE_PX / 2, T_FILL, 2)
		var bg := ColorRect.new()
		bg.color    = Color(0.102, 0.071, 0.031)
		bg.size     = Vector2(TILE_PX, GAME_H + 200 - GROUND_Y)
		bg.position = Vector2(cx - TILE_PX / 2, GROUND_Y)
		bg.z_index  = 1
		add_child(bg)

func _tile(tex: Texture2D, cx: float, cy: float, frame: int, z: int) -> void:
	var atlas := AtlasTexture.new(); atlas.atlas = tex
	atlas.region = Rect2((frame % 9) * TILE_PX, (frame / 9) * TILE_PX, TILE_PX, TILE_PX)
	var sp := Sprite2D.new(); sp.texture = atlas; sp.centered = true
	sp.position = Vector2(cx, cy); sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = z; add_child(sp)

func _build_city_buildings() -> void:
	# From Phaser CityScene.createCityBuildings():
	# baseY = BLACK_TILE_GROUND_Y - 12 = 927 - 12 = 915
	var placements := [
		["res://assets/buildings/city_archway/building.png",    380],
		["res://assets/buildings/city_blacksmith/building.png", 960],
		["res://assets/buildings/city_tavern/building.png",    1540],
		["res://assets/buildings/city_house_1/building.png",   2120],
		["res://assets/buildings/city_house_3/building.png",   2700],
		["res://assets/buildings/city_magic_shop/building.png",3280],
		["res://assets/buildings/city_house_2/building.png",   3860],
	]
	for p in placements:
		var tex: Texture2D = load(p[0])
		if not tex: push_warning("City: missing " + p[0]); continue
		var sp := Sprite2D.new()
		sp.texture = tex; sp.centered = true
		sp.offset  = Vector2(0, -tex.get_height() * 0.5)
		sp.position = Vector2(p[1], PROP_BASE)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 7
		add_child(sp)

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(180.0, 768.0)
	add_child(_player)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left = 0; _camera.limit_right = WORLD_WIDTH
	_camera.limit_top  = 0; _camera.limit_bottom = GAME_H
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 5.0
	_camera.drag_horizontal_enabled    = true; _camera.drag_vertical_enabled = true
	_camera.drag_left_margin  = 0.069; _camera.drag_right_margin  = 0.069
	_camera.drag_top_margin   = 0.067; _camera.drag_bottom_margin = 0.067
	_player.add_child(_camera)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var res := load("res://assets/audio/celadune_city.mp3") as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream = res
	_music.volume_db = linear_to_db(0.0)
	add_child(_music)
	_music.play()
	var t := create_tween()
	t.tween_property(_music, "volume_db", linear_to_db(0.42), 0.32)

func _build_hud() -> void:
	var hud := CanvasLayer.new(); hud.layer = 10; add_child(hud)
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); hud.add_child(bar_bg)
	var bar_fg := ColorRect.new()
	bar_fg.position = Vector2(26, GAME_H - 44); bar_fg.size = Vector2(176, 12)
	bar_fg.color = Color(0.87, 0.2, 0.2); hud.add_child(bar_fg)
	var hint := Label.new()
	hint.text = "M  Menu"; hint.position = Vector2(GAME_W - 120, GAME_H - 32)
	hint.add_theme_color_override("font_color", Color(0.78, 0.87, 0.92))
	hint.add_theme_font_size_override("font_size", 18); hud.add_child(hint)

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var t := create_tween()
	t.tween_property(ov, "color", Color(0,0,0,0), 0.5)
	t.tween_callback(ov.queue_free)

func _process(_delta: float) -> void:
	if not _player: return
	_sky_drift -= 0.1
	if _sky_layer: _parallax_bg.scroll_offset = Vector2(_sky_drift, 0.0)
	_check_boundaries()

func _check_boundaries() -> void:
	if _transitioning: return
	# Left edge → back to Forest
	if _player.position.x < 80 and _player.velocity.x < 0:
		_transition_to("Forest", 5100.0)
	# Right edge → Wilderness (placeholder back to Forest for now)
	elif _player.position.x > WORLD_WIDTH - 120 and _player.velocity.x > 0:
		_transition_to("Forest", 5100.0)

func _transition_to(scene: String, _spawn_x: float) -> void:
	if _transitioning: return
	_transitioning = true
	_player.set_physics_process(false)
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var t := create_tween()
	t.tween_property(_music, "volume_db", -80.0, 0.22)
	t.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.22)
	t.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + scene + ".tscn"))
