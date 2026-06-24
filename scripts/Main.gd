extends Node2D

func _ready() -> void:
	# Straight to forest for now; title screen comes later
	get_tree().change_scene_to_file("res://scenes/Forest.tscn")
