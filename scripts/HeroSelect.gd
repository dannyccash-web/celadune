extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Hero Select screen
# Matches Phaser HeroSelectScene: parchment panel 318×182 at 1284×716,
# hero card at y=538 scale 3.8, name at y+125, role "Fighter" at y+166.
# Enter/Space confirms → Forest, Esc → Start screen.
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W := 1920
const GAME_H := 1080

# Panel (parchment background)
const PANEL_X := 1284
const PANEL_Y := 716
const PANEL_W := 318
const PANEL_H := 182

# Card position
const CARD_X  := 960
const CARD_Y  := 538
const PORTRAIT_SCALE := 3.8

# Card outline dimensions (matches Phaser 300×398 outer rect)
const CARD_W  := 300
const CARD_H  := 398

const COL_PARCHMENT  := Color(0.941, 0.875, 0.710)
const COL_BORDER_OUT := Color(0.357, 0.216, 0.090)
const COL_BORDER_IN  := Color(0.855, 0.710, 0.416)
const COL_SPEAKER    := Color(0.290, 0.141, 0.067)
const COL_BODY       := Color(0.169, 0.106, 0.059)

var _ready_to_confirm: bool = false
var _music: AudioStreamPlayer
var _portrait_sprite: AnimatedSprite2D

func _ready() -> void:
	_build_ui()
	_build_audio()
	# Brief delay before accepting input
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self): _ready_to_confirm = true

func _build_ui() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)

	# Background — same as Start screen
	var bg := TextureRect.new()
	bg.texture      = load("res://assets/ui/celadune_start_screen_background.jpeg")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size         = Vector2(GAME_W, GAME_H)
	bg.position     = Vector2.ZERO
	cl.add_child(bg)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color    = Color(0.02, 0.02, 0.04, 0.55)
	overlay.size     = Vector2(GAME_W, GAME_H)
	overlay.position = Vector2.ZERO
	cl.add_child(overlay)

	# Title
	var title := Label.new()
	title.text = "Choose Your Hero"
	title.position = Vector2(0, 110)
	title.size     = Vector2(GAME_W, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Globals.FONT_TITLE)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", COL_PARCHMENT)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	cl.add_child(title)

	# Hero card outer rect (border)
	var card_outer := _panel_rect(
		CARD_X - CARD_W / 2, CARD_Y - CARD_H / 2,
		CARD_W, CARD_H, COL_BORDER_OUT, COL_PARCHMENT, 4
	)
	cl.add_child(card_outer)

	# Inner gold border
	var card_inner := _border_only(
		CARD_X - CARD_W / 2 + 8, CARD_Y - CARD_H / 2 + 8,
		CARD_W - 16, CARD_H - 16, COL_BORDER_IN, 2
	)
	cl.add_child(card_inner)

	# Portrait sprite (Caelan idle strip)
	var idle_tex: Texture2D = load("res://assets/characters/caelan/idle.png")
	if idle_tex:
		_portrait_sprite = AnimatedSprite2D.new()
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", 2.0)
		var a := AtlasTexture.new()
		a.atlas  = idle_tex
		a.region = Rect2(0, 0, 100, 64)
		sf.add_frame("idle", a)
		_portrait_sprite.sprite_frames = sf
		_portrait_sprite.scale    = Vector2(PORTRAIT_SCALE, PORTRAIT_SCALE)
		_portrait_sprite.flip_h   = true
		_portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_portrait_sprite.position = Vector2(CARD_X, CARD_Y + 10)
		_portrait_sprite.play("idle")
		cl.add_child(_portrait_sprite)

	# Hero name
	var name_lbl := Label.new()
	name_lbl.text     = "Caelan"
	name_lbl.position = Vector2(0, CARD_Y + 125 - CARD_H / 2 + CARD_Y - CARD_Y)
	name_lbl.size     = Vector2(GAME_W, 50)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", Globals.FONT_TITLE)
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", COL_SPEAKER)
	cl.add_child(name_lbl)
	name_lbl.position.y = CARD_Y + 90

	# Role
	var role_lbl := Label.new()
	role_lbl.text     = "Fighter"
	role_lbl.position = Vector2(0, CARD_Y + 125)
	role_lbl.size     = Vector2(GAME_W, 40)
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_override("font", Globals.FONT_MONO)
	role_lbl.add_theme_font_size_override("font_size", 20)
	role_lbl.add_theme_color_override("font_color", COL_BODY)
	cl.add_child(role_lbl)

	# "Press Enter to begin" prompt
	var prompt := Label.new()
	prompt.text     = "Press  Enter  to  begin"
	prompt.position = Vector2(0, GAME_H - 74)
	prompt.size     = Vector2(GAME_W, 60)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", Globals.FONT_TITLE)
	prompt.add_theme_font_size_override("font_size", 32)
	prompt.add_theme_color_override("font_color", COL_PARCHMENT)
	cl.add_child(prompt)

	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(prompt, "modulate:a", 0.3, 0.85)
	tw.tween_property(prompt, "modulate:a", 1.0, 0.85)

	# "Esc — back" hint
	var back_lbl := Label.new()
	back_lbl.text     = "Esc — Back"
	back_lbl.position = Vector2(40, GAME_H - 50)
	back_lbl.add_theme_font_size_override("font_size", 18)
	back_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.42, 0.7))
	cl.add_child(back_lbl)

	# Fade in
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var ov_cl := CanvasLayer.new(); ov_cl.layer = 100; ov_cl.add_child(ov); add_child(ov_cl)
	var fw := create_tween()
	fw.tween_property(ov, "color", Color(0,0,0,0), 0.4)
	fw.tween_callback(ov.queue_free)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var res := load("res://assets/audio/celadune_theme.mp3") as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream    = res
		_music.volume_db = linear_to_db(0.52)
	add_child(_music)
	_music.play()

func _process(_delta: float) -> void:
	if not _ready_to_confirm: return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		_confirm()
	if Input.is_action_just_pressed("ui_cancel"):
		_go_back()

func _confirm() -> void:
	_ready_to_confirm = false
	Globals.selected_hero = "caelan"
	Globals.reset()           # fresh game state
	Globals.selected_hero = "caelan"  # keep after reset
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 200; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Forest.tscn"))

func _go_back() -> void:
	_ready_to_confirm = false
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 200; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -80.0, 0.25)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.25)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Start.tscn"))

func _panel_rect(x: float, y: float, w: float, h: float, border_col: Color, bg_col: Color, thickness: int) -> Control:
	var c := Control.new()
	c.position = Vector2(x, y); c.size = Vector2(w, h)
	var bg := ColorRect.new(); bg.color = bg_col; bg.size = Vector2(w, h); c.add_child(bg)
	for r in _border_rects(w, h, border_col, thickness): c.add_child(r)
	return c

func _border_only(x: float, y: float, w: float, h: float, col: Color, thickness: int) -> Control:
	var c := Control.new(); c.position = Vector2(x, y); c.size = Vector2(w, h)
	for r in _border_rects(w, h, col, thickness): c.add_child(r)
	return c

func _border_rects(w: float, h: float, col: Color, t: int) -> Array:
	var rects := []
	for data in [[0, 0, w, t], [0, h-t, w, t], [0, 0, t, h], [w-t, 0, t, h]]:
		var r := ColorRect.new()
		r.color    = col
		r.position = Vector2(data[0], data[1])
		r.size     = Vector2(data[2], data[3])
		rects.append(r)
	return rects
