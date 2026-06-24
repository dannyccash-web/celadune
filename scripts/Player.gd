extends CharacterBody2D

# ── Coordinate reference ─────────────────────────────────────────────────────
# World is 1920×1080. GROUND_Y = 888 (top of surface tiles).
# When is_on_floor(), shape bottom = 888 → position.y = 888 - SHAPE_HALF_H = 843.
# In Phaser the player sprite center was at Y≈795 when on ground.
# Sprite offset.y = 795 - 843 = -48 puts the visual at the same height.

# ── Constants ────────────────────────────────────────────────────────────────
const SPEED          := 350.0   # px/s horizontal (approx Phaser dragX feel)
const JUMP_VELOCITY  := -820.0  # px/s upward (tuned for 1920×1080 / gravity 1800)
const GRAVITY        := 1800.0  # matches Phaser world gravity

# Caelan: 100×64 px frames, displayed at 3.1× (same as Phaser playerBaseScaleX)
const FRAME_W        := 100
const FRAME_H        := 64
const SPRITE_SCALE   := 3.1

# Physics box: in Phaser body was 20×34 (unscaled), offset (41,28).
# At 3.1× that's 62×105 in world space, positioned so its bottom = GROUND_Y.
# We use a Rectangle of the same world-space size for predictable floor detection.
const SHAPE_W        := 62.0
const SHAPE_H        := 105.0
const SHAPE_HALF_H   := SHAPE_H / 2.0   # 52.5

# Sprite vertical offset so visual feet sit at GROUND_Y when on floor.
# player.y on floor = 888 - 52.5 = 835.5; Phaser sprite center was 795.
# offset.y = 795 - 835.5 = -40.5 ≈ -41
const SPRITE_OFFSET_Y := -41.0

# ── Nodes ────────────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision

# ── State ────────────────────────────────────────────────────────────────────
var _attacking     := false
var _attack_timer  := 0.0
const ATTACK_DURATION := 0.375  # 3 frames @ 8 fps

# ── Setup ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_collision()
	_build_animations()
	sprite.scale   = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.offset  = Vector2(0.0, SPRITE_OFFSET_Y)
	# Pixel-art sprites → nearest-neighbour. Backgrounds are LINEAR (set there).
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Sprites face LEFT by default; start facing right
	sprite.flip_h = true
	sprite.play("idle")
	z_index = 10

func _build_collision() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SHAPE_W, SHAPE_H)
	collision.shape = rect
	# No offset — rectangle is centered on player position node

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	# [name, path, frame_count, fps, loop]
	var defs := [
		["idle",           "res://assets/characters/caelan/idle.png",           1,  1.0,  true],
		["walk",           "res://assets/characters/caelan/walk.png",           6,  10.0, true],
		["run",            "res://assets/characters/caelan/run.png",            6,  12.0, true],
		["jump",           "res://assets/characters/caelan/jump.png",           3,  10.0, false],
		["attack",         "res://assets/characters/caelan/attack.png",         3,   8.0, false],
		["death",          "res://assets/characters/caelan/death.png",          3,   5.0, false],
		["attack_sword",   "res://assets/characters/caelan/attack_sword.png",   3,   8.0, false],
		["idle_sword",     "res://assets/characters/caelan/idle_sword.png",     1,   1.0, true],
		["walk_sword",     "res://assets/characters/caelan/walk_sword.png",     6,  10.0, true],
		["jump_sword",     "res://assets/characters/caelan/jump_sword.png",     3,  10.0, false],
		["special_attack", "res://assets/characters/caelan/special_attack.png", 4,   8.0, false],
		["combo_attack",   "res://assets/characters/caelan/combo_attack.png",   8,  10.0, false],
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

	# Horizontal movement (not while attacking)
	if not _attacking:
		var dir := Input.get_axis("move_left", "move_right")
		if dir != 0.0:
			velocity.x = dir * SPEED
			# Sprites face LEFT by default → flip_h true = facing right
			sprite.flip_h = dir > 0.0
			if is_on_floor() and sprite.animation != "walk":
				sprite.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 12.0 * delta)
			if is_on_floor() and sprite.animation != "idle":
				sprite.play("idle")

		if not is_on_floor() and sprite.animation != "jump":
			sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 12.0 * delta)

	move_and_slide()

func _on_attack_finished() -> void:
	_attacking = false
	sprite.play("idle")
