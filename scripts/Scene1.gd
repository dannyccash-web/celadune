extends Node2D
## Scene1 — the first overworld scene (Millhaven outskirts).
##
## Layout (Y increases downward, origin at top-left):
##
##   0                    ┌─────────────────────────┐
##                        │  Scene_Background.png   │  z = -10
##                        │  (1920 × 1080, fills)   │
##                        │                         │
##   888  ────────────────┤  Ground_Tile_Green_2    │  z = -2  (visual depth, behind all)
##   952  ────────────────┤  Ground_Tile_Green_1    │  z =  2  (player walks on top of this)
##  1016  ────────────────┤  Ground_Tile_Black      │  z = 20  (UI strip, always in front)
##  1080                  └─────────────────────────┘
##
##  Ground collision: top of Green_1 row = y 952
##  Building base:   1080 - 150 = 930  (sits 22px above ground for depth)

const GAME_W := 1920
const GAME_H := 1080
const TILE   := 64
const COLS   := GAME_W / TILE   # 30

const ROW_BLACK  := GAME_H - TILE       # 1016
const ROW_GREEN1 := GAME_H - TILE * 2  # 952
const ROW_GREEN2 := GAME_H - TILE * 3  # 888

const GROUND_Y        := ROW_GREEN1   # 952
const BUILDING_BASE_Y := GAME_H - 150 # 930

const BG_PATH       := "res://assets/bg/scene_background.png"
const TILE_BLACK    := "res://assets/tiles/ground_tile_black.png"
const TILE_GREEN1   := "res://assets/tiles/ground_tile_green_1.png"
const TILE_GREEN2   := "res://assets/tiles/ground_tile_green_2.png"
const BUILDING_PATH := "res://assets/buildings/forest_hut/building.png"
const PLAYER_SCENE  := "res://scenes/Player.tscn"

# Oswin's shop door — centre of the building sprite, ground level
const DOOR_WORLD_X := 960.0
const DOOR_RADIUS  := 110.0

var _menu:               Node             = null
var _door_player_inside: bool             = false
var _door_tip:           Label            = null
var _player:             CharacterBody2D  = null

func _ready() -> void:
	_build_background()
	_build_ground()
	_build_building()
	_build_physics()
	_spawn_player()
	_build_door_trigger()
	_spawn_menu()

# ── Background ────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var tex := load(BG_PATH) as Texture2D
	if not tex:
		push_warning("Scene1: missing " + BG_PATH)
		var fallback := ColorRect.new()
		fallback.color   = Color(0.08, 0.12, 0.08)
		fallback.size    = Vector2(GAME_W, GAME_H)
		fallback.z_index = -10
		add_child(fallback)
		return
	var sp := Sprite2D.new()
	sp.texture        = tex
	sp.centered       = false
	sp.position       = Vector2.ZERO
	sp.z_index        = -10
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sp)

# ── Ground tile rows ──────────────────────────────────────────────────────────

func _build_ground() -> void:
	_tile_row(TILE_GREEN2, ROW_GREEN2, -2)
	_tile_row(TILE_GREEN1, ROW_GREEN1,  2)
	_tile_row(TILE_BLACK,  ROW_BLACK,  20)

func _tile_row(path: String, row_y: int, z: int) -> void:
	var tex := load(path) as Texture2D
	if not tex:
		push_warning("Scene1: missing tile " + path)
		return
	for col in range(COLS):
		var sp := Sprite2D.new()
		sp.texture        = tex
		sp.centered       = false
		sp.position       = Vector2(col * TILE, row_y)
		sp.z_index        = z
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sp)

# ── Building ──────────────────────────────────────────────────────────────────

func _build_building() -> void:
	var tex := load(BUILDING_PATH) as Texture2D
	if not tex:
		push_warning("Scene1: missing building " + BUILDING_PATH)
		return
	var sp := Sprite2D.new()
	sp.texture  = tex
	sp.centered = false
	var bx := (GAME_W - tex.get_width()) / 2.0
	var by := BUILDING_BASE_Y - tex.get_height()
	sp.position       = Vector2(bx, by)
	sp.z_index        = 0
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sp)

# ── Physics ───────────────────────────────────────────────────────────────────

func _build_physics() -> void:
	var ground := StaticBody2D.new()
	var gs     := CollisionShape2D.new()
	var gr     := RectangleShape2D.new()
	gr.size        = Vector2(GAME_W * 2.0, 300.0)
	gs.position    = Vector2(GAME_W / 2.0, GROUND_Y + 150.0)
	gs.shape       = gr
	ground.add_child(gs)
	add_child(ground)

	var lw := StaticBody2D.new()
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size     = Vector2(32.0, GAME_H * 2.0)
	ls.position = Vector2(-16.0, GAME_H / 2.0)
	ls.shape    = lr
	lw.add_child(ls)
	add_child(lw)

	var rw := StaticBody2D.new()
	var rs := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size     = Vector2(32.0, GAME_H * 2.0)
	rs.position = Vector2(GAME_W + 16.0, GAME_H / 2.0)
	rs.shape    = rr
	rw.add_child(rs)
	add_child(rw)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var ps := load(PLAYER_SCENE) as PackedScene
	if not ps:
		push_warning("Scene1: missing " + PLAYER_SCENE)
		return
	_player = ps.instantiate() as CharacterBody2D
	var spawn_x: float = Globals.spawn_x if Globals.from_transition else 300.0
	Globals.from_transition = false
	_player.position = Vector2(spawn_x, GROUND_Y - 64.0)
	_player.z_index  = 5
	add_child(_player)

	var cam := Camera2D.new()
	cam.limit_left                 = 0
	cam.limit_right                = GAME_W
	cam.limit_top                  = 0
	cam.limit_bottom               = GAME_H
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 6.0
	_player.add_child(cam)

# ── Door trigger (Oswin's Shop) ───────────────────────────────────────────────

func _build_door_trigger() -> void:
	var area := Area2D.new()
	area.position = Vector2(DOOR_WORLD_X, GROUND_Y)
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new()
	ci.radius = DOOR_RADIUS
	cs.shape  = ci
	area.add_child(cs)
	add_child(area)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_door_player_inside = true
			if _door_tip: _door_tip.visible = true)

	area.body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_door_player_inside = false
			if _door_tip: _door_tip.visible = false)

	# Hint label positioned in world space above the door
	_door_tip = Label.new()
	_door_tip.text    = "E  —  Enter Oswin's Shop"
	_door_tip.position = Vector2(DOOR_WORLD_X - 145, GROUND_Y - 100)
	_door_tip.visible  = false
	_door_tip.z_index  = 30
	_door_tip.add_theme_font_size_override("font_size", 20)
	_door_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_door_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_door_tip.add_theme_constant_override("shadow_offset_x", 2)
	_door_tip.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_door_tip)

# ── Menu ──────────────────────────────────────────────────────────────────────

func _spawn_menu() -> void:
	var MenuScript: Variant = load("res://scripts/MenuPanel.gd")
	if not MenuScript:
		push_warning("Scene1: MenuPanel.gd not found")
		return
	_menu = MenuScript.new()
	add_child(_menu)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"):
		if _menu:
			if _menu.visible:
				_menu.call("close")
			else:
				_menu.call("open")
		get_viewport().set_input_as_handled()
		return

	if _door_player_inside and not (_menu and _menu.visible):
		if event.is_action_pressed("interact"):
			_enter_oswin_shop()
			get_viewport().set_input_as_handled()

# ── Room transitions ──────────────────────────────────────────────────────────

## Called by any Door.gd node placed as a child of this scene.
func change_room(room_scene: PackedScene, spawn_name: String) -> void:
	Globals.target_spawn      = spawn_name
	Globals.return_scene_path = "res://scenes/Scene1.tscn"
	get_tree().change_scene_to_packed(room_scene)

func _enter_oswin_shop() -> void:
	Globals.interior_config_id = "oswin_shop"
	Globals.return_scene_path  = "res://scenes/Scene1.tscn"
	Globals.spawn_x            = DOOR_WORLD_X
	Globals.from_transition    = true

	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0)
	ov.size  = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(ov)
	add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0, 0, 0, 1), 0.35)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/HutInterior.tscn"))
