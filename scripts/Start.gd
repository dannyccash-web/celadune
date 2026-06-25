extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Start screen (splash / title)
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W := 1920
const GAME_H := 1080

var _music:           AudioStreamPlayer
var _sheen:           ColorRect = null   # direct reference for fast updates
var _sheen_x:         float = 0.0
var _sheen_active:    bool  = false
var _ready_to_start:  bool  = false
var _logo_left:       float = 320.0   # logo left edge in logo-container space
var _logo_right:      float = 1280.0  # logo right edge in logo-container space

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

	# Logo — placed in a clipping container so the sheen is masked to the logo area
	const LOGO_W := 1280; const LOGO_H := 640
	const LOGO_X := (GAME_W - LOGO_W) / 2   # = 320
	const LOGO_Y := 60

	# Clipping container — children render only within its rect
	var logo_clip := Control.new()
	logo_clip.position     = Vector2(LOGO_X, LOGO_Y)
	logo_clip.size         = Vector2(LOGO_W, LOGO_H)
	logo_clip.clip_children = Control.CLIP_CHILDREN_ONLY
	cl.add_child(logo_clip)

	var logo := TextureRect.new()
	logo.texture      = load("res://assets/ui/celadune_logo.png")
	logo.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size         = Vector2(LOGO_W, LOGO_H)
	logo.position     = Vector2.ZERO
	logo_clip.add_child(logo)

	# Sheen — diagonal stripe; swept in _process; clipped to logo bounds by parent
	_sheen = ColorRect.new()
	_sheen.name     = "Sheen"
	_sheen.color    = Color(1, 1, 1, 0.25)
	_sheen.size     = Vector2(90, LOGO_H + 200)
	_sheen.rotation = deg_to_rad(20)
	_sheen.position = Vector2(-120, -100)   # local coords inside logo_clip
	logo_clip.add_child(_sheen)

	# Sweep range is logo-container-local: 0 .. LOGO_W
	_logo_left  = 0.0
	_logo_right = LOGO_W

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

	# (watermark removed)

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
	_sheen_x      = _logo_left - 120.0   # start just before logo left edge

func _process(delta: float) -> void:
	# Animate sheen across logo (position is local to logo_clip container)
	if _sheen_active and _sheen:
		_sheen_x += 800.0 * delta
		_sheen.position.x = _sheen_x
		if _sheen_x > _logo_right + 120.0:
			_sheen_active = false
			_sheen.position.x = _logo_left - 200   # hide offscreen left
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
	tw2.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/HeroSelect.tscn"))
