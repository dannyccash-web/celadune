extends Area2D
## A doorway between two rooms.
##
## Drop one of these in a room, set the target room scene and the name of the
## Marker2D to arrive at in that room. When the player overlaps the door and
## presses "interact" (E / Up), the Game swaps rooms. Set auto_enter = true to
## transition on touch instead (good for screen-edge passages).

@export_file("*.tscn") var target_room: String
@export var target_spawn: String = "Start"
@export var auto_enter: bool = false

var _player_inside: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		if auto_enter:
			_go()

func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside = null

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and not auto_enter and event.is_action_pressed("interact"):
		_go()

func _go() -> void:
	if target_room.is_empty():
		push_warning("Door has no target_room set.")
		return
	var game := _find_game()
	if game:
		game.change_room(load(target_room), target_spawn)

func _find_game() -> Node:
	var n: Node = self
	while n:
		if n.has_method("change_room"):
			return n
		n = n.get_parent()
	return null
