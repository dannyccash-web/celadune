extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
## Main game node — now driven by MetroidvaniaSystem (MetSys).
##
## The world is defined on a grid in world/MapData.txt (edit it visually with the
## MetSys Map Editor in Godot). Each grid cell is assigned a room scene. When the
## player walks off the edge of a room into an adjacent cell that belongs to a
## different scene, MetSys fires a room change and the ScrollingRoomTransitions
## module swaps the room in and scrolls the camera. No hand-placed doors needed —
## to add an area you draw a cell, assign a scene, and open the shared edge.

const START_ROOM := "res://scenes/rooms/Room1.tscn"

func _ready() -> void:
	# Start from a clean MetSys state (matters when returning from a menu later).
	MetSys.reset_state()
	MetSys.set_save_data()

	# Tell MetSys which node is the player; it will track its position each frame.
	set_player($Player)

	# Keep the camera fitted to each room as we enter it.
	room_loaded.connect(_on_room_loaded)

	# Load the starting room, then drop the player on its Start marker.
	await load_room(START_ROOM)
	var start := map.get_node_or_null(^"Start")
	if start:
		player.global_position = start.global_position

	# Enable edge-based room transitions with a scrolling effect.
	add_module("ScrollingRoomTransitions.gd")

func _on_room_loaded() -> void:
	var room := MetSys.get_current_room_instance()
	var cam: Camera2D = player.get_node_or_null(^"Camera2D")
	if room and cam:
		room.adjust_camera_limits(cam)
