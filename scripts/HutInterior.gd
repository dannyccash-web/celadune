extends Node2D
# DIAGNOSTIC — minimal stub to test if scene loads at all

func _ready() -> void:
	# Layer 0 CanvasLayer — renders over everything, no camera needed
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)

	var bg := ColorRect.new()
	bg.color    = Color(0.12, 0.08, 0.05)
	bg.size     = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	cl.add_child(bg)

	var lbl := Label.new()
	lbl.text     = "Interior loading…"
	lbl.position = Vector2(800, 500)
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	cl.add_child(lbl)

	# Exit on E
	set_process(true)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/Forest.tscn")
