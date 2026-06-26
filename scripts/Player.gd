extends CharacterBody2D
## Celadune player controller — Caelan.
##
## Platformer controller: run/accelerate, variable-height jump, coyote time,
## jump buffering, double jump, wall slide, wall jump, dash, attack.
## Abilities gated through Globals.abilities.
## Signals: jumped, attacked — scenes connect these for SFX / reactions.

signal jumped
signal attacked

# ── Movement constants ────────────────────────────────────────────────────────
const SPEED        := 320.0
const ACCEL        := 2600.0
const FRICTION     := 3200.0
const AIR_ACCEL    := 1800.0
const AIR_FRICTION := 900.0

const GRAVITY      := 2000.0
const MAX_FALL     := 1100.0
const JUMP_VELOCITY    := -720.0
const JUMP_CUT         := 0.45
const COYOTE_TIME      := 0.10
const JUMP_BUFFER      := 0.10
const DOUBLE_JUMP_VEL  := -640.0

const WALL_SLIDE_SPEED := 140.0
const WALL_JUMP_PUSH   := 360.0
const WALL_JUMP_VEL    := -700.0

const DASH_SPEED    := 720.0
const DASH_TIME     := 0.16
const DASH_COOLDOWN := 0.45

# Attack
const ATTACK_DURATION := 0.35   # seconds the attack state lasts

# Caelan sprite sheet: each frame is 300 × 576 px (RGBA), or 300 × 192 (RGB small sheets)
const FRAME_W      := 300
const FRAME_H_TALL := 576   # RGBA multi-frame sheets
const FRAME_H_SMALL := 192  # RGB small-frame sheets
const SPRITE_SCALE := 0.32  # 300 * 0.32 ≈ 96 px display width

# ── State ─────────────────────────────────────────────────────────────────────
var _coyote    := 0.0
var _buffer    := 0.0
var _can_double := false
var _dashing   := false
var _dash_timer := 0.0
var _dash_cd   := 0.0
var _dash_dir  := 1.0
var _facing    := 1.0
var _attacking := false
var _attack_timer := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	_build_animations()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta

	# Attack state consumes the frame — still allow movement underneath
	if _attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attacking = false
		# Apply gravity while attacking
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		move_and_slide()
		return

	if _dashing:
		_process_dash(delta)
		move_and_slide()
		return

	var on_floor := is_on_floor()
	var input_x := Input.get_axis("move_left", "move_right")

	# Gravity
	if not on_floor:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	# Horizontal
	var accel   := ACCEL   if on_floor else AIR_ACCEL
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

	# Jump
	if _buffer > 0.0:
		if _coyote > 0.0:
			_do_jump(JUMP_VELOCITY)
		elif on_wall and Globals.has_ability("wall_jump"):
			_do_wall_jump()
		elif _can_double:
			_can_double = false
			_do_jump(DOUBLE_JUMP_VEL)

	# Variable height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Dash
	if Input.is_action_just_pressed("dash") and Globals.has_ability("dash") and _dash_cd <= 0.0:
		_start_dash()

	# Attack
	if Input.is_action_just_pressed("attack") and Globals.has_ability("attack") and not _attacking:
		_start_attack()

	move_and_slide()
	_update_animation(input_x, on_floor, pushing_wall)

func _do_jump(vel: float) -> void:
	var bonus := Globals.get_jump_bonus()
	velocity.y = vel - bonus * 20.0  # each jump bonus point adds 20 px/s upward
	_buffer = 0.0
	_coyote = 0.0
	jumped.emit()

func _do_wall_jump() -> void:
	var nx := signf(get_wall_normal().x)
	velocity.y = WALL_JUMP_VEL
	velocity.x = nx * WALL_JUMP_PUSH
	_facing = nx
	_buffer = 0.0
	jumped.emit()

func _start_dash() -> void:
	_dashing    = true
	_dash_timer = DASH_TIME
	_dash_cd    = DASH_COOLDOWN
	_dash_dir   = _facing
	sprite.play("jump")

func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(_dash_dir * DASH_SPEED, 0.0)
	if _dash_timer <= 0.0:
		_dashing = false

func _start_attack() -> void:
	_attacking    = true
	_attack_timer = ATTACK_DURATION
	velocity.x    = 0.0      # brief stop during swing
	sprite.play("attack")
	attacked.emit()

func _update_animation(input_x: float, on_floor: bool, sliding: bool) -> void:
	sprite.flip_h = _facing < 0.0
	if _attacking:
		pass  # attack anim already set
	elif not on_floor:
		sprite.play("jump")
	elif input_x != 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")

# ── Animation builder ─────────────────────────────────────────────────────────
## Each Caelan RGBA sheet is a horizontal strip: frame width = 300, height = 576.
## Each RGB sheet (death, attack, etc.): frame width = 300, height = 192.

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	# Primary movement animations (RGBA tall sheets)
	_add_anim_sheet(frames, "idle",   "res://assets/characters/caelan/idle.png",    3,  4.0, true,  FRAME_H_TALL)
	_add_anim_sheet(frames, "run",    "res://assets/characters/caelan/run.png",     18, 14.0, true,  FRAME_H_TALL)
	_add_anim_sheet(frames, "jump",   "res://assets/characters/caelan/jump.png",    9,  10.0, false, FRAME_H_TALL)
	_add_anim_sheet(frames, "walk",   "res://assets/characters/caelan/walk.png",    18, 10.0, true,  FRAME_H_TALL)

	# Action animations (RGB small sheets, 300×192)
	_add_anim_sheet(frames, "attack", "res://assets/characters/caelan/attack.png",  3,  10.0, false, FRAME_H_SMALL)
	_add_anim_sheet(frames, "death",  "res://assets/characters/caelan/death.png",   3,  6.0,  false, FRAME_H_SMALL)

	# "rise" = death played backwards — we re-add frames in reverse order
	_add_anim_reversed(frames, "rise", "res://assets/characters/caelan/death.png", 3, 5.0, FRAME_H_SMALL)

	sprite.sprite_frames = frames

func _add_anim_sheet(frames: SpriteFrames, anim: String, path: String,
		count: int, fps: float, loop: bool, frame_h: int) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	var sheet: Texture2D = load(path)
	if not sheet:
		push_warning("Player: missing sprite " + path)
		# Add a blank frame so the animation at least exists
		frames.add_frame(anim, PlaceholderTexture2D.new())
		return
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas  = sheet
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, frame_h)
		frames.add_frame(anim, atlas)

func _add_anim_reversed(frames: SpriteFrames, anim: String, path: String,
		count: int, fps: float, frame_h: int) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, false)
	var sheet: Texture2D = load(path)
	if not sheet:
		frames.add_frame(anim, PlaceholderTexture2D.new())
		return
	for i in range(count - 1, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas  = sheet
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, frame_h)
		frames.add_frame(anim, atlas)
