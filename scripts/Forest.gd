extends Node2D

# ── World dimensions ──────────────────────────────────────────────────────────
const WORLD_WIDTH   := 5000
const VIEWPORT_W    := 1280
const VIEWPORT_H    := 720
const GROUND_Y      := 620   # Y position of ground surface

# Background images are 3800×2400 (or 1900×1200 for sky).
# We scale them to fill viewport height (720px) → scale ≈ 0.30
const BG_SCALE      := 0.30

# ── Parallax layer configs ────────────────────────────────────────────────────
# [path, scroll_scale_x, y_offset_fraction]
# scroll_scale: 0 = fixed horizon, 1 = moves 1:1 with camera (foreground)
const BG_LAYERS := [
	["res://assets/bg/forest_sky.png",      0.05, 0.0],
	["res://assets/bg/forest_mountain.png", 0.15, 0.0],
	["res://assets/bg/forest_back.png",     0.30, 0.0],
	["res://assets/bg/forest_mid.png",      0.55, 0.05],
	["res://assets/bg/forest_short.png",    0.75, 0.10],
]

var _player: CharacterBody2D
var _camera: Camera2D

func _ready() -> void:
	_build_parallax()
	_build_ground()
	_spawn_player()
	_build_camera()

# ── Parallax background ───────────────────────────────────────────────────────
func _build_parallax() -> void:
	var pb := ParallaxBackground.new()
	pb.z_index = -10
	add_child(pb)

	for cfg in BG_LAYERS:
		var path: String  = cfg[0]
		var scroll: float = cfg[1]
		var y_frac: float = cfg[2]

		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(scroll, 0.0)
		pb.add_child(layer)

		var tex: Texture2D = load(path)
		if tex == null:
			continue

		# Scale image so its height fills the viewport
		var img_w := float(tex.get_width())
		var img_h := float(tex.get_height())
		var scale_y := float(VIEWPORT_H) / img_h
		var scaled_w := img_w * scale_y

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.scale = Vector2(scale_y, scale_y)
		sprite.position = Vector2(0.0, VIEWPORT_H * y_frac)
		layer.add_child(sprite)

		# Mirror so the layer tiles horizontally when the camera scrolls past it
		layer.motion_mirroring = Vector2(scaled_w, 0.0)

# ── Ground ────────────────────────────────────────────────────────────────────
func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	add_child(ground)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(WORLD_WIDTH * 2.0, 60.0)
	shape.shape = rect
	shape.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 30.0)
	ground.add_child(shape)

	# Visual ground strip (dark green)
	var vis := ColorRect.new()
	vis.color = Color(0.13, 0.22, 0.10)
	vis.size  = Vector2(WORLD_WIDTH * 2.0, 60.0)
	vis.position = Vector2(-WORLD_WIDTH / 2.0, GROUND_Y)
	ground.add_child(vis)

# ── Player ────────────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	_player = player_scene.instantiate()
	_player.position = Vector2(300.0, GROUND_Y - 10.0)
	add_child(_player)

# ── Camera ────────────────────────────────────────────────────────────────────
func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left   = 0
	_camera.limit_right  = WORLD_WIDTH
	_camera.limit_top    = -200
	_camera.limit_bottom = GROUND_Y + 60

	# Smooth follow
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 5.0

	_player.add_child(_camera)
