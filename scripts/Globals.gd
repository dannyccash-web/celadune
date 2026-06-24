extends Node

# ── Story flags ───────────────────────────────────────────────────────────────
var story_flags := {
	"chef_onions_delivered":    false,
	"mirelle_quest_complete":   false,
	"gold_given_to_mirelle":    null,
}

# ── Player inventory / state ───────────────────────────────────────────────────
var inventory: Array = []
var gold: int = 0
var selected_hero: String = "caelan"

# ── Town name ─────────────────────────────────────────────────────────────────
const TOWN_NAME := "Millhaven"
