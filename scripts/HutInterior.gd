extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Hut Interior scene
# Simple interior room — player can walk, E near door returns to Forest
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W   := 1920
const GAME_H   := 1080
const GROUND_Y := 888
const WORLD_W  := 1920

# Door/exit zone — centred at bottom of hut interior
const EXIT_X   := 960.0
const EXIT_Y   := 900.0
const EXIT_R   := 130.0

var _player:     CharacterBody2D
var _camera:     Camera2D
var _music:      AudioStreamPlayer
var _door_sfx:   AudioStreamPlayer
var _transitioning: bool = false
var _exit_tip:   Label

func _ready() -> void:
	_build_bg()
	_build_ground_physics()
	_build_props()
	_spawn_player()
	_build_camera()
	_build_audio()
	_build_hud()
	_fade_in()

func _build_bg() -> void:
	var cl := CanvasLayer.new(); cl.layer = -10; add_child(cl)
	var bg := TextureRect.new()
	bg.texture      = load("res://assets/bg/forest_hut_interior.jpeg")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size         = Vector2(GAME_W, GAME_H)
	bg.position     = Vector2.ZERO
	cl.add_child(bg)

func _build_ground_physics() -> void:
	var body  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size      = Vector2(WORLD_W * 2.0, 400.0)
	shape.position = Vector2(WORLD_W / 2.0, GROUND_Y + 200.0)
	shape.shape    = rect
	body.add_child(shape)
	add_child(body)

func _build_props() -> void:
	# Interior furniture using available furniture assets
	_prop("res://assets/props/furniture/cabinet_wood.png",  300,  GROUND_Y, 7)
	_prop("res://assets/props/furniture/armoire.png",       500,  GROUND_Y, 7)
	_prop("res://assets/props/furniture/bed_canopy.png",   1580,  GROUND_Y, 7)
	_prop("res://assets/props/furniture/dresser.png",      1680,  GROUND_Y, 7)
	_prop("res://assets/props/furniture/flower_vase.png",   800,  GROUND_Y, 7)
	_prop("res://assets/props/furniture/table_lamp.png",    860,  GROUND_Y, 7)

	# Exit tooltip
	_exit_tip = Label.new()
	_exit_tip.text    = "Exit  (E)"
	_exit_tip.visible = false
	_exit_tip.z_index = 30
	_exit_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_exit_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_exit_tip.add_theme_constant_override("shadow_offset_x", 2)
	_exit_tip.add_theme_constant_override("shadow_offset_y", 2)
	_exit_tip.add_theme_font_size_override("font_size", 18)
	_exit_tip.position = Vector2(EXIT_X - 35, EXIT_Y - 70)
	add_child(_exit_tip)

func _prop(path: String, x: float, base_y: float, z: int) -> void:
	var tex: Texture2D = load(path)
	if not tex: return
	var sp := Sprite2D.new(); sp.texture = tex; sp.centered = true
	sp.offset         = Vector2(0.0, -tex.get_height() * 0.5)
	sp.position       = Vector2(x, base_y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = z; add_child(sp)

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(EXIT_X, 835.0)
	_player.jumped.connect(func(): pass)
	_player.attacked.connect(func(): pass)
	add_child(_player)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0; _camera.limit_right  = WORLD_W
	_camera.limit_top    = 0; _camera.limit_bottom = GAME_H
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 4.0
	_player.add_child(_camera)

func _build_audio() -> void:
	# Quiet ambient music inside the hut (use forest music at low volume)
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

func _build_hud() -> void:
	var hud := CanvasLayer.new(); hud.layer = 10; add_child(hud)
	var hint := Label.new()
	hint.text     = "Interior"
	hint.position = Vector2(GAME_W / 2 - 60, 20)
	hint.add_theme_color_override("font_color", Color(0.78, 0.70, 0.55, 0.7))
	hint.add_theme_font_size_override("font_size", 22)
	hud.add_child(hint)

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.4)
	tw.tween_callback(ov.queue_free)

func _process(_delta: float) -> void:
	if not _player: return
	var dist := _player.position.distance_to(Vector2(EXIT_X, EXIT_Y))
	_exit_tip.visible = dist < EXIT_R * 1.4
	if dist < EXIT_R and Input.is_action_just_pressed("interact"):
		_exit_hut()

func _exit_hut() -> void:
	if _transitioning: return
	_transitioning = true
	_door_sfx.play()
	Globals.from_transition = true
	Globals.spawn_x = 2274.0  # return to hut door position in Forest
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Forest.tscn"))
