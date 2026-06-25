extends Node

# ── Fonts ─────────────────────────────────────────────────────────────────────
const FONT_MONO  := preload("res://assets/fonts/RobotoMono-Regular.ttf")
const FONT_TITLE := preload("res://assets/fonts/MacondoSwashCaps-Regular.ttf")

# ── Town ──────────────────────────────────────────────────────────────────────
const TOWN_NAME := "Millhaven"

# ── Hero ──────────────────────────────────────────────────────────────────────
var selected_hero: String = "caelan"

# ── Player state ──────────────────────────────────────────────────────────────
var player_health:     int = 10
var player_max_health: int = 10
var player_gold:       int = 0
var player_reputation: int = 4   # 1–7 scale

# ── Inventory / Equipment ─────────────────────────────────────────────────────
# Each item: { "name": String, "texture": String (res:// path or ""), "actions": Array[String] }
var inventory: Array = []
var equipment: Array = []

# ── Quest ─────────────────────────────────────────────────────────────────────
# notOffered | declined | accepted | paymentPending | onionsEaten | complete
var quest_state: String = "notOffered"

# ── Story flags ───────────────────────────────────────────────────────────────
var story_flags: Dictionary = {
	"chef_onions_delivered":  false,
	"mirelle_quest_complete": false,
	"gold_given_to_mirelle":  null,
}

# ── Dog persistence ───────────────────────────────────────────────────────────
var farm_dog_fled: bool = false
var city_dog_fled: bool = false

# ── Scene spawn position ──────────────────────────────────────────────────────
var spawn_x: float = 680.0
var spawn_y: float = 768.0
var from_transition: bool = false
var interior_config_id: String = "mirelle_farmhouse"

# ─────────────────────────────────────────────────────────────────────────────

func has_item(item_name: String) -> bool:
	for item in inventory:
		if item["name"] == item_name:
			return true
	return false

func add_item(item: Dictionary) -> void:
	if has_item(item["name"]): return
	inventory.append(item.duplicate())

func remove_item(item_name: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["name"] == item_name:
			inventory.remove_at(i)
			return true
	return false

func add_gold(amount: int) -> void:
	player_gold = max(0, player_gold + amount)

func spend_gold(amount: int) -> bool:
	if player_gold < amount: return false
	player_gold -= amount
	return true

func change_reputation(delta: float) -> void:
	player_reputation = clampi(player_reputation + int(roundf(delta)), 1, 7)

func get_rep_group() -> String:
	if player_reputation <= 2: return "hostile"
	if player_reputation == 3: return "cold"
	if player_reputation == 4: return "neutral"
	if player_reputation <= 6: return "friendly"
	return "reverent"

func reset() -> void:
	player_health     = 10
	player_max_health = 10
	player_gold       = 0
	player_reputation = 4
	inventory         = []
	equipment         = []
	quest_state       = "notOffered"
	story_flags = {
		"chef_onions_delivered":  false,
		"mirelle_quest_complete": false,
		"gold_given_to_mirelle":  null,
	}
	farm_dog_fled      = false
	city_dog_fled      = false
	spawn_x            = 680.0
	spawn_y            = 768.0
	from_transition    = false
	interior_config_id = "mirelle_farmhouse"
