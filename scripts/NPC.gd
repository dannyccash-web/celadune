extends Node2D

# ── NPC configuration (set before _ready via Forest.gd) ─────────────────────
var npc_name:       String  = ""
var walk_path:      String  = ""
var idle_path:      String  = ""
var walk_frames:    int     = 8
var idle_frames:    int     = 5
var npc_scale:      float   = 3.0  # Matches Phaser setScale(3.0) for all NPCs
var patrol_min_x:   float   = 0.0
var patrol_max_x:   float   = 0.0
var patrol_speed:   float   = 48.0  # px/s (Phaser wanderSpeed default)
var pause_ms:       float   = 3500.0
var frame_w:        int     = 64
var frame_h:        int     = 64

# ── NPC sprite Y position in world space ────────────────────────────────────
# NPC sprites are 64×64 at scale 3.0 (192×192 displayed).
# Phaser physics body 18×34 at offset(23,28): at 3.0× body is 54×102,
# offset (69, 84) from sprite top-left, bottom sits at GROUND_Y=888.
# Sprite center Y on ground: 888 - 84 - 51 + 96 = 849... let's derive cleanly:
#   body_bottom_world = sprite_center.y + (frame_h/2 * scale) - (frame_h * scale - (offset_y + body_h) * scale)
# Simpler: sprite_center.y = body_bottom_world - (offset_y + body_h - frame_h/2) * scale
#   = 888 - (28 + 34 - 32) * 3.0 = 888 - 30*3.0 = 888 - 90 = 798
const NPC_GROUND_Y := 798.0

# ── Internal state ────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $Sprite
var _dir:        int    = 1     # 1 = right, -1 = left
var _pause_timer: float = 0.0
var _paused:     bool   = false

func _ready() -> void:
	_build_animations()
	sprite.scale          = Vector2(npc_scale, npc_scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# GandalfHardcore sprites face LEFT by default; start facing right
	sprite.flip_h = true
	sprite.play("idle")
	z_index = 8

	# Brief pause before starting patrol
	_paused = true
	_pause_timer = 1.2

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_strip(frames, "walk", walk_path, walk_frames, 10.0, true)
	_add_strip(frames, "idle", idle_path, idle_frames, 4.0, true)
	sprite.sprite_frames = frames

func _add_strip(frames: SpriteFrames, anim: String, path: String, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	var tex: Texture2D = load(path)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame(anim, atlas)

func _process(delta: float) -> void:
	if _paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_paused = false
			sprite.play("walk")
		return

	# Move in current direction
	position.x += _dir * patrol_speed * delta

	# Flip sprite: face LEFT by default, flip for right
	sprite.flip_h = _dir > 0

	# Reverse at patrol ends
	if _dir > 0 and position.x >= patrol_max_x:
		position.x = patrol_max_x
		_start_pause()
		_dir = -1
	elif _dir < 0 and position.x <= patrol_min_x:
		position.x = patrol_min_x
		_start_pause()
		_dir = 1

func _start_pause() -> void:
	_paused = true
	_pause_timer = pause_ms / 1000.0
	sprite.play("idle")

# ── External pause (called by scene during dialogue) ──────────────────────────

func pause_patrol() -> void:
	set_process(false)
	sprite.play("idle")

func resume_patrol() -> void:
	set_process(true)
