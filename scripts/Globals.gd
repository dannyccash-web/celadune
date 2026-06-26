extends Node
## Global game state that persists across room changes.
## Kept deliberately small — this is the place to store things the whole game
## needs to know about (which room we're entering, where to spawn, abilities).

# Name of the spawn Marker2D the player should appear at in the next room.
# Each room contains Marker2D nodes; a Door sets this before changing rooms.
var target_spawn: String = "Start"

# Player abilities — flip these on as the player earns them. The controller
# already checks them, so unlocking double-jump/dash is a one-line change.
var abilities := {
	"double_jump": true,
	"dash": true,
	"wall_jump": true,
}

func has_ability(name: String) -> bool:
	return abilities.get(name, false)

# ── Story flags ───────────────────────────────────────────────────────────────
# Simple named on/off switches that record story progress. NPCs can set a flag
# when a conversation ends, and gate different dialogue on whether a flag is set.
# Example: Globals.set_flag("met_elder"); if Globals.has_flag("met_elder"): ...
var flags := {}

func set_flag(name: String, value: bool = true) -> void:
	flags[name] = value

func has_flag(name: String) -> bool:
	return flags.get(name, false)
