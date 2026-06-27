extends Node2D
## Scene1 — the first overworld scene.
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
##  Building base:   1080 - 150 = 930  (sits 22px above ground collision for depth)

const GAME_W := 1920
const GAME_H := 1080
const TILE   := 64
const COLS   := GAME_W / TILE   # 30

# Row Y positions (top edge of each tile row)
const ROW_BLACK  := GAME_H - TILE       # 1016
const ROW_GREEN1 := GAME_H - TILE * 2  # 952
const ROW_GREEN2 := GAME_H - TILE * 3  # 888

# Physics ground sits at the top surface of Green_1
const GROUND_Y := ROW_GREEN1   # 952

# Buildings have their base (bottom edge) here
const BUILDING_BASE_Y := GAME_H - 150  # 930

# Asset paths
const BG_PATH       := "res://assets/bg/scene_background.png"
const TILE_BLACK    := "res://assets/tiles/ground_tile_black.png"
const TILE_GREEN1   := "res://assets/tiles/ground_tile_green_1.png"
const TILE_GREEN2   := "res://assets/tiles/ground_tile_green_2.png"
const BUILDING_PATH := "res://assets/buildings/forest_hut/building.png"
const PLAYER_SCENE  := "res://scenes/Player.tscn"

func _ready() -> void:
	_build_background()
	_build_ground()
	_build_building()
	_build_physics()
	_spawn_player()

# ── Background ────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var tex := load(BG_PATH) as Texture2D
	if not tex:
		push_warning("Scene1: missing " + BG_PATH)
		var fallback := ColorRect.new()
		fallback.color = Color(0.08, 0.12, 0.08)
		fallback.size  = Vector2(GAME_W, GAME_H)
		fallback.z_index = -10
		add_child(fallback)
		return
	var sp := Sprite2D.new()
	sp.texture  = tex
	sp.centered = false
	sp.position = Vector2.ZERO
	sp.z_index  = -10
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sp)

# ── Ground tile rows ──────────────────────────────────────────────────────────

func _build_ground() -> void:
	# Green_2: furthest back, gives visual depth behind buildings/player
	_tile_row(TILE_GREEN2, ROW_GREEN2, -2)
	# Green_1: player walks on top of this row
	_tile_row(TILE_GREEN1, ROW_GREEN1,  2)
	# Black: UI strip, always drawn in front of everything
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
	# Centre horizontally; bottom edge sits at BUILDING_BASE_Y
	var bx := (GAME_W - tex.get_width()) / 2.0
	var by := BUILDING_BASE_Y - tex.get_height()
	sp.position       = Vector2(bx, by)
	sp.z_index        = 0   # in front of Green_2, behind player
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sp)

# ── Physics ───────────────────────────────────────────────────────────────────

func _build_physics() -> void:
	# Solid ground — top surface = GROUND_Y
	var ground := StaticBody2D.new()
	var gs     := CollisionShape2D.new()
	var gr     := RectangleShape2D.new()
	gr.size        = Vector2(GAME_W * 2.0, 300.0)
	gs.position    = Vector2(GAME_W / 2.0, GROUND_Y + 150.0)
	gs.shape       = gr
	ground.add_child(gs)
	add_child(ground)

	# Left boundary wall
	var lw := StaticBody2D.new()
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size     = Vector2(32.0, GAME_H * 2.0)
	ls.position = Vector2(-16.0, GAME_H / 2.0)
	ls.shape    = lr
	lw.add_child(ls)
	add_child(lw)

	# Right boundary wall
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
	var player := ps.instantiate() as CharacterBody2D
	# Spawn left of centre, just above ground
	player.position = Vector2(300.0, GROUND_Y - 64.0)
	player.z_index  = 5
	add_child(player)

	var cam := Camera2D.new()
	cam.limit_left               = 0
	cam.limit_right              = GAME_W
	cam.limit_top                = 0
	cam.limit_bottom             = GAME_H
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 6.0
	player.add_child(cam)
