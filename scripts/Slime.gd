extends Node2D
## Slime enemy — patrols a range, damages player on contact.
## Set patrol_min_x, patrol_max_x, and ground_y before adding to scene.

signal hit_player

const FRAME_W    := 32
const FRAME_H    := 32
const FRAME_ROW  := 0     # row 0 = idle/walk animation
const FRAME_CNT  := 4     # use first 4 frames
const ANIM_FPS   := 6.0
const SLIME_SCALE := 3.0

const WALK_SPEED := 55.0
const HIT_RADIUS := 36.0   # world pixels (before scale) for contact
const HIT_COOLDOWN := 1.2  # seconds between hits

var patrol_min_x: float = 0.0
var patrol_max_x: float = 400.0
var ground_y:     float = 838.0
var slime_sheet:  String = "res://assets/enemies/slime_green.png"

var _sprite:      AnimatedSprite2D
var _area:        Area2D
var _dir:         int   = 1
var _pause_timer: float = 0.0
var _hit_timer:   float = 0.0
var _hp:          int   = 3

func _ready() -> void:
	z_index = 8
	_build_sprite()
	_build_area()

func _build_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(SLIME_SCALE, SLIME_SCALE)

	var tex: Texture2D = load(slime_sheet)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", ANIM_FPS)
	for i in range(FRAME_CNT):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * FRAME_W, FRAME_ROW * FRAME_H, FRAME_W, FRAME_H)
		sf.add_frame("walk", a)
	_sprite.sprite_frames = sf
	_sprite.play("walk")
	_sprite.flip_h = true   # start facing right
	add_child(_sprite)

func _build_area() -> void:
	_area = Area2D.new()
	var col := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = HIT_RADIUS
	col.shape  = circ
	_area.add_child(col)
	_area.body_entered.connect(_on_body_entered)
	add_child(_area)

func _process(delta: float) -> void:
	if _hit_timer > 0.0:
		_hit_timer -= delta

	if _pause_timer > 0.0:
		_pause_timer -= delta
		return

	position.x += _dir * WALK_SPEED * delta
	_sprite.flip_h = _dir > 0

	if _dir > 0 and position.x >= patrol_max_x:
		position.x = patrol_max_x
		_dir = -1
		_pause_timer = randf_range(0.4, 1.4)
	elif _dir < 0 and position.x <= patrol_min_x:
		position.x = patrol_min_x
		_dir = 1
		_pause_timer = randf_range(0.4, 1.4)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and _hit_timer <= 0.0:
		_hit_timer = HIT_COOLDOWN
		hit_player.emit()

## Called by scene when player attacks (attack hitbox check is done in scene).
## Returns true if slime dies.
func take_hit() -> bool:
	_hp -= 1
	# Flash white briefly
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color(2, 2, 2, 1), 0.06)
	tw.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.10)
	if _hp <= 0:
		var tw2 := create_tween()
		tw2.tween_property(_sprite, "modulate:a", 0.0, 0.22)
		tw2.tween_callback(queue_free)
		return true
	return false
