extends Node2D
# ══════════════════════════════════════════════════════════════════════════════
# Interior scene — shared by Mirelle's farmhouse and all city buildings.
# Room: 1920 × 1080 | floor at GY=708 | ceiling at CEIL_Y=420
# Furniture placed at FURN_SCALE=2.5 (source assets are small pixel art).
# ══════════════════════════════════════════════════════════════════════════════

const GAME_W  := 1920
const GAME_H  := 1080
const TILE    := 64
const COLS    := 30
const RY      := 356
const CEIL_Y  := 420
const GY      := 708
const WALL_BOT := 676
const WIN_Y   := 484
const WIN_H   := 128
const DOOR_X  := 64.0
const EXIT_R  := 100.0

const FURN_SCALE := 3.5
const PROP_P := "res://assets/props/furniture/"
const INT_P  := "res://assets/props/interior/"

# ── Shop catalog (Oswin's wares) ──────────────────────────────────────────────
const SHOP_ITEMS := [
	{
		"name": "Health Potion",
		"price": 5,
		"texture": "",
		"actions": ["Drink", "Drop"],
		"heal": 5,
		"desc": "Restores 5 HP.",
	},
	{
		"name": "Iron Sword",
		"price": 15,
		"texture": "",
		"slot": "weapon",
		"stat_bonus": {"attack": 2},
		"actions": ["Equip", "Drop"],
		"desc": "+2 Attack",
	},
	{
		"name": "Leather Armor",
		"price": 20,
		"texture": "",
		"slot": "armor",
		"stat_bonus": {"defense": 1},
		"actions": ["Equip", "Drop"],
		"desc": "+1 Defense",
	},
	{
		"name": "Winged Boots",
		"price": 25,
		"texture": "",
		"slot": "boots",
		"stat_bonus": {"jump": 2},
		"actions": ["Equip", "Drop"],
		"desc": "+2 Jump",
	},
]

const OSWIN_X     := 960.0   # Oswin stands mid-shop behind the counter
const OSWIN_R     := 260.0   # proximity radius to trigger shop prompt

var _player:    CharacterBody2D
var _camera:    Camera2D
var _music:     AudioStreamPlayer
var _hp_bar_fg: ColorRect
var _hp_label:  Label
var _hud_layer: CanvasLayer
var _exit_tip:  Label
var _shop_tip:  Label

# Shop panel
var _shop_layer:   CanvasLayer
var _shop_visible: bool  = false
var _shop_idx:     int   = 0
var _shop_gold_lbl: Label
var _shop_rows:    Array = []    # array of {panel, price_lbl, name_lbl, desc_lbl, style}

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

func _ready() -> void:
	_build_background()
	_build_room()
	_build_ground_physics()
	_build_furniture()
	_spawn_player()
	_build_camera()
	_build_hud()
	if Globals.interior_config_id == "oswin_shop":
		_build_shop_panel()
	_build_audio()
	_fade_in()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color   = Color(0.04, 0.03, 0.02)
	bg.size    = Vector2(GAME_W, GAME_H)
	bg.z_index = -10
	add_child(bg)

func _build_ground_physics() -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GAME_W * 2.0, 200.0)
	shape.position = Vector2(GAME_W / 2.0, GY + 100.0)
	shape.shape = rect
	body.add_child(shape); add_child(body)
	var lb := StaticBody2D.new(); var ls := CollisionShape2D.new(); var lr := RectangleShape2D.new()
	lr.size = Vector2(32, GAME_H * 2.0); ls.position = Vector2(-16, GAME_H / 2.0)
	ls.shape = lr; lb.add_child(ls); add_child(lb)
	var rb := StaticBody2D.new(); var rs := CollisionShape2D.new(); var rr := RectangleShape2D.new()
	rr.size = Vector2(32, GAME_H * 2.0); rs.position = Vector2(GAME_W + 16, GAME_H / 2.0)
	rr.size = Vector2(32, GAME_H * 2.0); rs.position = Vector2(GAME_W + 16, GAME_H / 2.0)
	rs.shape = rr; rb.add_child(rs); add_child(rb)

func _spawn_player() -> void:
	var s: PackedScene = load("res://scenes/Player.tscn")
	_player = s.instantiate()
	_player.position = Vector2(DOOR_X + 100.0, GY - 60.0)
	add_child(_player)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left = 0; _camera.limit_right = GAME_W
	_camera.limit_top  = 0; _camera.limit_bottom = GAME_H
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 6.0
	_player.add_child(_camera)

func _build_audio() -> void:
	_music = AudioStreamPlayer.new()
	var path := Globals.current_music_path
	if path == "": path = "res://assets/audio/celadune_theme.mp3"
	var res := load(path) as AudioStream
	if res:
		if res is AudioStreamMP3: (res as AudioStreamMP3).loop = true
		_music.stream = res
	_music.volume_db = linear_to_db(0.0)
	add_child(_music); _music.play()
	create_tween().tween_property(_music, "volume_db", linear_to_db(0.22), 0.5)

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
	_hp_label.text = "10 / 10"; _hp_label.position = Vector2(212, GAME_H - 46)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hp_label.add_theme_font_size_override("font_size", 13); _hud_layer.add_child(_hp_label)
	var room_lbl := Label.new()
	room_lbl.text = _room_name()
	room_lbl.position = Vector2(GAME_W / 2 - 300, 16)
	room_lbl.size = Vector2(600, 48)
	room_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_lbl.add_theme_font_override("font", Globals.FONT_TITLE)
	room_lbl.add_theme_font_size_override("font_size", 32)
	room_lbl.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	_hud_layer.add_child(room_lbl)
	_exit_tip = Label.new()
	_exit_tip.text = "E  —  Exit"; _exit_tip.visible = false; _exit_tip.z_index = 30
	_exit_tip.position = Vector2(DOOR_X - 40, GY - 140)
	_exit_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_exit_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_exit_tip.add_theme_constant_override("shadow_offset_x", 2)
	_exit_tip.add_theme_constant_override("shadow_offset_y", 2)
	_exit_tip.add_theme_font_size_override("font_size", 18)
	add_child(_exit_tip)

	# Shop tip (only relevant in oswin_shop)
	_shop_tip = Label.new()
	_shop_tip.text = "E  —  Browse Wares"
	_shop_tip.visible = false
	_shop_tip.z_index = 30
	_shop_tip.position = Vector2(OSWIN_X - 120, GY - 160)
	_shop_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_shop_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_shop_tip.add_theme_constant_override("shadow_offset_x", 2)
	_shop_tip.add_theme_constant_override("shadow_offset_y", 2)
	_shop_tip.add_theme_font_size_override("font_size", 18)
	add_child(_shop_tip)

func _fade_in() -> void:
	var ov := ColorRect.new(); ov.color = Color(0,0,0,1); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	tw.tween_property(ov, "color", Color(0,0,0,0), 0.5)
	tw.tween_callback(ov.queue_free)

func _process(_delta: float) -> void:
	if not _player: return

	# HP bar
	var ratio := float(Globals.player_health) / float(max(Globals.player_max_health, 1))
	_hp_bar_fg.size.x = 176.0 * ratio
	_hp_label.text = "%d / %d" % [Globals.player_health, Globals.player_max_health]

	# Shop panel input — consumed before door check
	if _shop_visible:
		if Input.is_action_just_pressed("ui_cancel"):
			_close_shop()
		elif Input.is_action_just_pressed("move_up"):
			_shop_idx = wrapi(_shop_idx - 1, 0, SHOP_ITEMS.size())
			_refresh_shop_rows()
		elif Input.is_action_just_pressed("move_down"):
			_shop_idx = wrapi(_shop_idx + 1, 0, SHOP_ITEMS.size())
			_refresh_shop_rows()
		elif Input.is_action_just_pressed("interact"):
			_try_buy(_shop_idx)
		return

	var near_door := _player.position.distance_to(Vector2(DOOR_X, GY)) < EXIT_R
	_exit_tip.visible = near_door

	var near_oswin := (Globals.interior_config_id == "oswin_shop") and \
		_player.position.distance_to(Vector2(OSWIN_X, GY)) < OSWIN_R
	_shop_tip.visible = near_oswin and not near_door

	if near_door and Input.is_action_just_pressed("interact"):
		_exit_room()
		return

	if near_oswin and not near_door and Input.is_action_just_pressed("interact"):
		_open_shop()

# ── Shop panel ──────────────────────────────────────────────────────────────

func _build_shop_panel() -> void:
	_shop_layer = CanvasLayer.new()
	_shop_layer.layer = 50
	_shop_layer.visible = false
	add_child(_shop_layer)

	# Dim overlay
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.68)
	dim.size  = Vector2(1920, 1080)
	_shop_layer.add_child(dim)

	# Parchment panel  860 × 660  centred
	const PX := 530; const PY := 200; const PW := 860; const PH := 660
	var panel := Panel.new()
	panel.position = Vector2(PX, PY)
	panel.size     = Vector2(PW, PH)
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(0.941, 0.875, 0.710)
	sty.border_color = Color(0.357, 0.216, 0.090)
	sty.set_border_width_all(5)
	panel.add_theme_stylebox_override("panel", sty)
	_shop_layer.add_child(panel)

	# Title
	var title := Label.new()
	title.text     = "Oswin's Wares"
	title.position = Vector2(PX + PW / 2 - 200, PY + 22)
	title.size     = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Globals.FONT_TITLE: title.add_theme_font_override("font", Globals.FONT_TITLE)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.357, 0.204, 0.090))
	_shop_layer.add_child(title)

	# Subtitle / hint
	var hint := Label.new()
	hint.text     = "↑ ↓  select   E  buy   Esc  close"
	hint.position = Vector2(PX + 20, PY + PH - 46)
	hint.size     = Vector2(PW - 40, 36)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Globals.FONT_MONO: hint.add_theme_font_override("font", Globals.FONT_MONO)
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.400, 0.300, 0.180))
	_shop_layer.add_child(hint)

	# Gold display
	_shop_gold_lbl = Label.new()
	_shop_gold_lbl.position = Vector2(PX + PW - 220, PY + 24)
	_shop_gold_lbl.size     = Vector2(200, 44)
	_shop_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if Globals.FONT_TITLE: _shop_gold_lbl.add_theme_font_override("font", Globals.FONT_TITLE)
	_shop_gold_lbl.add_theme_font_size_override("font_size", 26)
	_shop_gold_lbl.add_theme_color_override("font_color", Color(0.357, 0.204, 0.090))
	_shop_layer.add_child(_shop_gold_lbl)

	# Divider
	var div := ColorRect.new()
	div.color    = Color(0.357, 0.216, 0.090)
	div.size     = Vector2(PW - 40, 2)
	div.position = Vector2(PX + 20, PY + 82)
	_shop_layer.add_child(div)

	# Item rows
	const ROW_H := 108
	const ROW_Y := PY + 96
	const ROW_X := PX + 24

	_shop_rows.clear()
	for i in range(SHOP_ITEMS.size()):
		var item: Dictionary = SHOP_ITEMS[i]
		var ry := ROW_Y + i * ROW_H

		var row_panel := Panel.new()
		row_panel.position = Vector2(ROW_X, ry)
		row_panel.size     = Vector2(PW - 48, ROW_H - 10)
		var rs := StyleBoxFlat.new()
		rs.bg_color     = Color(0, 0, 0, 0)
		rs.border_color = Color(0.357, 0.216, 0.090)
		rs.set_border_width_all(3)
		row_panel.add_theme_stylebox_override("panel", rs)
		_shop_layer.add_child(row_panel)

		var name_lbl := Label.new()
		name_lbl.text     = item["name"]
		name_lbl.position = Vector2(ROW_X + 16, ry + 12)
		if Globals.FONT_TITLE: name_lbl.add_theme_font_override("font", Globals.FONT_TITLE)
		name_lbl.add_theme_font_size_override("font_size", 26)
		name_lbl.add_theme_color_override("font_color", Color(0.169, 0.106, 0.059))
		_shop_layer.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text     = item.get("desc", "")
		desc_lbl.position = Vector2(ROW_X + 16, ry + 50)
		if Globals.FONT_MONO: desc_lbl.add_theme_font_override("font", Globals.FONT_MONO)
		desc_lbl.add_theme_font_size_override("font_size", 18)
		desc_lbl.add_theme_color_override("font_color", Color(0.290, 0.200, 0.100))
		_shop_layer.add_child(desc_lbl)

		var price_lbl := Label.new()
		price_lbl.text     = "%d gold" % item["price"]
		price_lbl.position = Vector2(ROW_X + PW - 150, ry + 28)
		price_lbl.size     = Vector2(120, 40)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if Globals.FONT_TITLE: price_lbl.add_theme_font_override("font", Globals.FONT_TITLE)
		price_lbl.add_theme_font_size_override("font_size", 24)
		price_lbl.add_theme_color_override("font_color", Color(0.450, 0.300, 0.050))
		_shop_layer.add_child(price_lbl)

		_shop_rows.append({
			"panel": row_panel,
			"name_lbl": name_lbl,
			"desc_lbl": desc_lbl,
			"price_lbl": price_lbl,
			"style": rs,
		})

	# Oswin's opening line (bottom flavour text)
	var oswin_lbl := Label.new()
	oswin_lbl.text     = "\"Finest goods in Millhaven — everything enchanted and guaranteed.\""
	oswin_lbl.position = Vector2(PX + 20, PY + PH - 90)
	oswin_lbl.size     = Vector2(PW - 40, 44)
	oswin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oswin_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if Globals.FONT_MONO: oswin_lbl.add_theme_font_override("font", Globals.FONT_MONO)
	oswin_lbl.add_theme_font_size_override("font_size", 17)
	oswin_lbl.add_theme_color_override("font_color", Color(0.380, 0.270, 0.140))
	_shop_layer.add_child(oswin_lbl)

func _open_shop() -> void:
	if not _shop_layer: return
	_shop_visible = true
	_shop_idx     = 0
	_shop_layer.visible = true
	_refresh_shop_rows()

func _close_shop() -> void:
	_shop_visible = false
	if _shop_layer: _shop_layer.visible = false

func _refresh_shop_rows() -> void:
	_shop_gold_lbl.text = "Gold: %d" % Globals.player_gold
	for i in range(_shop_rows.size()):
		var row: Dictionary = _shop_rows[i]
		var item: Dictionary = SHOP_ITEMS[i]
		var selected := (i == _shop_idx)
		var can_afford := Globals.player_gold >= item["price"]
		var style: StyleBoxFlat = row["style"]
		style.bg_color     = Color(0.88, 0.78, 0.56, 0.7) if selected else Color(0, 0, 0, 0)
		style.border_color = Color(0.16, 0.08, 0.04) if selected else Color(0.60, 0.44, 0.26)
		style.set_border_width_all(4 if selected else 2)
		var name_col := Color(0.10, 0.06, 0.03) if can_afford else Color(0.55, 0.40, 0.28)
		row["name_lbl"].add_theme_color_override("font_color", name_col)
		var price_col: Color
		if not can_afford:
			price_col = Color(0.72, 0.25, 0.20)
		elif selected:
			price_col = Color(0.30, 0.55, 0.15)
		else:
			price_col = Color(0.45, 0.30, 0.05)
		row["price_lbl"].add_theme_color_override("font_color", price_col)

func _try_buy(idx: int) -> void:
	var item: Dictionary = SHOP_ITEMS[idx]
	if not Globals.spend_gold(item["price"]):
		return  # can't afford — silently ignore (price goes red as visual cue)
	# Give a copy of the item to player's inventory
	var copy := item.duplicate(true)
	copy.erase("price")
	copy.erase("desc")
	Globals.add_item(copy)
	_refresh_shop_rows()

func _exit_room() -> void:
	Globals.from_transition = true
	Globals.spawn_x = _return_x()
	var ov := ColorRect.new(); ov.color = Color(0,0,0,0); ov.size = Vector2(GAME_W, GAME_H)
	var cl := CanvasLayer.new(); cl.layer = 100; cl.add_child(ov); add_child(cl)
	var tw := create_tween()
	if _music: tw.tween_property(_music, "volume_db", -80.0, 0.3)
	tw.parallel().tween_property(ov, "color", Color(0,0,0,1), 0.3)
	tw.tween_callback(func() -> void:
		var path: String = Globals.return_scene_path
		if path == "": path = "res://scenes/" + _return_scene() + ".tscn"
		Globals.return_scene_path = ""
		get_tree().change_scene_to_file(path))

func _build_room() -> void:
	var roof_tex  := _tex(INT_P + "house_roof.png")
	var wall_tex  := _tex(INT_P + "house_wall.png")
	var wbase_tex := _tex(INT_P + "wall_base.png")
	var floor1    := _tex(INT_P + "floor_tile_1.png")
	var floor2    := _tex(INT_P + "floor_tile_2.png")
	var door_tex  := _tex(INT_P + "door_open.png")
	var win_tex   := _tex(INT_P + "blue_window_open.png")

	_fill_row(roof_tex, RY, TILE, TILE, 2)
	for row in range(4):
		_fill_row(wall_tex, CEIL_Y + row * TILE, TILE, TILE, 2)
	_fill_row(wbase_tex, WALL_BOT, TILE, 32, 2)

	for c in range(COLS):
		var t := floor1 if c % 2 == 0 else floor2
		if not t: continue
		var sp := Sprite2D.new()
		sp.texture = t; sp.centered = false
		sp.position = Vector2(c * TILE, GY)
		sp.scale = Vector2(float(TILE) / float(t.get_width()), float(TILE / 4) / float(t.get_height()))
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 2; add_child(sp)

	for wc in [5, 15, 25]:
		var sky := ColorRect.new()
		sky.color = Color(0.78, 0.87, 0.91)
		sky.position = Vector2(wc * TILE, WIN_Y)
		sky.size = Vector2(TILE, WIN_H); sky.z_index = 1; add_child(sky)
		if win_tex:
			var ws := _wall_sprite(win_tex, wc * TILE, WIN_Y, TILE, WIN_H)
			ws.z_index = 4; add_child(ws)

	if door_tex:
		var dw := int(door_tex.get_width() * 2); var dh := int(door_tex.get_height() * 2)
		var ds := _wall_sprite(door_tex, DOOR_X - dw / 2.0, GY - dh, dw, dh)
		ds.z_index = 5; add_child(ds)

func _tex(path: String) -> Texture2D:
	var t := load(path)
	if t is Texture2D: return t
	push_warning("HutInterior: missing " + path); return null

func _wall_sprite(tex: Texture2D, x: float, y: float, w: float, h: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.position = Vector2(x, y)
	sp.scale = Vector2(w / float(tex.get_width()), h / float(tex.get_height()))
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

func _fill_row(tex: Texture2D, y: float, tw: float, th: float, z: int) -> void:
	if not tex: return
	for c in range(COLS):
		var sp := _wall_sprite(tex, c * tw, y, tw, th)
		sp.z_index = z; add_child(sp)

func _build_furniture() -> void:
	match Globals.interior_config_id:
		"mirelle_farmhouse":
			_furn(PROP_P + "curtain_red.png",    330, GY - 40)
			_furn(PROP_P + "bed_canopy.png",     500, GY)
			_furn(PROP_P + "dresser.png",        760, GY)
			_furn_wall(PROP_P + "picture_sm.png", 650, CEIL_Y + 90)
			_furn_top(PROP_P + "chandelier.png", 960, CEIL_Y + TILE)
			_furn(PROP_P + "floor_lamp.png",    1050, GY)
			_furn(PROP_P + "sofa_red.png",      1150, GY)
			_furn(PROP_P + "bench_green.png",   1360, GY)
			_furn(PROP_P + "bench_teal.png",    1490, GY)
			_furn(PROP_P + "flower_vase.png",   1650, GY)
			_furn(PROP_P + "cabinet_wood.png",  1760, GY)
			_furn_wall(PROP_P + "picture_med.png", 1200, CEIL_Y + 85)
			_furn(PROP_P + "curtain_red.png",   1610, GY - 40)
		"bram_smithy":
			_furn(PROP_P + "barrel.png",        350, GY)
			_furn(PROP_P + "chest_open.png",    560, GY)
			_furn(PROP_P + "cabinet_dark.png",  800, GY)
			_furn(PROP_P + "lantern_stone.png", 1150, GY)
			_furn(PROP_P + "barrel.png",        1400, GY)
			_furn(PROP_P + "barrel.png",        1600, GY)
			_furn(PROP_P + "urn_decor.png",     1800, GY)
		"padrig_tavern":
			_furn(PROP_P + "curtain_red.png",   240, GY - 40)
			_furn(PROP_P + "bench_red.png",     380, GY)
			_furn(PROP_P + "bench_teal.png",    620, GY)
			_furn_top(PROP_P + "chandelier.png", 960, CEIL_Y + TILE)
			_furn(PROP_P + "sofa_ornate.png",  1100, GY)
			_furn(PROP_P + "table_lamp.png",   1380, GY)
			_furn(PROP_P + "bench_yellow.png", 1600, GY)
			_furn(PROP_P + "curtain_red.png",  1820, GY - 40)
		"teren_house":
			_furn(PROP_P + "cabinet_wood.png",  380, GY)
			_furn(PROP_P + "sofa_green.png",    700, GY)
			_furn_top(PROP_P + "chandelier.png", 960, CEIL_Y + TILE)
			_furn(PROP_P + "mirror_tall.png",  1300, GY)
			_furn(PROP_P + "dresser.png",      1600, GY)
			_furn_wall(PROP_P + "picture_med.png", 1100, CEIL_Y + 90)
		"ysra_house":
			_furn(PROP_P + "sofa_teal.png",    450, GY)
			_furn(PROP_P + "flower_vase.png",  760, GY)
			_furn(PROP_P + "blue_flower.png",  950, GY)
			_furn(PROP_P + "mirror_tall.png", 1300, GY)
			_furn(PROP_P + "cabinet_dark.png",1600, GY)
			_furn_wall(PROP_P + "picture_lg.png", 1100, CEIL_Y + 95)
		"oswin_shop":
			_furn(PROP_P + "crystal_blue.png",  350, GY)
			_furn(PROP_P + "cabinet_dark.png",  650, GY)
			_furn(PROP_P + "urn_decor.png",     950, GY)
			_furn(PROP_P + "crystal_blue.png", 1250, GY)
			_furn(PROP_P + "cabinet_dark.png", 1550, GY)
			_furn(PROP_P + "bird_stand.png",   1800, GY)
			_furn_top(PROP_P + "chandelier.png", 960, CEIL_Y + TILE)
			# Counter — a bench used as a shop counter in front of Oswin
			_furn(PROP_P + "bench_teal.png",   OSWIN_X - 64, GY)
		"rilla_house":
			_furn(PROP_P + "sofa_yellow.png",   450, GY)
			_furn_top(PROP_P + "chandelier.png", 960, CEIL_Y + TILE)
			_furn(PROP_P + "floor_lamp.png",    850, GY)
			_furn(PROP_P + "dresser.png",      1500, GY)
			_furn(PROP_P + "flower_vase.png",  1750, GY)
			_furn_wall(PROP_P + "picture_med.png", 1200, CEIL_Y + 90)
		_:
			_furn(PROP_P + "bed_canopy.png",  340, GY)
			_furn(PROP_P + "sofa_red.png",   1300, GY)
			_furn(PROP_P + "flower_vase.png",1750, GY)

func _furn(path: String, x: float, base_y: float) -> void:
	var tex := load(path) as Texture2D
	if not tex: push_warning("HutInterior: missing " + path); return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.scale = Vector2(FURN_SCALE, FURN_SCALE)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position = Vector2(x - tex.get_width() * FURN_SCALE * 0.5, base_y - tex.get_height() * FURN_SCALE)
	sp.z_index = 5; add_child(sp)

func _furn_top(path: String, x: float, top_y: float) -> void:
	var tex := load(path) as Texture2D
	if not tex: push_warning("HutInterior: missing " + path); return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.scale = Vector2(FURN_SCALE, FURN_SCALE)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position = Vector2(x - tex.get_width() * FURN_SCALE * 0.5, top_y)
	sp.z_index = 5; add_child(sp)

func _furn_wall(path: String, x: float, mid_y: float) -> void:
	var tex := load(path) as Texture2D
	if not tex: push_warning("HutInterior: missing " + path); return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.scale = Vector2(FURN_SCALE, FURN_SCALE)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position = Vector2(x - tex.get_width() * FURN_SCALE * 0.5, mid_y - tex.get_height() * FURN_SCALE * 0.5)
	sp.z_index = 4; add_child(sp)
