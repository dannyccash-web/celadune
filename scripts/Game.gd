extends Node2D
## Main game node. Owns the persistent Player and swaps room scenes in and out.
##
## Rooms are plain scenes under scenes/rooms/. Each room contains Marker2D nodes
## that act as spawn points; a Door tells the Game which room scene to load and
## which marker to appear at. The Player lives here (not inside a room) so it
## survives transitions.

@export var starting_room: PackedScene

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player

var current_room: Node2D

func _ready() -> void:
	if starting_room:
		_load_room(starting_room)

# Called by doors. Defers the actual swap so we're not freeing a body mid-collision.
func change_room(room_scene: PackedScene, spawn_name: String) -> void:
	Globals.target_spawn = spawn_name
	_load_room.call_deferred(room_scene)

func _load_room(room_scene: PackedScene) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	current_room = room_scene.instantiate()
	world.add_child(current_room)

	# Place the player at the requested spawn marker (fallback: first marker / origin).
	var spawn := current_room.get_node_or_null(NodePath(Globals.target_spawn))
	if spawn == null:
		spawn = current_room.get_node_or_null(^"Start")
	if spawn:
		player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
