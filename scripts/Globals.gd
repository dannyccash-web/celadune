extends Node
## Global game state — persists across all scene transitions.
## This is the single source of truth for player stats, inventory,
## quest state, reputation, economy, and ability flags.

# ── Constants ─────────────────────────────────────────────────────────────────
const TOWN_NAME := "Millhaven"

# Reputation descriptors (index = reputation value 1–7)
const REP_LABELS := [
	"",            # 0 unused
	"Reviled",     # 1
	"Disliked",    # 2
	"Neutral",     # 3
	"Respected",   # 4
	"Admired",     # 5
	"Celebrated",  # 6
	"Legendary",   # 7
]

# ── Fonts ─────────────────────────────────────────────────────────────────────
var FONT_TITLE: Font
var FONT_MONO:  Font

# ── Scene routing ─────────────────────────────────────────────────────────────
var target_spawn:       String = "Start"  # Marker2D name for room-based transitions
var spawn_x:            float  = 300.0   # X position for overworld spawn
var from_transition:    bool   = false   # true = skip intro, just place player
var interior_config_id: String = ""      # which building interior to render
var current_music_path: String = ""      # so interiors can continue outdoor track

# ── Player stats (base values; effective = base + equipment bonuses) ───────────
var player_health:      int = 10
var player_max_health:  int = 10
var player_attack_base: int = 1    # unarmed
var player_defense_base: int = 0

# ── Economy ───────────────────────────────────────────────────────────────────
var player_gold: int = 50  # 50 starting gold for testing; tune later

# ── Reputation (1 hostile → 7 legendary) ─────────────────────────────────────
var player_reputation: int = 4   # start Respected

# ── World flags ───────────────────────────────────────────────────────────────
var farm_dog_fled: bool = false
var city_dog_fled: bool = false

# ── Quest state ───────────────────────────────────────────────────────────────
# "" | "declined" | "accepted" | "onionsEaten" | "paymentPending" | "complete"
var quest_state: String = ""
var story_flags: Dictionary = {}

# ── Inventory & equipment ─────────────────────────────────────────────────────
# Each item: { name, texture (res:// path or ""), price, actions: [...], [slot], [stat_bonus: {}] }
var inventory:  Array = []
var equipment:  Array = []  # items in the equipment list (owned but separate from equip slots)
var equipped:   Dictionary = {}  # slot_name → item dict  e.g. "weapon" → {name: "Iron Sword", ...}

# ── Abilities ─────────────────────────────────────────────────────────────────
var abilities := {
	"double_jump": true,
	"dash":        true,
	"wall_jump":   true,
	"attack":      true,
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_fonts()

func _load_fonts() -> void:
	var title_path := "res://assets/fonts/MacondoSwashCaps-Regular.ttf"
	var mono_path  := "res://assets/fonts/RobotoMono-Regular.ttf"
	var tf := load(title_path)
	if tf is Font: FONT_TITLE = tf
	var mf := load(mono_path)
	if mf is Font: FONT_MONO = mf

# ── Ability helpers ───────────────────────────────────────────────────────────

func has_ability(name: String) -> bool:
	return abilities.get(name, false)

# ── Stat helpers ──────────────────────────────────────────────────────────────

## Effective attack = base + weapon bonus
func get_attack() -> int:
	var bonus := 0
	var w = equipped.get("weapon", null)
	if w: bonus += w.get("stat_bonus", {}).get("attack", 0)
	return player_attack_base + bonus

## Effective defense = base + armor bonus
func get_defense() -> int:
	var bonus := 0
	var a = equipped.get("armor", null)
	if a: bonus += a.get("stat_bonus", {}).get("defense", 0)
	return player_defense_base + bonus

## Effective jump bonus (0 = normal, positive = extra velocity)
func get_jump_bonus() -> int:
	var bonus := 0
	for slot in equipped.values():
		bonus += slot.get("stat_bonus", {}).get("jump", 0)
	return bonus

## Take damage. Returns true if player died.
func take_damage(amount: int) -> bool:
	var eff_dmg := max(1, amount - get_defense())
	player_health = max(0, player_health - eff_dmg)
	return player_health <= 0

## Heal player.
func heal(amount: int) -> void:
	player_health = min(player_max_health, player_health + amount)

# ── Economy helpers ────────────────────────────────────────────────────────────

func add_gold(amount: int) -> void:
	player_gold += amount

## Returns true if gold was available and spent.
func spend_gold(amount: int) -> bool:
	if player_gold < amount:
		return false
	player_gold -= amount
	return true

# ── Reputation helpers ─────────────────────────────────────────────────────────

## delta can be fractional (e.g. 0.5); internally stored as float, displayed as int.
var _rep_float: float = 4.0

func change_reputation(delta: float) -> void:
	_rep_float = clampf(_rep_float + delta, 1.0, 7.0)
	player_reputation = int(round(_rep_float))

func rep_label() -> String:
	return REP_LABELS[clampi(player_reputation, 1, 7)]

# ── Inventory helpers ─────────────────────────────────────────────────────────

func add_item(item: Dictionary) -> void:
	inventory.append(item)

func remove_item(item_name: String) -> void:
	for i in range(inventory.size() - 1, -1, -1):
		if inventory[i]["name"] == item_name:
			inventory.remove_at(i)
			return

func has_item(item_name: String) -> bool:
	for it in inventory:
		if it["name"] == item_name:
			return true
	return false

# ── Equipment helpers ─────────────────────────────────────────────────────────

## Move item from inventory to an equipment slot. Returns true on success.
func equip_item(item: Dictionary) -> bool:
	var slot: String = item.get("slot", "")
	if slot == "": return false
	# Un-equip whatever's in that slot first (move back to inventory)
	if equipped.has(slot):
		_unequip_slot(slot)
	# Remove from inventory and mark as equipped
	remove_item(item["name"])
	equipped[slot] = item
	return true

## Move the equipped item in a slot back to inventory.
func unequip_slot(slot: String) -> void:
	_unequip_slot(slot)

func _unequip_slot(slot: String) -> void:
	if not equipped.has(slot): return
	var it: Dictionary = equipped[slot]
	it["actions"] = ["Equip", "Drop"]
	inventory.append(it)
	equipped.erase(slot)

## List equipped items as an array (for MenuPanel Equipment tab).
func equipped_list() -> Array:
	var result := []
	for slot in ["weapon", "armor", "boots"]:
		if equipped.has(slot):
			var item: Dictionary = equipped[slot].duplicate()
			item["_slot"] = slot
			item["actions"] = ["Unequip"]
			result.append(item)
	return result

# ── Save / load (simple Dictionary to file) ──────────────────────────────────

const SAVE_PATH := "user://celadune_save.cfg"

func save_game() -> void:
	var data := {
		"player_health":      player_health,
		"player_max_health":  player_max_health,
		"player_attack_base": player_attack_base,
		"player_defense_base": player_defense_base,
		"player_gold":        player_gold,
		"player_reputation":  player_reputation,
		"_rep_float":         _rep_float,
		"farm_dog_fled":      farm_dog_fled,
		"city_dog_fled":      city_dog_fled,
		"quest_state":        quest_state,
		"story_flags":        story_flags,
		"inventory":          inventory,
		"equipped":           equipped,
		"abilities":          abilities,
		"spawn_x":            spawn_x,
		"interior_config_id": interior_config_id,
		"current_music_path": current_music_path,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return false
	var text := f.get_as_text(); f.close()
	var result := JSON.parse_string(text)
	if result == null: return false
	var data: Dictionary = result
	player_health      = data.get("player_health",      10)
	player_max_health  = data.get("player_max_health",  10)
	player_attack_base = data.get("player_attack_base", 1)
	player_defense_base = data.get("player_defense_base", 0)
	player_gold        = data.get("player_gold",        0)
	player_reputation  = data.get("player_reputation",  4)
	_rep_float         = data.get("_rep_float",         4.0)
	farm_dog_fled      = data.get("farm_dog_fled",      false)
	city_dog_fled      = data.get("city_dog_fled",      false)
	quest_state        = data.get("quest_state",        "")
	story_flags        = data.get("story_flags",        {})
	inventory          = data.get("inventory",          [])
	equipped           = data.get("equipped",           {})
	abilities          = data.get("abilities",          abilities)
	spawn_x            = data.get("spawn_x",            300.0)
	interior_config_id = data.get("interior_config_id", "")
	current_music_path = data.get("current_music_path", "")
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
