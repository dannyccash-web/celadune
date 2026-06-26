extends CharacterBody2D
## Celadune player controller.
##
## A solid, genre-standard 2D platformer character: run with acceleration,
## variable-height jump, coyote time, jump buffering, double jump, wall slide,
## wall jump, and dash. Abilities are gated through Globals so the game can
## unlock them over time. Tune the constants below to change game feel —
## you should never need to touch the logic to retune movement.

# ── Movement tuning ───────────────────────────────────────────────────────────
const SPEED            := 320.0    # top horizontal run speed (px/s)
const ACCEL            := 2600.0   # ground acceleration (px/s^2)
const FRICTION         := 3200.0   # ground deceleration (px/s^2)
const AIR_ACCEL        := 1800.0   # weaker control in the air
const AIR_FRICTION     := 900.0

const GRAVITY          := 2000.0   # falling acceleration (px/s^2)
const MAX_FALL         := 1100.0   # terminal velocity
const JUMP_VELOCITY    := -720.0   # initial jump impulse
const JUMP_CUT         := 0.45     # release jump early -> keep this fraction of up-velocity

const COYOTE_TIME      := 0.10     # grace period to jump after leaving a ledge
const JUMP_BUFFER      := 0.10     # press jump slightly before landing and it still fires

const DOUBLE_JUMP_VEL  := -640.0

# Wall mechanics
const WALL_SLIDE_SPEED := 140.0    # capped fall speed while hugging a wall
const WALL_JUMP_PUSH   := 360.0    # horizontal kick away from the wall
const WALL_JUMP_VEL    := -700.0

# Dash
const DASH_SPEED       := 720.0
const DASH_TIME        := 0.16
const DASH_COOLDOWN    := 0.45

# ── State ─────────────────────────────────────────────────────────────────────
var _coyote := 0.0
var _buffer := 0.0
var _can_double := false
var _dashing := false
var _dash_timer := 0.0
var _dash_cd := 0.0
var _dash_dir := 1.0
var _facing := 1.0

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	_build_animations()
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta

	if _dashing:
		_process_dash(delta)
		move_and_slide()
		return

	var on_floor := is_on_floor()
	var input_x := Input.get_axis("move_left", "move_right")

	# Gravity
	if not on_floor:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	# Horizontal movement
	var accel := ACCEL if on_floor else AIR_ACCEL
	var friction := FRICTION if on_floor else AIR_FRICTION
	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * SPEED, accel * delta)
		_facing = signf(input_x)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Timers
	if on_floor:
		_coyote = COYOTE_TIME
		_can_double = Globals.has_ability("double_jump")
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	_buffer = maxf(_buffer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER

	# Wall slide
	var on_wall := is_on_wall_only() and not on_floor
	var pushing_wall := on_wall and input_x != 0.0 and signf(input_x) == -signf(get_wall_normal().x)
	if pushing_wall and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = WALL_SLIDE_SPEED

	# Jumping
	if _buffer > 0.0:
		if _coyote > 0.0:
			_do_jump(JUMP_VELOCITY)
		elif on_wall and Globals.has_ability("wall_jump"):
			_do_wall_jump()
		elif _can_double:
			_can_double = false
			_do_jump(DOUBLE_JUMP_VEL)

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Dash
	if Input.is_action_just_pressed("dash") and Globals.has_ability("dash") and _dash_cd <= 0.0:
		_start_dash()

	move_and_slide()
	_update_animation(input_x, on_floor, pushing_wall)

func _do_jump(vel: float) -> void:
	velocity.y = vel
	_buffer = 0.0
	_coyote = 0.0

func _do_wall_jump() -> void:
	var nx := signf(get_wall_normal().x)
	velocity.y = WALL_JUMP_VEL
	velocity.x = nx * WALL_JUMP_PUSH
	_facing = nx
	_buffer = 0.0

func _start_dash() -> void:
	_dashing = true
	_dash_timer = DASH_TIME
	_dash_cd = DASH_COOLDOWN
	_dash_dir = _facing
	sprite.play("jump")

func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
	if _dash_timer <= 0.0:
		_dashing = false

func _update_animation(input_x: float, on_floor: bool, sliding: bool) -> void:
	sprite.flip_h = _facing < 0.0
	if not on_floor:
		sprite.play("jump")
	elif input_x != 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")

# Builds SpriteFrames from the placeholder strips at runtime so no .import-time
# SpriteFrames resource is needed. Swap the textures for your real art later.
func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", "res://assets/sprites/player_idle.png", 2, 4.0, true)
	_add_anim(frames, "run",  "res://assets/sprites/player_run.png",  4, 12.0, true)
	_add_anim(frames, "jump", "res://assets/sprites/player_jump.png", 1, 1.0, false)
	sprite.sprite_frames = frames

func _add_anim(frames: SpriteFrames, name: String, path: String, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	var sheet: Texture2D = load(path)
	var fw := int(sheet.get_width() / count)
	var fh := sheet.get_height()
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(name, atlas)
