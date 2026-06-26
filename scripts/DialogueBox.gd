extends CanvasLayer
class_name DialogueBox
## Reusable parchment-style dialogue panel.
## Add as child of a scene, connect signals, call show_line() to drive it.

signal choice_confirmed(index: int)
signal dismissed

const PANEL_W   := 1320
const PANEL_H   := 528
const PORTRAIT_SZ := 222

# Panel position (centred in 1920×1080)
const PANEL_X   := 300
const PANEL_Y   := 276

# Colour palette matching Phaser
const COL_PARCHMENT  := Color(0.941, 0.875, 0.710)
const COL_BORDER_OUT := Color(0.357, 0.216, 0.090)
const COL_BORDER_IN  := Color(0.855, 0.710, 0.416)
const COL_SPEAKER    := Color(0.290, 0.141, 0.067)
const COL_BODY       := Color(0.169, 0.106, 0.059)
const COL_CHOICE     := Color(0.239, 0.106, 0.031)
const COL_CHOICE_ACT := Color(0.839, 0.710, 0.384, 0.08)

# Typewriter speed (seconds per character)
const TYPEWRITER_DELAY := 0.024

var _overlay:        ColorRect
var _panel:          Panel
var _speaker_label:  Label
var _body_label:     Label
var _portrait_sprite: AnimatedSprite2D
var _options_container: VBoxContainer
var _hint_label:     Label
var _writing_sfx:    AudioStreamPlayer

var _current_text:   String = ""
var _type_index:     int    = 0
var _is_typing:      bool   = false
var _type_timer:     float  = 0.0
var _choices:        Array  = []
var _choice_index:   int    = 0
var _awaiting_choice: bool  = false
var _choice_boxes:   Array  = []

func _ready() -> void:
	layer = 50
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Dim overlay
	_overlay = ColorRect.new()
	_overlay.color       = Color(0.020, 0.027, 0.039, 0.54)
	_overlay.size        = Vector2(1920, 1080)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Parchment panel background
	_panel = Panel.new()
	_panel.position = Vector2(PANEL_X, PANEL_Y)
	_panel.size     = Vector2(PANEL_W, PANEL_H)
	var style := StyleBoxFlat.new()
	style.bg_color           = COL_PARCHMENT
	style.border_color       = COL_BORDER_OUT
	style.set_border_width_all(4)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Inner gold border (decorative ColorRect outline)
	var inner_border := _border_rect(PANEL_X + 9, PANEL_Y + 9, PANEL_W - 18, PANEL_H - 18, COL_BORDER_IN, 2)
	add_child(inner_border)

	# Portrait frame
	var portrait_frame := _border_rect(PANEL_X + 43, PANEL_Y + 36, PORTRAIT_SZ, PORTRAIT_SZ, COL_BORDER_IN, 2)
	add_child(portrait_frame)

	# Portrait clip container — clips the zoomed sprite to exactly the frame rect
	var portrait_clip := Control.new()
	portrait_clip.position     = Vector2(PANEL_X + 43, PANEL_Y + 36)
	portrait_clip.size         = Vector2(PORTRAIT_SZ, PORTRAIT_SZ)
	portrait_clip.clip_children = Control.CLIP_CHILDREN_ONLY
	portrait_clip.z_index      = 1
	add_child(portrait_clip)

	# Portrait sprite — zoomed 6× and offset upward so head/torso fills the frame
	_portrait_sprite = AnimatedSprite2D.new()
	_portrait_sprite.position = Vector2(PORTRAIT_SZ / 2, PORTRAIT_SZ / 2 - 15)
	_portrait_sprite.scale    = Vector2(6.0, 6.0)
	_portrait_sprite.flip_h   = true
	_portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_clip.add_child(_portrait_sprite)

	# Speaker name
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(PANEL_X + 348, PANEL_Y + 48)
	_speaker_label.add_theme_font_override("font", Globals.FONT_TITLE)
	_speaker_label.add_theme_font_size_override("font_size", 40)
	_speaker_label.add_theme_color_override("font_color", COL_SPEAKER)
	add_child(_speaker_label)

	# Body text
	_body_label = Label.new()
	_body_label.position    = Vector2(PANEL_X + 348, PANEL_Y + 115)
	_body_label.size        = Vector2(PANEL_W - 348 - 43, 260)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.add_theme_font_override("font", Globals.FONT_MONO)
	_body_label.add_theme_font_size_override("font_size", 24)
	_body_label.add_theme_color_override("font_color", COL_BODY)
	_body_label.add_theme_constant_override("line_spacing", 12)
	add_child(_body_label)

	# Options container
	_options_container = VBoxContainer.new()
	_options_container.position = Vector2(PANEL_X + 43, PANEL_Y + PANEL_H - 175)
	_options_container.size     = Vector2(PANEL_W - 86, 160)
	_options_container.add_theme_constant_override("separation", 10)
	add_child(_options_container)

	# Hint label — shown only when choices are available, bottom-right of panel
	_hint_label = Label.new()
	_hint_label.text     = "↑↓ to choose   Enter to confirm"
	_hint_label.position = Vector2(PANEL_X + 43, PANEL_Y + PANEL_H - 48)
	_hint_label.size     = Vector2(PANEL_W - 86, 36)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_override("font", Globals.FONT_MONO)
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", Color(0.306, 0.216, 0.125))
	_hint_label.visible = false   # only shown when _awaiting_choice = true
	add_child(_hint_label)

	# Writing SFX
	_writing_sfx = AudioStreamPlayer.new()
	var sfx = load("res://assets/sfx/writing.mp3") as AudioStream
	if sfx:
		if sfx is AudioStreamMP3: (sfx as AudioStreamMP3).loop = true
		_writing_sfx.stream    = sfx
		_writing_sfx.volume_db = linear_to_db(0.45)
	add_child(_writing_sfx)

func _border_rect(x: float, y: float, w: float, h: float, col: Color, thickness: int) -> Control:
	var c := Control.new()
	c.position = Vector2(x, y)
	c.size     = Vector2(w, h)
	# Top
	var t := ColorRect.new(); t.color = col; t.size = Vector2(w, thickness); t.position = Vector2.ZERO; c.add_child(t)
	# Bottom
	var b := ColorRect.new(); b.color = col; b.size = Vector2(w, thickness); b.position = Vector2(0, h - thickness); c.add_child(b)
	# Left
	var l := ColorRect.new(); l.color = col; l.size = Vector2(thickness, h); l.position = Vector2.ZERO; c.add_child(l)
	# Right
	var r := ColorRect.new(); r.color = col; r.size = Vector2(thickness, h); r.position = Vector2(w - thickness, 0); c.add_child(r)
	return c

# ── Public API ────────────────────────────────────────────────────────────────

## Open dialogue with a single line. `portrait_frames` is an AnimatedSprite2D.sprite_frames,
## or null to hide the portrait.
func show_line(speaker: String, text: String, choices: Array, portrait_frames = null) -> void:
	visible = true
	_speaker_label.text = speaker
	_body_label.text    = ""
	_clear_options()
	_choices       = choices.duplicate()
	_choice_index  = 0
	_awaiting_choice = false

	# Portrait
	if portrait_frames and _portrait_sprite:
		_portrait_sprite.sprite_frames = portrait_frames
		_portrait_sprite.play("idle")
		_portrait_sprite.visible = true
	else:
		if _portrait_sprite: _portrait_sprite.visible = false

	# Start typewriter
	_current_text = text
	_type_index   = 0
	_is_typing    = true
	_type_timer   = 0.0
	if _writing_sfx and not _writing_sfx.playing:
		_writing_sfx.play()

func close() -> void:
	visible = false
	_is_typing       = false
	_awaiting_choice = false
	_hint_label.visible = false
	if _writing_sfx and _writing_sfx.playing:
		_writing_sfx.stop()
	dismissed.emit()

# ── Per-frame ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not visible: return

	if _is_typing:
		_type_timer += delta
		while _type_timer >= TYPEWRITER_DELAY and _type_index < _current_text.length():
			_type_timer -= TYPEWRITER_DELAY
			_type_index += 1
			_body_label.text = _current_text.left(_type_index)
		if _type_index >= _current_text.length():
			_finish_typing()

	if Input.is_action_just_pressed("interact"):
		if _is_typing:
			# Skip to end
			_type_index = _current_text.length()
			_body_label.text = _current_text
			_finish_typing()
		elif _awaiting_choice:
			_confirm_choice()
		return

	if _awaiting_choice:
		if Input.is_action_just_pressed("move_up"):
			_choice_index = wrapi(_choice_index - 1, 0, _choices.size())
			_refresh_options()
		if Input.is_action_just_pressed("move_down"):
			_choice_index = wrapi(_choice_index + 1, 0, _choices.size())
			_refresh_options()

func _finish_typing() -> void:
	_is_typing = false
	_body_label.text = _current_text
	if _writing_sfx and _writing_sfx.playing:
		_writing_sfx.stop()
	if _portrait_sprite: _portrait_sprite.stop()
	if _choices.size() > 0:
		_awaiting_choice = true
		_hint_label.visible = true
		_render_options()

func _clear_options() -> void:
	for child in _options_container.get_children():
		child.queue_free()
	_choice_boxes = []

func _render_options() -> void:
	_clear_options()
	for i in range(_choices.size()):
		var panel := PanelContainer.new()
		var style_norm := StyleBoxFlat.new()
		style_norm.bg_color     = Color(0, 0, 0, 0)
		style_norm.border_color = COL_BORDER_IN
		style_norm.set_border_width_all(2)
		var style_sel := StyleBoxFlat.new()
		style_sel.bg_color     = COL_CHOICE_ACT
		style_sel.border_color = COL_BORDER_OUT
		style_sel.set_border_width_all(3)
		panel.add_theme_stylebox_override("panel", style_norm if i != _choice_index else style_sel)

		var lbl := Label.new()
		lbl.text = _choices[i]
		lbl.add_theme_font_override("font", Globals.FONT_MONO)
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.add_theme_color_override("font_color", COL_CHOICE if i == _choice_index else Color(0.431, 0.310, 0.141))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		panel.add_child(lbl)
		_options_container.add_child(panel)
		_choice_boxes.append(panel)

func _refresh_options() -> void:
	for i in range(_choice_boxes.size()):
		var style_norm := StyleBoxFlat.new()
		style_norm.bg_color     = Color(0, 0, 0, 0)
		style_norm.border_color = COL_BORDER_IN
		style_norm.set_border_width_all(2)
		var style_sel := StyleBoxFlat.new()
		style_sel.bg_color     = COL_CHOICE_ACT
		style_sel.border_color = COL_BORDER_OUT
		style_sel.set_border_width_all(3)
		_choice_boxes[i].add_theme_stylebox_override("panel", style_norm if i != _choice_index else style_sel)
		var lbl: Label = _choice_boxes[i].get_child(0)
		lbl.add_theme_color_override("font_color", COL_CHOICE if i == _choice_index else Color(0.431, 0.310, 0.141))

func _confirm_choice() -> void:
	_awaiting_choice = false
	_clear_options()
	choice_confirmed.emit(_choice_index)

## Build a simple SpriteFrames for an NPC portrait (idle strip only).
static func make_portrait_frames(idle_path: String, idle_count: int, frame_w: int = 64, frame_h: int = 64) -> SpriteFrames:
	var tex: Texture2D = load(idle_path)
	if not tex: return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 4.0)
	for i in range(mini(idle_count, 2)):   # 2 frames for talking effect
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame("idle", a)
	return sf
