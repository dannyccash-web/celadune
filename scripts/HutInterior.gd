extends Node2D

const GAME_W  := 1920
const GAME_H  := 1080
const TILE    := 64
const COLS    := 30
const RY      := 356
const CEIL_Y  := 420
const WALL_BOT := 676
const GY      := 708
const DOOR_X  := 32
const WIN_H   := 128
const WIN_Y   := 484
const WALL_MID_Y := 548
const EXIT_R  := 90.0

func _room_name() -> String:
	match Globals.interior_config_id:
		"bram_smithy":    return "Bram Alder's Smithy"
		"padrig_tavern":  return "Padrig's Tavern"
		"teren_house":    return "Teren Vale's House"
		"ysra_house":     return "Ysra Thorn's House"
		"oswin_shop":     return "Oswin's Shop"
		"rilla_house":    return "Rilla's House"
	return "Mirelle's Farmhouse"

func _return_scene() -> String:
	match Globals.interior_config_id:
		"bram_smithy", "padrig_tavern", "teren_house", "ysra_house", "oswin_shop", "rilla_house":
			return "City"
	return "Forest"

func _return_x() -> float:
	match Globals.interior_config_id:
		"bram_smithy":   return 909.0
		"padrig_tavern": return 1611.0
		"teren_house":   return 2144.0
		"ysra_house":    return 2700.0
		"oswin_shop":    return 3303.0
		"rilla_house":   return 3757.0
	return 2274.0

func _ready() -> void:
	# STEP 1: background only
	var cl := CanvasLayer.new(); cl.layer = -1; add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.02)
	bg.size  = Vector2(GAME_W, GAME_H)
	cl.add_child(bg)

	# STEP 2: room tiles
	_build_room()

	# STEP 3: status label so we can see progress
	var info_cl := CanvasLayer.new(); info_cl.layer = 50; add_child(info_cl)
	var lbl := Label.new()
	lbl.text = "Room built — press E to exit"
	lbl.position = Vector2(600, 20)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	info_cl.add_child(lbl)

	set_process(true)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		Globals.from_transition = true
		Globals.spawn_x = _return_x()
		get_tree().change_scene_to_file("res://scenes/" + _return_scene() + ".tscn")

func _build_room() -> void:
	var P := "res://assets/props/interior/"
	var roof_tex  := _tex(P + "house_roof.png")
	var wall_tex  := _tex(P + "house_wall.png")
	var wbase_tex := _tex(P + "wall_base.png")
	var floor1    := _tex(P + "floor_tile_1.png")
	var floor2    := _tex(P + "floor_tile_2.png")
	var door_tex  := _tex(P + "door_open.png")
	var win_tex   := _tex(P + "blue_window_open.png")

	_fill_row(roof_tex,  RY,       TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y,       TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 64,  TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 128, TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 192, TILE, 64, 2)
	_fill_row(wbase_tex, WALL_BOT,     TILE, 32, 2)

	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		if not t: continue
		var sp := Sprite2D.new()
		sp.texture = t; sp.centered = false
		sp.position = Vector2(c * TILE, GY)
		sp.scale = Vector2(float(TILE) / float(t.get_width()), 16.0 / float(t.get_height()))
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 2; add_child(sp)

	for wc in [5, 15, 25]:
		var sky := ColorRect.new()
		sky.color = Color(0.78, 0.87, 0.91)
		sky.position = Vector2(wc * TILE, WIN_Y)
		sky.size = Vector2(TILE, WIN_H); sky.z_index = 1; add_child(sky)
		if win_tex:
			var ws := _sprite(win_tex, wc * TILE, WIN_Y, TILE, WIN_H)
			ws.z_index = 4; add_child(ws)

	if door_tex:
		var ds := _sprite(door_tex, DOOR_X - TILE * 0.5, GY - 76.0, TILE, 92.0)
		ds.z_index = 5; add_child(ds)

func _tex(path: String) -> Texture2D:
	var t := load(path)
	if t is Texture2D: return t
	return null

func _sprite(tex: Texture2D, x: float, y: float, w: float, h: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.position = Vector2(x, y)
	sp.scale = Vector2(w / float(tex.get_width()), h / float(tex.get_height()))
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _fill_row(tex: Texture2D, y: float, tw: float, th: float, z: int) -> void:
	if not tex: return
	for c in range(COLS):
		var sp := _sprite(tex, c * tw, y, tw, th)
		sp.z_index = z; add_child(sp)
