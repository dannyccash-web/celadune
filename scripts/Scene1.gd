extends Node2D
## Scene1 — Millhaven outskirts. 1920×1080 fixed viewport (no camera scroll).
##
## World layout (Y increases downward):
##   ROW_GREEN2 y=888   visual depth strip
##   ROW_GREEN1 y=952   player/NPC ground (physics collision here)
##   ROW_BLACK  y=1016  UI strip — HUD lives here
##   GAME_H     y=1080  bottom edge
##
## The viewport is also 1920×1080 so the entire scene fills the screen.
## No Camera2D needed.

const GAME_W := 1920
const GAME_H := 1080
const TILE   := 64
const COLS   := GAME_W / TILE

const ROW_BLACK  := GAME_H - TILE       # 1016
const ROW_GREEN1 := GAME_H - TILE * 2  # 952
const ROW_GREEN2 := GAME_H - TILE * 3  # 888
const GROUND_Y        := ROW_GREEN1     # 952
const BUILDING_BASE_Y := GAME_H - 150  # 930

# Oswin stands just right of the building entrance
const OSWIN_X    := 1090.0
const OSWIN_W    := 40.0     # placeholder body width
const OSWIN_H    := 80.0     # placeholder body height
const OSWIN_R    := 140.0    # interaction radius

const BG_PATH       := "res://assets/bg/scene_background.png"
const TILE_BLACK    := "res://assets/tiles/ground_tile_black.png"
const TILE_GREEN1   := "res://assets/tiles/ground_tile_green_1.png"
const TILE_GREEN2   := "res://assets/tiles/ground_tile_green_2.png"
const BUILDING_PATH := "res://assets/buildings/forest_hut/building.png"
const PLAYER_SCENE  := "res://scenes/Player.tscn"

const SHOP_ITEMS := [
	{"name": "Health Potion", "price": 5,  "heal": 5,  "actions": ["Drink","Drop"], "desc": "Restores 5 HP."},
	{"name": "Iron Sword",    "price": 15, "slot": "weapon", "stat_bonus": {"attack": 2},  "actions": ["Equip","Drop"], "desc": "+2 Attack"},
	{"name": "Leather Armor", "price": 20, "slot": "armor",  "stat_bonus": {"defense": 1}, "actions": ["Equip","Drop"], "desc": "+1 Defense"},
	{"name": "Winged Boots",  "price": 25, "slot": "boots",  "stat_bonus": {"jump": 2},    "actions": ["Equip","Drop"], "desc": "+2 Jump"},
]

# ── State ──────────────────────────────────────────────────────────────────────
var _player:      CharacterBody2D = null
var _menu:        Node            = null

var _near_oswin:  bool  = false
var _oswin_tip:   Label = null

var _shop_visible:  bool          = false
var _shop_idx:      int           = 0
var _shop_layer:    CanvasLayer   = null
var _shop_gold_lbl: Label         = null
var _shop_rows:     Array         = []

var _hud_hp_bar:  ColorRect = null
var _hud_hp_lbl:  Label     = null
var _hud_gold:    Label     = null

# ── Boot ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_background()
	_build_ground()
	_build_building()
	_build_physics()
	_spawn_player()
	_build_oswin_npc()
	_build_shop_panel()
	_build_hud()
	_spawn_menu()

# ── Background ────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var tex := load(BG_PATH) as Texture2D
	if not tex:
		var fb := ColorRect.new()
		fb.color = Color(0.08, 0.12, 0.08); fb.size = Vector2(GAME_W, GAME_H); fb.z_index = -10
		add_child(fb); return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false; sp.position = Vector2.ZERO
	sp.z_index = -10; sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sp)

# ── Ground tile rows ──────────────────────────────────────────────────────────

func _build_ground() -> void:
	_tile_row(TILE_GREEN2, ROW_GREEN2, -2)
	_tile_row(TILE_GREEN1, ROW_GREEN1,  2)
	_tile_row(TILE_BLACK,  ROW_BLACK,  20)

func _tile_row(path: String, row_y: int, z: int) -> void:
	var tex := load(path) as Texture2D
	if not tex: push_warning("Scene1: missing tile " + path); return
	for col in range(COLS):
		var sp := Sprite2D.new()
		sp.texture = tex; sp.centered = false
		sp.position = Vector2(col * TILE, row_y)
		sp.z_index = z; sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sp)

# ── Building ──────────────────────────────────────────────────────────────────

func _build_building() -> void:
	var tex := load(BUILDING_PATH) as Texture2D
	if not tex: push_warning("Scene1: missing building"); return
	var sp := Sprite2D.new()
	sp.texture = tex; sp.centered = false
	sp.position = Vector2((GAME_W - tex.get_width()) / 2.0, BUILDING_BASE_Y - tex.get_height())
	sp.z_index = 0; sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sp)

# ── Physics ───────────────────────────────────────────────────────────────────

func _build_physics() -> void:
	_solid_box(Vector2(GAME_W / 2.0, GROUND_Y + 150.0), Vector2(GAME_W * 2.0, 300.0))
	_solid_box(Vector2(-16.0,         GAME_H / 2.0),    Vector2(32.0, GAME_H * 2.0))
	_solid_box(Vector2(GAME_W + 16.0, GAME_H / 2.0),   Vector2(32.0, GAME_H * 2.0))

func _solid_box(center: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new(); var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new(); rs.size = size
	cs.position = center; cs.shape = rs; b.add_child(cs); add_child(b)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var ps := load(PLAYER_SCENE) as PackedScene
	if not ps: push_warning("Scene1: missing Player.tscn"); return
	_player = ps.instantiate() as CharacterBody2D
	var sx: float = Globals.spawn_x if Globals.from_transition else 300.0
	Globals.from_transition = false
	_player.position = Vector2(sx, GROUND_Y - 64.0)
	_player.z_index  = 5
	add_child(_player)
	# Camera2D follows player within scene bounds
	var cam := Camera2D.new()
	cam.limit_left   = 0
	cam.limit_right  = GAME_W
	cam.limit_top    = 0
	cam.limit_bottom = GAME_H
	cam.position_smoothing_enabled = false
	_player.add_child(cam)
	cam.reset_smoothing()

# ── Oswin NPC ─────────────────────────────────────────────────────────────────

func _build_oswin_npc() -> void:
	# Placeholder body — brownish rectangle standing on the ground
	var body := ColorRect.new()
	body.color    = Color(0.55, 0.38, 0.18)
	body.size     = Vector2(OSWIN_W, OSWIN_H)
	body.position = Vector2(OSWIN_X - OSWIN_W * 0.5, GROUND_Y - OSWIN_H)
	body.z_index  = 4
	add_child(body)

	# "Oswin" name label
	var nl := Label.new()
	nl.text     = "Oswin"
	nl.position = Vector2(OSWIN_X - 28, GROUND_Y - OSWIN_H - 30)
	nl.z_index  = 10
	nl.add_theme_font_size_override("font_size", 18)
	nl.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	nl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	nl.add_theme_constant_override("shadow_offset_x", 2)
	nl.add_theme_constant_override("shadow_offset_y", 2)
	add_child(nl)

	# Proximity trigger
	var area := Area2D.new()
	area.position = Vector2(OSWIN_X, GROUND_Y - OSWIN_H * 0.5)
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new(); ci.radius = OSWIN_R
	cs.shape = ci; area.add_child(cs); add_child(area)

	area.body_entered.connect(func(b: Node2D) -> void:
		if b.is_in_group("player"):
			_near_oswin = true
			if _oswin_tip: _oswin_tip.visible = true)
	area.body_exited.connect(func(b: Node2D) -> void:
		if b.is_in_group("player"):
			_near_oswin = false
			if _oswin_tip: _oswin_tip.visible = false)

	# "E — Browse Wares" hint
	_oswin_tip = Label.new()
	_oswin_tip.text    = "E  —  Browse Wares"
	_oswin_tip.position = Vector2(OSWIN_X - 90, GROUND_Y - OSWIN_H - 56)
	_oswin_tip.visible  = false
	_oswin_tip.z_index  = 30
	_oswin_tip.add_theme_font_size_override("font_size", 17)
	_oswin_tip.add_theme_color_override("font_color",        Color(0.97, 0.93, 0.84))
	_oswin_tip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_oswin_tip.add_theme_constant_override("shadow_offset_x", 2)
	_oswin_tip.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_oswin_tip)

# ── Shop panel (Oswin) ────────────────────────────────────────────────────────

func _build_shop_panel() -> void:
	_shop_layer         = CanvasLayer.new()
	_shop_layer.layer   = 50
	_shop_layer.visible = false
	add_child(_shop_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.68)
	dim.size  = Vector2(GAME_W, GAME_H); _shop_layer.add_child(dim)

	const PX := 530; const PY := 180; const PW := 860; const PH := 680
	var panel := Panel.new()
	panel.position = Vector2(PX, PY); panel.size = Vector2(PW, PH)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.941, 0.875, 0.710)
	sty.border_color = Color(0.357, 0.216, 0.090)
	sty.set_border_width_all(5)
	panel.add_theme_stylebox_override("panel", sty); _shop_layer.add_child(panel)

	var title := Label.new()
	title.text = "Oswin's Wares"; title.position = Vector2(PX + PW / 2 - 200, PY + 18)
	title.size = Vector2(400, 60); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.357, 0.204, 0.090))
	_shop_layer.add_child(title)

	_shop_gold_lbl = Label.new()
	_shop_gold_lbl.position = Vector2(PX + PW - 220, PY + 20)
	_shop_gold_lbl.size = Vector2(200, 44)
	_shop_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shop_gold_lbl.add_theme_font_size_override("font_size", 24)
	_shop_gold_lbl.add_theme_color_override("font_color", Color(0.357, 0.204, 0.090))
	_shop_layer.add_child(_shop_gold_lbl)

	var hint := Label.new()
	hint.text = "↑ ↓  select     E  buy     Esc  close"
	hint.position = Vector2(PX + 20, PY + PH - 44)
	hint.size = Vector2(PW - 40, 36); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.400, 0.300, 0.180))
	_shop_layer.add_child(hint)

	var div := ColorRect.new()
	div.color = Color(0.357, 0.216, 0.090)
	div.size = Vector2(PW - 40, 2); div.position = Vector2(PX + 20, PY + 78); _shop_layer.add_child(div)

	const ROW_H := 116; const ROW_Y := PY + 90; const ROW_X := PX + 24
	_shop_rows.clear()
	for i in range(SHOP_ITEMS.size()):
		var item: Dictionary = SHOP_ITEMS[i]
		var ry := ROW_Y + i * ROW_H
		var rp := Panel.new()
		rp.position = Vector2(ROW_X, ry); rp.size = Vector2(PW - 48, ROW_H - 10)
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0,0,0,0); rs.border_color = Color(0.357,0.216,0.090)
		rs.set_border_width_all(3); rp.add_theme_stylebox_override("panel", rs)
		_shop_layer.add_child(rp)
		var nl2 := Label.new()
		nl2.text = item["name"]; nl2.position = Vector2(ROW_X+16, ry+10)
		nl2.add_theme_font_size_override("font_size", 26)
		nl2.add_theme_color_override("font_color", Color(0.169,0.106,0.059))
		_shop_layer.add_child(nl2)
		var dl := Label.new()
		dl.text = item.get("desc",""); dl.position = Vector2(ROW_X+16, ry+48)
		dl.add_theme_font_size_override("font_size", 18)
		dl.add_theme_color_override("font_color", Color(0.290,0.200,0.100))
		_shop_layer.add_child(dl)
		var pl := Label.new()
		pl.text = "%d gold" % item["price"]; pl.position = Vector2(ROW_X+PW-150, ry+28)
		pl.size = Vector2(120,40); pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pl.add_theme_font_size_override("font_size", 24)
		pl.add_theme_color_override("font_color", Color(0.450,0.300,0.050))
		_shop_layer.add_child(pl)
		_shop_rows.append({"panel": rp, "style": rs, "name_lbl": nl2, "price_lbl": pl})

func _open_shop() -> void:
	_shop_visible = true; _shop_idx = 0
	_shop_layer.visible = true; _refresh_shop()

func _close_shop() -> void:
	_shop_visible = false; _shop_layer.visible = false

func _refresh_shop() -> void:
	_shop_gold_lbl.text = "Gold: %d" % Globals.player_gold
	for i in range(_shop_rows.size()):
		var row: Dictionary = _shop_rows[i]
		var item: Dictionary = SHOP_ITEMS[i]
		var sel:    bool         = (i == _shop_idx)
		var afford: bool         = Globals.player_gold >= (item["price"] as int)
		var rs:     StyleBoxFlat = row["style"] as StyleBoxFlat
		rs.bg_color     = Color(0.88,0.78,0.56,0.7) if sel else Color(0,0,0,0)
		rs.border_color = Color(0.16,0.08,0.04)     if sel else Color(0.60,0.44,0.26)
		rs.set_border_width_all(4 if sel else 2)
		var nc: Color = Color(0.10,0.06,0.03) if afford else Color(0.55,0.40,0.28)
		(row["name_lbl"]  as Label).add_theme_color_override("font_color", nc)
		var pc: Color
		if not afford:    pc = Color(0.72,0.25,0.20)
		elif sel:         pc = Color(0.30,0.55,0.15)
		else:             pc = Color(0.45,0.30,0.05)
		(row["price_lbl"] as Label).add_theme_color_override("font_color", pc)

func _try_buy(idx: int) -> void:
	var item: Dictionary = SHOP_ITEMS[idx]
	if not Globals.spend_gold(item["price"] as int): return
	var copy := item.duplicate(true)
	copy.erase("price"); copy.erase("desc")
	Globals.add_item(copy); _refresh_shop()

# ── HUD (CanvasLayer — always fixed to screen, never moves with camera) ─────────

func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)

	# Dark strip backdrop at bottom
	var strip := ColorRect.new()
	strip.color    = Color(0.04, 0.04, 0.04, 0.88)
	strip.size     = Vector2(GAME_W, 64)
	strip.position = Vector2(0, GAME_H - 64)
	cl.add_child(strip)

	# HP bar background
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.1, 0.04, 0.04, 0.9)
	bar_bg.size     = Vector2(180, 16)
	bar_bg.position = Vector2(24, GAME_H - 40)
	cl.add_child(bar_bg)

	# HP bar fill
	_hud_hp_bar = ColorRect.new()
	_hud_hp_bar.color    = Color(0.87, 0.20, 0.20)
	_hud_hp_bar.size     = Vector2(176, 12)
	_hud_hp_bar.position = Vector2(26, GAME_H - 38)
	cl.add_child(_hud_hp_bar)

	# "HP" tag
	var hp_tag := Label.new()
	hp_tag.text     = "HP"
	hp_tag.position = Vector2(24, GAME_H - 60)
	hp_tag.add_theme_font_size_override("font_size", 14)
	hp_tag.add_theme_color_override("font_color", Color(0.87, 0.20, 0.20))
	cl.add_child(hp_tag)

	# HP value
	_hud_hp_lbl = Label.new()
	_hud_hp_lbl.text     = "10 / 10"
	_hud_hp_lbl.position = Vector2(212, GAME_H - 42)
	_hud_hp_lbl.add_theme_font_size_override("font_size", 14)
	_hud_hp_lbl.add_theme_color_override("font_color", Color(0.96, 0.89, 0.71))
	cl.add_child(_hud_hp_lbl)

	# Gold
	_hud_gold = Label.new()
	_hud_gold.text     = "Gold: 50"
	_hud_gold.position = Vector2(GAME_W - 180, GAME_H - 48)
	_hud_gold.add_theme_font_size_override("font_size", 20)
	_hud_gold.add_theme_color_override("font_color", Color(0.96, 0.89, 0.45))
	cl.add_child(_hud_gold)

	# Location name (centered)
	var loc := Label.new()
	loc.text     = "Millhaven"
	loc.position = Vector2(GAME_W / 2 - 100, GAME_H - 52)
	loc.size     = Vector2(200, 44)
	loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc.add_theme_font_size_override("font_size", 22)
	loc.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
	cl.add_child(loc)

	# Controls hint
	var ctrl := Label.new()
	ctrl.text     = "Move: A/D   Jump: Space   Dash: Shift   Menu: M"
	ctrl.position = Vector2(24, GAME_H - 22)
	ctrl.add_theme_font_size_override("font_size", 13)
	ctrl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
	cl.add_child(ctrl)

# ── Menu ──────────────────────────────────────────────────────────────────────

func _spawn_menu() -> void:
	var MenuScript: Variant = load("res://scripts/MenuPanel.gd")
	if not MenuScript:
		push_warning("Scene1: MenuPanel.gd not found"); return
	_menu = MenuScript.new()
	if not is_instance_valid(_menu):
		push_warning("Scene1: MenuPanel instantiation failed"); _menu = null; return
	add_child(_menu)

# ── Process ───────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	# Update HUD
	if _hud_hp_bar and _hud_hp_lbl:
		var ratio := float(Globals.player_health) / float(maxi(Globals.player_max_health, 1))
		_hud_hp_bar.size.x = 176.0 * ratio
		_hud_hp_lbl.text   = "%d / %d" % [Globals.player_health, Globals.player_max_health]
	if _hud_gold:
		_hud_gold.text = "Gold: %d" % Globals.player_gold

	# Shop navigation while open
	if _shop_visible:
		if Input.is_action_just_pressed("ui_cancel"):
			_close_shop()
		elif Input.is_action_just_pressed("move_up"):
			_shop_idx = wrapi(_shop_idx - 1, 0, SHOP_ITEMS.size()); _refresh_shop()
		elif Input.is_action_just_pressed("move_down"):
			_shop_idx = wrapi(_shop_idx + 1, 0, SHOP_ITEMS.size()); _refresh_shop()
		elif Input.is_action_just_pressed("interact"):
			_try_buy(_shop_idx)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	# M key — toggle inventory menu
	if event.is_action_pressed("menu_toggle"):
		if _menu:
			if _menu.visible: _menu.call("close")
			else:             _menu.call("open")
		get_viewport().set_input_as_handled()
		return

	# E key — interact with Oswin (only when shop is closed and menu is closed)
	if event.is_action_pressed("interact") and _near_oswin \
			and not _shop_visible \
			and not (_menu and _menu.visible):
		_open_shop()
		get_viewport().set_input_as_handled()

# ── Room transitions (called by any Door node placed in this scene) ────────────

func change_room(room_scene: PackedScene, spawn_name: String) -> void:
	Globals.target_spawn      = spawn_name
	Globals.return_scene_path = "res://scenes/Scene1.tscn"
	get_tree().change_scene_to_packed(room_scene)
