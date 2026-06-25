extends CharacterBody2D

# ── Coordinate derivation ────────────────────────────────────────────────────
# Phaser source values (main.js):
#   playerBaseScaleX/Y = 3.1
#   body.setSize(20, 34), setOffset(41, 28)   ← unscaled px
#   body bottom when on floor = GROUND_Y = 888
#
# In Phaser, body world size = 20×34 × 3.1 = 62×105.4
# Body bottom at 888 → body top = 888 - 105.4 = 782.6
# Sprite center.y = body_top - (offset_y × scale) + (frame_h/2 × scale)
#                 = 782.6 - (28×3.1) + (32×3.1) = 782.6 - 86.8 + 99.2 = 795
#
# Godot CharacterBody2D: RectangleShape2D size=(62, 105), half_h=52.5
# On floor: position.y = 888 - 52.5 = 835.5
# We want sprite visual center at 795 → sprite.position.y = 795 - 835.5 = -40.5 ≈ -41
#
# IMPORTANT: Use sprite.position (world-space offset from parent), NOT sprite.offset.
# sprite.offset is pre-scale in Godot and would be multiplied by 3.1, making it 127px.

# ── Signals (Forest.gd connects these for SFX) ───────────────────────────────
signal jumped
signal attacked

# ── Physics constants — exact Phaser values ──────────────────────────────────
const SPEED         := 260.0   # px/s  (Phaser moveSpeed = 260)
const JUMP_VEL      := -570.0  # px/s  (Phaser setVelocityY(-570))
const GRAVITY       := 1800.0  # px/s² (Phaser world gravity.y = 1800)
const DRAG_X        := 1800.0  # px/s² (Phaser body.setDragX(1800))
const MAX_VEL_X     := 350.0   # px/s  (Phaser body.setMaxVelocity(350, 1200))
const MAX_VEL_Y     := 1200.0

# ── Sprite constants ─────────────────────────────────────────────────────────
const FRAME_W       := 100
const FRAME_H       := 64
const SCALE         := 3.1

# Shape matches Phaser's scaled physics body
const SHAPE_W       := 62.0    # 20 × 3.1
const SHAPE_H       := 105.0   # 34 × 3.1
# Sprite node sits 41 world-pixels above CharacterBody2D center (see derivation above)
const SPRITE_Y      := -41.0

# ── Nodes ────────────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision

# ── State ────────────────────────────────────────────────────────────────────
var _attacking := false
const ATTACK_FRAMES := 3
const ATTACK_FPS    := 8.0
const ATTACK_DUR    := ATTACK_FRAMES / ATTACK_FPS   # 0.375 s

func _ready() -> void:
	_build_collision()
	_build_animations()

	sprite.scale          = Vector2(SCALE, SCALE)
	sprite.position       = Vector2(0.0, SPRITE_Y)   # world-space offset, unaffected by sprite scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.flip_h         = true   # sprites face LEFT by default; start facing right
	sprite.play("idle")
	z_index = 10

func _build_collision() -> void:
	var r := RectangleShape2D.new()
	r.size = Vector2(SHAPE_W, SHAPE_H)
	collision.shape = r

func _build_animations() -> void:
	# All Caelan animation sheets are single-row warrior strips (frames 0..N in row 0).
	# createCaelanAnimations() in Phaser uses warriorFrameList which picks frames 0..count-1.
	# Direction is handled by flip_h, not by separate left/right rows.
	var f := SpriteFrames.new()
	f.remove_animation("default")
	var defs := [
		# [name, path, frames, fps, loop]
		["idle",           "res://assets/characters/caelan/idle.png",           1,  1.0,  true],
		["walk",           "res://assets/characters/caelan/walk.png",           6,  10.0, true],
		["run",            "res://assets/characters/caelan/run.png",            6,  12.0, true],
		["jump",           "res://assets/characters/caelan/jump.png",           3,  10.0, false],
		["attack",         "res://assets/characters/caelan/attack.png",         3,   8.0, false],
		["special_attack", "res://assets/characters/caelan/special_attack.png", 4,   8.0, false],
		["death",          "res://assets/characters/caelan/death.png",          3,   5.0, false],
		["idle_sword",     "res://assets/characters/caelan/idle_sword.png",     1,   1.0, true],
		["walk_sword",     "res://assets/characters/caelan/walk_sword.png",     6,  10.0, true],
		["jump_sword",     "res://assets/characters/caelan/jump_sword.png",     3,  10.0, false],
		["attack_sword",   "res://assets/characters/caelan/attack_sword.png",   3,   8.0, false],
		["combo_attack",       "res://assets/characters/caelan/combo_attack.png",       8,  10.0, false],
		["walk_heavy",         "res://assets/characters/caelan/walk_heavy.png",         6,   8.0, true],
		["run_sword",          "res://assets/characters/caelan/run_sword.png",          6,  12.0, true],
		["walk_sword_heavy",   "res://assets/characters/caelan/walk_sword_heavy.png",   6,   8.0, true],
		["death_sword",        "res://assets/characters/caelan/death_sword.png",        3,   5.0, false],
		["special_slash",      "res://assets/characters/caelan/special_slash.png",      6,   8.0, false],
	]
	for d in defs:
		_strip(f, d[0], d[1], d[2], d[3], d[4])

	# "rise" = death frames in reverse order (intro sequence)
	f.add_animation("rise")
	f.set_animation_loop("rise", false)
	f.set_animation_speed("rise", 8.0)   # Phaser frameRate:8
	var death_tex: Texture2D = load("res://assets/characters/caelan/death.png")
	if death_tex:
		for i in [2, 1, 0]:
			var a := AtlasTexture.new()
			a.atlas  = death_tex
			a.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			f.add_frame("rise", a)

	sprite.sprite_frames = f

func _strip(f: SpriteFrames, name: String, path: String, count: int, fps: float, loop: bool) -> void:
	f.add_animation(name)
	f.set_animation_loop(name, loop)
	f.set_animation_speed(name, fps)
	var tex: Texture2D = load(path)
	for i in range(count):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		f.add_frame(name, a)

# ── Per-frame physics ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_VEL_Y)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _attacking:
		velocity.y = JUMP_VEL
		emit_signal("jumped")

	# Attack — Phaser startAttack() plays special_attack (4-frame overhead slash)
	if Input.is_action_just_pressed("attack") and not _attacking:
		_attacking = true
		sprite.play("special_attack")
		emit_signal("attacked")
		sprite.animation_finished.connect(_on_attack_done, CONNECT_ONE_SHOT)

	# Horizontal movement
	var dir := Input.get_axis("move_left", "move_right")
	if not _attacking:
		if dir != 0.0:
			velocity.x = clampf(dir * SPEED, -MAX_VEL_X, MAX_VEL_X)
			sprite.flip_h = dir > 0.0   # flip_h true = facing right
			if is_on_floor() and sprite.animation != "walk":
				sprite.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0.0, DRAG_X * delta)
			if is_on_floor() and sprite.animation != "idle":
				sprite.play("idle")

		if not is_on_floor():
			if sprite.animation != "jump":
				sprite.play("jump")
			if velocity.y > -20.0 and sprite.is_playing():
				sprite.pause()
			elif velocity.y <= -20.0 and not sprite.is_playing():
				sprite.play()  # resume ascending from paused state
	else:
		velocity.x = move_toward(velocity.x, 0.0, DRAG_X * delta)

	move_and_slide()

func _on_attack_done() -> void:
	_attacking = false
	sprite.play("idle")
