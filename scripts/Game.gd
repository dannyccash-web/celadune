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

# A copy of world/MapData.txt. Godot's web export does not always pack loose
# .txt files, so if the res:// file is missing at runtime we write this copy to
# user:// and load that instead. world/MapData.txt remains the source of truth
# you edit (in the MetSys Map editor); keep this in sync if you change the map by
# hand. When the res:// file IS packed, this fallback is never used.
const EMBEDDED_MAP := "$ln;Overworld\n[0,0,0]\n1,-1,-1,-1|||uid://celadunerm1\n[1,0,0]\n-1,-1,1,-1|||uid://celadunerm2\n"

func _ready() -> void:
	# Make sure the world map is loaded (packed res:// file, or user:// fallback).
	_ensure_world_map()

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

func _ensure_world_map() -> void:
	var res_path := "res://world/MapData.txt"
	if FileAccess.file_exists(res_path):
		print("[Celadune] Map data loaded from packed res:// file.")
		MetSys.load_map_data(res_path)
		return
	# Fallback for exported builds where the loose .txt wasn't packed.
	var user_path := "user://MapData.txt"
	var f := FileAccess.open(user_path, FileAccess.WRITE)
	if f:
		f.store_string(EMBEDDED_MAP)
		f.close()
	print("[Celadune] Map data loaded from user:// fallback copy.")
	MetSys.load_map_data(user_path)

func _on_room_loaded() -> void:
	var room := MetSys.get_current_room_instance()
	var cam: Camera2D = player.get_node_or_null(^"Camera2D")
	if room and cam:
		room.adjust_camera_limits(cam)
