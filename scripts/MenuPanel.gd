extends CanvasLayer
## Parchment-style M-menu with Inventory / Equipment / Stats / Controls tabs.
## Call open() from any scene. Emits `closed` on close.

signal closed

const PANEL_X := 216
const PANEL_Y := 132
const PANEL_W := 1488
const PANEL_H := 816

const COL_PARCHMENT  := Color(0.941, 0.875, 0.710)
const COL_BORDER_OUT := Color(0.357, 0.216, 0.090)
const COL_BORDER_IN  := Color(0.855, 0.710, 0.416)
const COL_TAB_TXT    := Color(0.357, 0.204, 0.090)
const COL_TAB_ACT    := Color(0.239, 0.110, 0.051)
const COL_BODY       := Color(0.169, 0.106, 0.059)
const COL_SLOT       := COL_BORDER_IN
const COL_SLOT_SEL   := COL_BORDER_OUT
const COL_STAT_KEY   := Color(0.290, 0.141, 0.067)
const COL_STAT_VAL   := Color(0.169, 0.106, 0.059)

const PAGES := ["Inventory", "Equipment", "Stats", "Controls"]

var _page_idx:    int    = 0
var _item_idx:    int    = 0
var _mode:        String = "categories"   # categories | section | actions
var _action_idx:  int    = 0
var _just_opened: bool   = false

var _title_lbl:   Label
var _gold_lbl:    Label
var _tab_btns:    Array = []
var _grid_root:   Control
var _stats_root:  Control
var _ctrl_root:   Control
var _empty_lbl:   Label
var _action_root: Control

func _ready() -> void:
	layer = 60
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Dim overlay
	var dim := ColorRect.new()
	dim.color        = Color(0.020, 0.027, 0.039, 0.62)
	dim.size         = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Panel
	var panel := Panel.new()
	panel.position   = Vector2(PANEL_X, PANEL_Y)
	panel.size       = Vector2(PANEL_W, PANEL_H)
	var sty := StyleBoxFlat.new()
	sty.bg_color     = COL_PARCHMENT
	sty.border_color = COL_BORDER_OUT
	sty.set_border_width_all(4)
	panel.add_theme_stylebox_override("panel", sty)
	add_child(panel)

	# Inner border
	_add_border(PANEL_X + 9, PANEL_Y + 9, PANEL_W - 18, PANEL_H - 18, COL_BORDER_IN, 2)

	# Title
	_title_lbl = _label("Inventory", PANEL_X + 492, PANEL_Y + 67, 54, Globals.FONT_TITLE, COL_TAB_TXT)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Gold counter (top-right)
	_gold_lbl = _label("Gold: 0", PANEL_X + PANEL_W - 204, PANEL_Y + PANEL_H - 77, 28, Globals.FONT_TITLE, COL_TAB_TXT)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Hint
	_label("M / Esc to close", PANEL_X + PANEL_W - 48, PANEL_Y + 46, 19, Globals.FONT_MONO, Color(0.306, 0.216, 0.125)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Tab buttons (left column)
	const TAB_START_Y := 140
	for i in range(PAGES.size()):
		var tab := Panel.new()
		tab.position = Vector2(PANEL_X + 30, PANEL_Y + TAB_START_Y + i * 90)
		tab.size     = Vector2(264, 65)
		var ts := StyleBoxFlat.new()
		ts.bg_color     = Color(0, 0, 0, 0)
		ts.border_color = COL_BORDER_IN
		ts.set_border_width_all(3)
		tab.add_theme_stylebox_override("panel", ts)
		add_child(tab)
		var tl := _label(PAGES[i], PANEL_X + 162, PANEL_Y + TAB_START_Y + i * 90 + 30, 30, Globals.FONT_TITLE, COL_TAB_TXT)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tab_btns.append({"panel": tab, "label": tl, "style": ts})

	# Divider
	var div := ColorRect.new()
	div.color    = COL_BORDER_OUT
	div.size     = Vector2(2, PANEL_H - 144)
	div.position = Vector2(PANEL_X + 318, PANEL_Y + 72)
	add_child(div)

	# Content roots
	_grid_root = Control.new()
	_grid_root.position = Vector2(PANEL_X + 386, PANEL_Y + 122)
	_grid_root.size     = Vector2(PANEL_W - 386 - 43, PANEL_H - 140)
	add_child(_grid_root)

	_stats_root = Control.new()
	_stats_root.position = Vector2(PANEL_X + 386, PANEL_Y + 100)
	_stats_root.size     = Vector2(PANEL_W - 386 - 43, PANEL_H - 120)
	_stats_root.visible  = false
	add_child(_stats_root)

	_ctrl_root = Control.new()
	_ctrl_root.position = Vector2(PANEL_X + 386, PANEL_Y + 151)
	_ctrl_root.size     = Vector2(PANEL_W - 386 - 43, PANEL_H - 160)
	_ctrl_root.visible  = false
	add_child(_ctrl_root)
	_build_controls_text()

	_empty_lbl = _label("No items yet.", PANEL_X + 386, PANEL_Y + 180, 28, Globals.FONT_MONO, Color(0.365, 0.263, 0.133))
	_empty_lbl.visible = false

func _build_controls_text() -> void:
	var h1 := _label("KEYBOARD", 0, 0, 28, Globals.FONT_MONO, Color(0.247, 0.141, 0.067))
	_ctrl_root.add_child(h1)
	var kb := (
		"Arrow Left / A      Move left\n" +
		"Arrow Right / D     Move right\n" +
		"Space / W           Jump\n" +
		"Shift               Dash\n" +
		"Z                   Attack\n" +
		"E / Enter           Interact / Confirm\n" +
		"M                   Open / Close Menu\n" +
		"Esc                 Cancel / Close\n" +
		"Up / Down           Navigate menus"
	)
	var b1 := _label(kb, 0, 46, 24, Globals.FONT_MONO, Color(0.169, 0.106, 0.059))
	b1.autowrap_mode = TextServer.AUTOWRAP_WORD
	b1.size = Vector2(900, 400)
	_ctrl_root.add_child(b1)

func _label(text: String, x: float, y: float, size: int, font: Font, col: Color) -> Label:
	var l := Label.new()
	l.text     = text
	l.position = Vector2(x, y)
	if font: l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _add_border(x: float, y: float, w: float, h: float, col: Color, th: int) -> void:
	for r in [[x, y, w, th], [x, y+h-th, w, th], [x, y, th, h], [x+w-th, y, th, h]]:
		var cr := ColorRect.new(); cr.color = col
		cr.position = Vector2(r[0], r[1]); cr.size = Vector2(r[2], r[3])
		add_child(cr)

# ── Public API ─────────────────────────────────────────────────────────────────

func open() -> void:
	visible      = true
	_page_idx    = 0
	_item_idx    = 0
	_mode        = "categories"
	_just_opened = true
	_refresh()

func close() -> void:
	visible = false
	closed.emit()

# ── Input ──────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not visible: return
	if _just_opened: _just_opened = false; return

	if Input.is_action_just_pressed("ui_cancel") or _is_menu_key():
		if _mode == "actions":
			_mode = "section"; _refresh()
		elif _mode == "section":
			_mode = "categories"; _refresh()
		else:
			close()
		return

	if Input.is_action_just_pressed("move_up"):   _navigate(-1)
	if Input.is_action_just_pressed("move_down"):  _navigate(1)
	if Input.is_action_just_pressed("move_left"):
		if _mode == "actions":  _mode = "section";     _refresh()
		elif _mode == "section": _mode = "categories"; _refresh()
	if Input.is_action_just_pressed("move_right"):
		if _mode == "categories": _mode = "section"; _item_idx = 0; _refresh()

	if Input.is_action_just_pressed("interact"):
		if _mode == "categories":
			_mode = "section"; _item_idx = 0; _refresh()
		elif _mode == "section":
			_open_item_action()
		elif _mode == "actions":
			_perform_action()

func _is_menu_key() -> bool:
	return Input.is_action_just_pressed("menu_toggle") or Input.is_action_just_pressed("ui_cancel")

func _navigate(dir: int) -> void:
	var items := _current_items()
	match _mode:
		"categories":
			_page_idx = wrapi(_page_idx + dir, 0, PAGES.size())
			_item_idx = 0
		"section":
			if PAGES[_page_idx] not in ["Controls", "Stats"] and items.size() > 0:
				_item_idx = wrapi(_item_idx + dir, 0, items.size())
		"actions":
			var item := items[_item_idx] if _item_idx < items.size() else {}
			var acts: Array = item.get("actions", [])
			if acts.size() > 0:
				_action_idx = wrapi(_action_idx + dir, 0, acts.size())
	_refresh()

func _current_items() -> Array:
	match PAGES[_page_idx]:
		"Inventory": return Globals.inventory
		"Equipment": return Globals.equipped_list()
	return []

func _open_item_action() -> void:
	var items := _current_items()
	if _item_idx >= items.size(): return
	if items[_item_idx].get("actions", []).size() == 0: return
	_mode       = "actions"
	_action_idx = 0
	_refresh()

func _perform_action() -> void:
	var items := _current_items()
	if _item_idx >= items.size(): return
	var item    := items[_item_idx]
	var actions: Array = item.get("actions", [])
	if _action_idx >= actions.size(): return
	var action: String = actions[_action_idx]

	match action:
		"Eat":
			Globals.remove_item(item["name"])
			if item["name"] == "Onions" and Globals.quest_state == "accepted":
				Globals.quest_state = "onionsEaten"
			elif item.get("heal", 0) > 0:
				Globals.heal(item["heal"])
			_item_idx = clampi(_item_idx, 0, maxi(Globals.inventory.size() - 1, 0))

		"Equip":
			Globals.equip_item(item)
			_item_idx = 0

		"Unequip":
			var slot: String = item.get("_slot", item.get("slot", ""))
			if slot != "": Globals.unequip_slot(slot)
			_item_idx = 0

		"Drop":
			Globals.remove_item(item["name"])
			_item_idx = clampi(_item_idx, 0, maxi(Globals.inventory.size() - 1, 0))

	_mode = "section"
	_refresh()

# ── Refresh ────────────────────────────────────────────────────────────────────

func _refresh() -> void:
	# Tab highlights
	for i in range(_tab_btns.size()):
		var active := (i == _page_idx)
		var ts: StyleBoxFlat = _tab_btns[i]["style"]
		ts.border_color = COL_BORDER_OUT if active else COL_BORDER_IN
		ts.set_border_width_all(4 if active else 3)
		_tab_btns[i]["label"].add_theme_color_override("font_color", COL_TAB_ACT if active else COL_TAB_TXT)

	_title_lbl.text = PAGES[_page_idx]

	# Gold — shown on Inventory and Equipment
	var show_gold := PAGES[_page_idx] in ["Inventory", "Equipment"]
	_gold_lbl.visible = show_gold
	_gold_lbl.text    = "Gold: %d" % Globals.player_gold

	# Clear
	for c in _grid_root.get_children():  c.queue_free()
	for c in _stats_root.get_children(): c.queue_free()
	_empty_lbl.visible  = false
	_ctrl_root.visible  = false
	_grid_root.visible  = false
	_stats_root.visible = false

	match PAGES[_page_idx]:
		"Controls":
			_ctrl_root.visible = true
		"Stats":
			_stats_root.visible = true
			_build_stats_panel()
		"Inventory", "Equipment":
			_grid_root.visible = true
			_build_grid()

func _build_stats_panel() -> void:
	var eff_atk := Globals.get_attack()
	var eff_def := Globals.get_defense()
	var eff_jmp := Globals.get_jump_bonus()

	var rows := [
		["Health",     "%d / %d" % [Globals.player_health, Globals.player_max_health]],
		["Attack",     str(eff_atk) + (" (+%d equipped)" % (eff_atk - Globals.player_attack_base) if eff_atk > Globals.player_attack_base else "")],
		["Defense",    str(eff_def) + (" (+%d equipped)" % (eff_def - Globals.player_defense_base) if eff_def > Globals.player_defense_base else "")],
		["Jump Bonus", "+%d" % eff_jmp if eff_jmp > 0 else "None"],
		["Reputation", "%s (%d / 7)" % [Globals.rep_label(), Globals.player_reputation]],
		["Gold",       "%d" % Globals.player_gold],
		["", ""],   # spacer
		["ABILITIES", ""],
	]

	# Abilities
	for ab in Globals.abilities.keys():
		var label := ab.replace("_", " ").capitalize()
		var val   := "Unlocked" if Globals.abilities[ab] else "Locked"
		rows.append([label, val])

	# Equipped items
	rows.append(["", ""])
	rows.append(["EQUIPPED", ""])
	if Globals.equipped.is_empty():
		rows.append(["(nothing)", ""])
	else:
		for slot in Globals.equipped.keys():
			rows.append([slot.capitalize(), Globals.equipped[slot]["name"]])

	const ROW_H   := 42
	const KEY_X   := 0
	const VAL_X   := 360
	const KEY_SZ  := 28
	const VAL_SZ  := 26
	const HDR_SZ  := 22

	var y := 0
	for row in rows:
		var key: String = row[0]
		var val: String = row[1]
		if key == "" and val == "":
			y += 20; continue

		if key in ["ABILITIES", "EQUIPPED"]:
			# Header row
			var div := ColorRect.new()
			div.color    = COL_BORDER_IN
			div.size     = Vector2(900, 2)
			div.position = Vector2(KEY_X, y + 8)
			_stats_root.add_child(div)
			y += 14
			var hl := Label.new()
			hl.text     = key
			hl.position = Vector2(KEY_X, y)
			hl.add_theme_font_size_override("font_size", HDR_SZ)
			hl.add_theme_color_override("font_color", COL_STAT_KEY)
			if Globals.FONT_MONO: hl.add_theme_font_override("font", Globals.FONT_MONO)
			_stats_root.add_child(hl)
			y += ROW_H; continue

		var kl := Label.new()
		kl.text     = key
		kl.position = Vector2(KEY_X, y)
		kl.add_theme_font_size_override("font_size", KEY_SZ if key == key.to_upper() else VAL_SZ)
		kl.add_theme_color_override("font_color", COL_STAT_KEY)
		if Globals.FONT_TITLE: kl.add_theme_font_override("font", Globals.FONT_TITLE)
		_stats_root.add_child(kl)

		if val != "":
			var vl := Label.new()
			vl.text     = val
			vl.position = Vector2(VAL_X, y)
			vl.add_theme_font_size_override("font_size", VAL_SZ)
			vl.add_theme_color_override("font_color", COL_STAT_VAL)
			if Globals.FONT_MONO: vl.add_theme_font_override("font", Globals.FONT_MONO)
			_stats_root.add_child(vl)

		y += ROW_H

func _build_grid() -> void:
	var items := _current_items()
	if items.size() == 0:
		_empty_lbl.visible = true
		_empty_lbl.text = match PAGES[_page_idx]:
			"Equipment": "No equipment yet. Buy items at Oswin's shop."
			_: "No items yet."
		return

	const COLS   := 6
	const SLOT_SZ := 144
	const GAP_X  := 29
	const GAP_Y  := 36
	const STEP_X := SLOT_SZ + GAP_X
	const STEP_Y := SLOT_SZ + 48 + GAP_Y

	for idx in range(items.size()):
		var col := idx % COLS
		var row := idx / COLS
		var x   := float(col * STEP_X)
		var y   := float(row * STEP_Y)
		var selected := (_mode != "categories" and idx == _item_idx)

		var slot := Panel.new()
		slot.position = Vector2(x, y)
		slot.size     = Vector2(SLOT_SZ, SLOT_SZ)
		var ss := StyleBoxFlat.new()
		ss.bg_color     = Color(0, 0, 0, 0)
		ss.border_color = COL_SLOT_SEL if selected else COL_SLOT
		ss.set_border_width_all(4 if selected else 3)
		slot.add_theme_stylebox_override("panel", ss)
		_grid_root.add_child(slot)

		var item := items[idx]
		if item.get("texture", "") != "":
			var icon := TextureRect.new()
			icon.texture      = load(item["texture"])
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position     = Vector2(x + 22, y + 15)
			icon.size         = Vector2(100, 100)
			_grid_root.add_child(icon)

		# Stat summary badge
		if item.get("stat_bonus"):
			var badge_parts := []
			var sb: Dictionary = item["stat_bonus"]
			if sb.get("attack",  0) > 0: badge_parts.append("+%d ATK" % sb["attack"])
			if sb.get("defense", 0) > 0: badge_parts.append("+%d DEF" % sb["defense"])
			if sb.get("jump",    0) > 0: badge_parts.append("+%d JMP" % sb["jump"])
			if badge_parts.size() > 0:
				var badge := Label.new()
				badge.text     = " ".join(badge_parts)
				badge.position = Vector2(x + 4, y + 4)
				badge.add_theme_font_size_override("font_size", 14)
				badge.add_theme_color_override("font_color", Color(0.2, 0.55, 0.2))
				_grid_root.add_child(badge)

		var lbl := Label.new()
		lbl.text     = item["name"]
		lbl.position = Vector2(x + SLOT_SZ / 2, y + SLOT_SZ + 10)
		lbl.size     = Vector2(SLOT_SZ + 12, 48)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", COL_BODY)
		if Globals.FONT_MONO: lbl.add_theme_font_override("font", Globals.FONT_MONO)
		_grid_root.add_child(lbl)

		# Action popup
		if _mode == "actions" and selected:
			var actions: Array = item.get("actions", [])
			var am := Panel.new()
			am.position = Vector2(x + SLOT_SZ + 10, y)
			am.size     = Vector2(260, 50 + actions.size() * 46)
			var as_ := StyleBoxFlat.new()
			as_.bg_color     = COL_PARCHMENT
			as_.border_color = COL_BORDER_OUT
			as_.set_border_width_all(3)
			am.add_theme_stylebox_override("panel", as_)
			_grid_root.add_child(am)
			for ai in range(actions.size()):
				var asel := (ai == _action_idx)
				var al := Label.new()
				al.text     = actions[ai]
				al.position = Vector2(x + SLOT_SZ + 26, y + 14 + ai * 46)
				al.add_theme_font_size_override("font_size", 22)
				al.add_theme_color_override("font_color", COL_TAB_ACT if asel else COL_BODY)
				if Globals.FONT_MONO: al.add_theme_font_override("font", Globals.FONT_MONO)
				_grid_root.add_child(al)
