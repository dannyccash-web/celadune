extends CanvasLayer
## Global dialogue system (autoload as "Dialogue").
##
## Any NPC (or script) calls:
##     Dialogue.start("Elder", ["Welcome, traveler.", "Dark days are upon us."])
## and a text box steps through the lines. Press E or Space to advance (or to
## instantly finish the current line while it's still typing out). Gameplay is
## paused while a conversation is open. Pass a callback to run when it ends:
##     Dialogue.start("Elder", lines, func(): Globals.set_flag("met_elder"))

signal finished

var active := false

var _lines: PackedStringArray = []
var _index := 0
var _on_done := Callable()

var _typing := false
var _char_progress := 0.0
var _armed := false               # ignore the same key press that opened the box

const REVEAL_SPEED := 50.0        # characters per second

@onready var _panel: Panel = Panel.new()
var _name_label: Label
var _body: Label
var _prompt: Label

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep running while the tree is paused
	_build_ui()
	_panel.visible = false

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.13, 0.94)
	style.border_color = Color(0.55, 0.62, 0.78)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)

	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 40
	_panel.offset_right = -40
	_panel.offset_top = -210
	_panel.offset_bottom = -28
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.4))
	vbox.add_child(_name_label)

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 24)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color(0.7, 0.76, 0.9))
	_prompt.text = "[E] continue"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_prompt)

func start(speaker: String, lines: PackedStringArray, on_done := Callable()) -> void:
	if active or lines.is_empty():
		return
	active = true
	_armed = false
	_lines = lines
	_index = 0
	_on_done = on_done
	_name_label.text = speaker
	_name_label.visible = not speaker.is_empty()
	_panel.visible = true
	get_tree().paused = true
	_show_line()

func _show_line() -> void:
	_body.text = _lines[_index]
	_body.visible_characters = 0
	_char_progress = 0.0
	_typing = true
	_prompt.visible = false

func _process(delta: float) -> void:
	if not active:
		return
	if not _armed:
		_armed = true     # arm one frame after opening so the opening press is ignored
	if _typing:
		_char_progress += REVEAL_SPEED * delta
		_body.visible_characters = int(_char_progress)
		if _body.visible_characters >= _body.text.length():
			_finish_typing()

func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	_prompt.text = "[E] continue" if _index < _lines.size() - 1 else "[E] close"
	_prompt.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not active or not _armed:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
		else:
			_advance()

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_end()
	else:
		_show_line()

func _end() -> void:
	active = false
	_panel.visible = false
	get_tree().paused = false
	if _on_done.is_valid():
		_on_done.call()
	finished.emit()
