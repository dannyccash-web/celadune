extends Area2D
## A talkable character. Drop this scene in a room, then write its dialogue in
## the Inspector — no code needed.
##
## Inspector fields:
##   Speaker Name      — the name shown in the text box.
##   Lines             — the conversation, one entry per text-box line.
##   Set Flag On End   — (optional) story flag to set when this talk finishes.
##   Gate Flag         — (optional) if this flag is set AND Lines After is
##                       filled in, the NPC says "Lines After" instead of "Lines"
##                       (use it to change what a character says after an event).
##   Lines After       — (optional) alternate conversation, see Gate Flag.

@export var speaker_name: String = "Villager"
@export var lines: Array[String] = ["Hello, traveler."]
@export var set_flag_on_end: String = ""
@export var gate_flag: String = ""
@export var lines_after: Array[String] = []

var _near := false

@onready var _prompt: Label = $Prompt

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	if _prompt:
		_prompt.visible = false

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_near = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_near = false

func _process(_delta: float) -> void:
	if _prompt:
		_prompt.visible = _near and not Dialogue.active

func _unhandled_input(event: InputEvent) -> void:
	if not _near or Dialogue.active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_talk()

func _talk() -> void:
	var chosen := lines
	if not gate_flag.is_empty() and Globals.has_flag(gate_flag) and not lines_after.is_empty():
		chosen = lines_after
	var flag := set_flag_on_end
	var on_done := func():
		if not flag.is_empty():
			Globals.set_flag(flag)
	Dialogue.start(speaker_name, PackedStringArray(chosen), on_done)
