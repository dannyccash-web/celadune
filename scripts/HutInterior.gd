extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# HutInterior — interior scene for Mirelle's farmhouse + all 6 city buildings
# Room: 30 cols × 64px = 1920px wide (fills viewport exactly — no camera scroll)
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W   := 1920
const GAME_H   := 1080
const TILE     := 64
const COLS     := 30
const RY       := 356      # roof y
const CEIL_Y   := 420      # wall rows start
const WALL_BOT := 676      # wainscoting row
const GY       := 708      # floor y (physics ground)
const WIN_Y    := 484      # window top
const WIN_H    := 128      # window height
const EXIT_R   := 90.0     # exit trigger radius from door center

const F := "res://assets/props/furniture/"
const P := "res://assets/props/interior/"

# ── Per-config helpers ────────────────────────────────────────────────────────

func _room_name() -> String:
	match Globals.interior_config_id:
		"bram_smithy":    return "Bram Alder's Smithy"
		"padrig_tavern":  return "Padrig's Tavern"
		"teren_house":    return "Teren Vale's House"
		"ysra_house":     return "Ysra Thorn's House"
		"oswin_shop":     return "Oswin's Shop"
		"rilla_house":    return "Rilla's House"
	return "Mirelle's Farmhouse"

func _return_scene() -> String:
	match Globals.interior_config_id:
		"bram_smithy", "padrig_tavern", "teren_house", "ysra_house", "oswin_shop", "rilla_house":
			return "City"
	return "Forest"

func _return_x() -> float:
	match Globals.interior_config_id:
		"bram_smithy":   return 909.0
		"padrig_tavern": return 1611.0
		"teren_house":   return 2144.0
		"ysra_house":    return 2700.0
		"oswin_shop":    return 3303.0
		"rilla_house":   return 3757.0
	return 2274.0

# Per-config window variant (blue, red, or plain)
func _window_texture() -> String:
	match Globals.interior_config_id:
		"bram_smithy":   return P + "red_window_open.png"
		"padrig_tavern": return P + "blue_window_open.png"
		"ysra_house":    return P + "red_window_open.png"
	return P + "blue_window_open.png"

# Furniture: Array of [path, world_x, world_y]
# world_y: use GY to sit on the floor, or GY - offset for wall items
func _furniture_items() -> Array:
	match Globals.interior_config_id:
		"mirelle_farmhouse":
			return [
				[F + "small_chandelier.png",    480.0, GY - 180.0],
				[F + "red_sofa.png",            620.0, GY],
				[F + "bookcase.png",           1100.0, GY],
				[F + "small_flower_picture.png",820.0, GY - 180.0],
				[F + "flower_vase.png",        1400.0, GY],
			]
		"bram_smithy":
			return [
				[F + "wooden_crate.png",        500.0, GY],
				[F + "wooden_crate.png",        600.0, GY],
				[F + "mantel_shelf.png",        950.0, GY - 200.0],
				[F + "stacked_books.png",      1300.0, GY],
				[F + "wooden_t_post.png",      1500.0, GY],
			]
		"padrig_tavern":
			return [
				[F + "wooden_table.png",        550.0, GY],
				[F + "blue_bench.png",          480.0, GY],
				[F + "blue_bench.png",          680.0, GY],
				[F + "blue_cushioned_bench.png",1000.0, GY],
				[F + "stacked_books.png",      1350.0, GY],
				[F + "hanging_lantern.png",     800.0, GY - 220.0],
			]
		"teren_house":
			return [
				[F + "bookcase.png",            500.0, GY],
				[F + "nightstand.png",          900.0, GY],
				[F + "double_door_wardrobe.png",1250.0, GY],
				[F + "small_wall_shelf.png",    700.0, GY - 180.0],
			]
		"ysra_house":
			return [
				[F + "blue_sofa.png",           580.0, GY],
				[F + "floor_lamp.png",          830.0, GY],
				[F + "wall_mirror.png",        1100.0, GY - 160.0],
				[F + "small_framed_portrait.png", 1350.0, GY - 170.0],
			]
		"oswin_shop":
			return [
				[F + "bookcase.png",            480.0, GY],
				[F + "bookcase.png",            600.0, GY],
				[F + "stacked_books.png",       780.0, GY],
				[F + "plant_on_pedestal.png",  1050.0, GY],
				[F + "small_wall_cabinet.png", 1350.0, GY - 180.0],
				[F + "small_green_chest.png",  1550.0, GY],
			]
		"rilla_house":
			return [
				[F + "red_sofa.png",            580.0, GY],
				[F + "flower_vase.png",         850.0, GY],
				[F + "small_wall_cabinet.png", 1200.0, GY - 170.0],
				[F + "blue_armchair.png",      1400.0, GY],
			]
	return []

# ── Nodes ─────────────────────────────────────────────────────────────────────
var _player:     CharacterBody2D
var _music:      AudioStreamPlayer
var _jump_sfx:   AudioStreamPlayer
var _attack_sfx: AudioStreamPlayer
var _hp_bar_fg:  ColorRect
var _hp_label:   Label
var _hud_layer:  CanvasLayer
var _menu_panel: Node
var _menu_open:  bool = false
var _transitioning: bool = false
var _exit_tip:   Label

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_background()
	_build_room_tiles()
	_build_physics()
	_place_furniture()
	_spawn_player()
	_build_audio()
	_build_hud()
	_build_exit_tip()
	_build_menu()
	_fade_in()

# ── Background ────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var cl := CanvasLayer.new(); cl.layer = -1; add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.02)
	bg.size  = Vector2(GAME_W, GAME_H)
	cl.add_child(bg)

# ── Room tiles ────────────────────────────────────────────────────────────────

func _build_room_tiles() -> void:
	var roof_tex  := _tex(P + "house_roof.png")
	var wall_tex  := _tex(P + "house_wall.png")
	var wbase_tex := _tex(P + "wall_base.png")
	var floor1    := _tex(P + "floor_tile_1.png")
	var floor2    := _tex(P + "floor_tile_2.png")
	var door_tex  := _tex(P + "door_open.png")
	var win_tex   := _tex(_window_texture())

	_fill_row(roof_tex,  RY,            TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y,        TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 64,   TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 128,  TILE, 64, 2)
	_fill_row(wall_tex,  CEIL_Y + 192,  TILE, 64, 2)
	_fill_row(wbase_tex, WALL_BOT,      TILE, 32, 2)

	# Alternating floor tiles
	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		if not t: continue
		var sp := Sprite2D.new()
		sp.texture = t; sp.centered = false
		sp.position = Vector2(c * TILE, GY)
		sp.scale = Vector2(float(TILE) / float(t.get_width()), 16.0 / float(t.get_height()))
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 2; add_child(sp)

	# Windows at cols 5, 15, 25
	for wc in [5, 15, 25]:
		var sky := ColorRect.new()
		sky.color    = Color(0.78, 0.87, 0.91)
		sky.position = Vector2(wc * TILE, WIN_Y)
		sky.size     = Vector2(TILE, WIN_H)
		sky.z_index  = 1; add_child(sky)
		if win_tex:
			var ws := _sprite(win_tex, float(wc * TILE), WIN_Y, float(TILE), float(WIN_H))
			ws.z_index = 4; add_child(ws)

	# Door at col 0 (left wall)
	if door_tex:
		var ds := _sprite(door_tex, 0.0, GY - 92.0, float(TILE), 92.0)
		ds.z_index = 5; add_child(ds)

	# Room name subtitle
	var name_cl := CanvasLayer.new(); name_cl.layer = 5; add_child(name_cl)
	var lbl := Label.new()
	lbl.text                = _room_name()
	lbl.position            = Vector2(760, 315)
	lbl.size                = Vector2(400, 36)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58, 0.6))
	name_cl.add_child(lbl)

# ── Physics ───────────────────────────────────────────────────────────────────

func _build_physics() -> void:
	# Floor (wide slab below GY)
	var fb  := StaticBody2D.new()
	var fsh := CollisionShape2D.new()
	var frr := RectangleShape2D.new()
	frr.size       = Vector2(GAME_W * 2.0, 200.0)
	fsh.position   = Vector2(GAME_W / 2.0, GY + 2.0 + 100.0)
	fsh.shape      = frr
	fb.add_child(fsh); add_child(fb)

	# Left wall
	var lw  := StaticBody2D.new()
	var lsh := CollisionShape2D.new()
	var lrr := RectangleShape2D.new()
	lrr.size     = Vector2(20.0, GAME_H * 2.0)
	lsh.position = Vector2(-10.0, GAME_H / 2.0)
	lsh.shape    = lrr
	lw.add_child(lsh); add_child(lw)

	# Right wall
	var rw  := StaticBody2D.new()
	var rsh := CollisionShape2D.new()
	var rrr := RectangleShape2D.new()
	rrr.size     = Vector2(20.0, GAME_H * 2.0)
	rsh.position = Vector2(GAME_W + 10.0, GAME_H / 2.0)
	rsh.shape    = rrr
	rw.add_child(rsh); add_child(rw)

# ── Furniture ─────────────────────────────────────────────────────────────────

func _place_furniture() -> void:
	for item in _furniture_items():
		_furniture(item[0], item[1], item[2])

func _furniture(path: String, x: float, y: float) -> void:
	var tex: Texture2D = load(path)
	if not tex:
		push_warning("HutInterior: missing furniture " + path)
		return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = true
	sp.offset  = Vector2(0.0, -tex.get_height() * 0.5)
	sp.position = Vector2(x, y)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = 6; add_child(sp)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	# Spawn just inside door — body center y when standing = GY - SHAPE_H/2 = 708 - 52.5 ≈ 655
	_player.position = Vector2(140.0, 655.0)
	_player.jumped.connect(_on_player_jumped)
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)

# ── Audio ─────────────────────────────────────────────────────────────────────

func _build_audio() -> void:
	_music      = _audio("res://assets/audio/celadune_forest.mp3",                                     0.0,  true)
	_jump_sfx   = _audio("res://assets/sfx/ribhavagrawal-woosh-230554.mp3",                            0.45, false)
	_attack_sfx = _audio("res://assets/sfx/freesound_community-sword-sound-2-36274.mp3",               0.55, false)
	_music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.22), 0.4)

func _audio(path: String, vol: float, loop: bool) -> AudioStreamPlayer:
	var p   := AudioStreamPlayer.new()
	var res := load(path) as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = loop
		p.stream = res
	p.volume_db = linear_to_db(vol)
	add_child(p)
	return p

func _on_player_jumped()   -> void: if _jump_sfx:   _jump_sfx.play()
func _on_player_attacked() -> void: if _attack_sfx: _attack_sfx.play()

# ── HUD ───────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new(); _hud_layer.layer = 10; add_child(_hud_layer)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(24, GAME_H - 46); bar_bg.size = Vector2(180, 16)
	bar_bg.color = Color(0.1, 0.04, 0.04, 0.85); _hud_layer.add_child(bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.position = Vector2(26, GAME_H - 44); _hp_bar_fg.size = Vector2(176, 12)
	_hp_bar_fg.color = Color(0.87, 0.2, 0.2); _hud_layer.add_child(_hp_bar_fg)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"; hp_lbl.position = Vector2(24, GAME_H - 62)
	hp_lbl.add_theme_color_override("font_color", Color(0.87, 0.2, 0.2))
	hp_lbl.add_theme_font_size_override("font_size", 13); _hud_layer.add_child(hp_lbl)

	_hp_label = Label.new()
	_hp_label.text = "%d / %d" % [Globals.player_health, Globals.player_max_health]
	_hp_label.position = Vector2(212, GAME_H - 46)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hp_label.add_theme_font_size_override("font_size", 13); _hud_layer.add_child(_hp_label)

	var mhint := Label.new()
	mhint.text = "M  Menu"; mhint.position = Vector2(GAME_W - 120, GAME_H - 32)
	mhint.add_theme_color_override("font_color", Color(0.78, 0.87, 0.92))
	mhint.add_theme_font_size_override("font_size", 18); _hud_layer.add_child(mhint)

	_refresh_hud()

func _refresh_hud() -> void:
	var pct := float(Globals.player_health) / float(Globals.player_max_health)
	_hp_bar_fg.size.x = 176.0 * pct
	_hp_label.text    = "%d / %d" % [Globals.player_health, Globals.player_max_health]

# ── Exit tooltip ──────────────────────────────────────────────────────────────

func _build_exit_tip() -> void:
	_exit_tip = Label.new()
	_exit_tip.text    = "E  —  Exit"
	_exit_tip.visible = false
	_exit_tip.z_index = 30
	_exit_tip.position = Vector2(8, 560)
	_exit_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_exit_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_exit_tip.add_theme_constant_override("shadow_offset_x", 2)
	_exit_tip.add_theme_constant_override("shadow_offset_y", 2)
	_exit_tip.add_theme_font_size_override("font_size", 16)
	add_child(_exit_tip)

# ── Menu ──────────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var mp_script: GDScript = load("res://scripts/MenuPanel.gd")
	_menu_panel = mp_script.new()
	add_child(_menu_panel)
	_menu_panel.closed.connect(_on_menu_closed)

func _on_menu_closed() -> void:
	_menu_open = false
	if _player: _player.set_physics_process(true)

# ── Fade-in ───────────────────────────────────────────────────────────────────

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.5)
	tw.tween_callback(ov.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# Per-frame
# ══════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if not _player or _transitioning: return

	if Input.is_action_just_pressed("menu_toggle") and not _menu_open:
		_menu_open = true
		_player.set_physics_process(false)
		_menu_panel.open()
		return

	if _menu_open: return

	# Near the door (left side of room)
	var near_door := _player.position.x < 200.0
	_exit_tip.visible = near_door

	if near_door and Input.is_action_just_pressed("interact"):
		_do_exit()

func _do_exit() -> void:
	if _transitioning: return
	_transitioning = true
	_player.set_physics_process(false)
	Globals.from_transition = true
	Globals.spawn_x = _return_x()
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	if _music:
		tw.tween_property(_music, "volume_db", -80.0, 0.22)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.22)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/" + _return_scene() + ".tscn"))

# ── Helpers ───────────────────────────────────────────────────────────────────

func _tex(path: String) -> Texture2D:
	var t := load(path)
	if t is Texture2D: return t
	return null

func _sprite(tex: Texture2D, x: float, y: float, w: float, h: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.position = Vector2(x, y)
	sp.scale = Vector2(w / float(tex.get_width()), h / float(tex.get_height()))
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _fill_row(tex: Texture2D, y: float, tw: float, th: float, z: int) -> void:
	if not tex: return
	for c in range(COLS):
		var sp := _sprite(tex, c * tw, y, tw, th)
		sp.z_index = z; add_child(sp)
