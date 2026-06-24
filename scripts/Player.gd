extends CharacterBody2D

# ── Constants ────────────────────────────────────────────────────────────────
const SPEED        := 260.0
const RUN_SPEED    := 420.0
const JUMP_VELOCITY := -580.0
const GRAVITY      := 1400.0

# Caelan sprite sheet dimensions
const FRAME_W := 100
const FRAME_H := 64
const SPRITE_SCALE := 2.5

# ── Nodes ────────────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision

# ── State ────────────────────────────────────────────────────────────────────
var _attacking := false
var _attack_timer := 0.0
const ATTACK_DURATION := 0.375  # 3 frames at 8fps

# ── Setup ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_animations()
	_build_collision()
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	# Sprites face LEFT by default; start facing right
	sprite.flip_h = true
	sprite.play("idle")

func _build_collision() -> void:
	var cap := CapsuleShape2D.new()
	cap.radius = 14.0
	cap.height = 48.0
	collision.shape = cap
	# Center the capsule on the sprite's body
	collision.position = Vector2(FRAME_W / 2.0, FRAME_H / 2.0 + 4)

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	# [name, path, frame_count, fps, loop]
	var defs := [
		["idle",   "res://assets/characters/caelan/idle.png",   1,  1.0,  true],
		["walk",   "res://assets/characters/caelan/walk.png",   6,  10.0, true],
		["run",    "res://assets/characters/caelan/run.png",    6,  12.0, true],
		["jump",   "res://assets/characters/caelan/jump.png",   3,  10.0, false],
		["attack", "res://assets/characters/caelan/attack.png", 3,  8.0,  false],
		["death",  "res://assets/characters/caelan/death.png",  3,  5.0,  false],
	]

	for d in defs:
		_add_strip_anim(frames, d[0], d[1], d[2], d[3], d[4])

	sprite.sprite_frames = frames

func _add_strip_anim(
		frames: SpriteFrames,
		anim_name: String,
		path: String,
		count: int,
		fps: float,
		loop: bool
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, fps)
	var tex: Texture2D = load(path)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame(anim_name, atlas)

# ── Physics ───────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Attack cooldown
	if _attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attacking = false

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _attacking:
		velocity.y = JUMP_VELOCITY

	# Attack
	if Input.is_action_just_pressed("attack") and is_on_floor() and not _attacking:
		_attacking = true
		_attack_timer = ATTACK_DURATION
		sprite.play("attack")
		sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

	# Horizontal movement
	var run := Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right") == false \
			or Input.is_action_pressed("move_right") and Input.is_action_pressed("move_left") == false
	# (run modifier key could be added later; for now walk = run at reduced speed)
	var dir := Input.get_axis("move_left", "move_right")

	if not _attacking:
		if dir != 0.0:
			velocity.x = dir * SPEED
			# Sprites default to facing LEFT; flip_h = true → facing RIGHT
			sprite.flip_h = dir > 0.0
			if is_on_floor():
				sprite.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 10.0 * delta)
			if is_on_floor() and not sprite.animation == "idle":
				sprite.play("idle")

		if not is_on_floor():
			if sprite.animation != "jump":
				sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 10.0 * delta)

	move_and_slide()

func _on_attack_finished() -> void:
	_attacking = false
	sprite.play("idle")
