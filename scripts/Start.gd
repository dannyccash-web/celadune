extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Start screen (splash / title)
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W := 1920
const GAME_H := 1080

var _music:       AudioStreamPlayer
var _sheen_timer: float = 0.0
var _sheen_x:     float = -600.0
var _sheen_active: bool  = false
var _ready_to_start: bool = false

func _ready() -> void:
	_build_ui()
	_build_audio()
	_start_sheen()
	Globals.reset()

func _build_ui() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)

	# Background
	var bg := TextureRect.new()
	bg.texture      = load("res://assets/ui/celadune_start_screen_background.jpeg")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size         = Vector2(GAME_W, GAME_H)
	bg.position     = Vector2.ZERO
	cl.add_child(bg)

	# Dark overlay for readability
	var overlay := ColorRect.new()
	overlay.color    = Color(0.02, 0.02, 0.04, 0.38)
	overlay.size     = Vector2(GAME_W, GAME_H)
	overlay.position = Vector2.ZERO
	cl.add_child(overlay)

	# Logo
	var logo := TextureRect.new()
	logo.texture      = load("res://assets/ui/celadune_logo.png")
	logo.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size         = Vector2(960, 480)
	logo.position     = Vector2(480, 80)
	cl.add_child(logo)

	# Sheen effect (white diagonal stripe over logo)
	var sheen := ColorRect.new()
	sheen.name    = "Sheen"
	sheen.color   = Color(1, 1, 1, 0.18)
	sheen.size    = Vector2(60, 700)
	sheen.rotation = deg_to_rad(30)
	sheen.position = Vector2(-600, 0)
	cl.add_child(sheen)

	# "Press Enter to begin"
	var prompt := Label.new()
	prompt.text     = "Press  Enter  to  begin"
	prompt.position = Vector2(0, 1006)
	prompt.size     = Vector2(GAME_W, 60)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", Globals.FONT_TITLE)
	prompt.add_theme_font_size_override("font_size", 36)
	prompt.add_theme_color_override("font_color", Color(0.94, 0.88, 0.64))
	cl.add_child(prompt)

	# Pulse animation on prompt
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(prompt, "modulate:a", 0.3, 0.85)
	tw.tween_property(prompt, "modulate:a", 1.0, 0.85)

	# Version hint
	var ver := Label.new()
	ver.text     = Globals.TOWN_NAME
	ver.position = Vector2(GAME_W - 200, GAME_H - 36)
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38, 0.7))
	cl.add_child(ver)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var res := load("res://assets/audio/celadune_theme.mp3") as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream    = res
		_music.volume_db = linear_to_db(0.0)
	add_child(_music)
	_music.play()
	# Fade in to 0.52 (Phaser volumeStart=0.52)
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.52), 1.2)
	_ready_to_start = false
	await get_tree().create_timer(0.8).timeout
	_ready_to_start = true

func _start_sheen() -> void:
	_sheen_active = true
	_sheen_x      = -600.0

func _process(delta: float) -> void:
	# Animate sheen across logo
	if _sheen_active:
		_sheen_x += 800.0 * delta
		var sheen = get_node_or_null("CanvasLayer/Sheen")
		if not sheen:
			# Find it in the canvas layer
			for cl in get_children():
				if cl is CanvasLayer:
					sheen = cl.get_node_or_null("Sheen")
					if sheen: break
		if sheen:
			sheen.position.x = _sheen_x
			if _sheen_x > GAME_W + 200:
				_sheen_active = false
				# Restart sheen after 4 seconds
				await get_tree().create_timer(4.0).timeout
				if is_instance_valid(self): _start_sheen()

	if not _ready_to_start: return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		_go_to_forest()

func _go_to_forest() -> void:
	_ready_to_start = false
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.4)
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 200; cl.add_child(ov); add_child(cl)
	var tw2 := create_tween()
	tw2.tween_property(ov, "color", Color(0,0,0,1), 0.4)
	tw2.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Forest.tscn"))
