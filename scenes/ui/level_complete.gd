## level_complete.gd
## Level complete / results screen.
## Shows star rating, score breakdown, and navigation buttons.

extends Control

# -------------------------------------------------
@onready var stars_label: Label        = $Panel/VBoxContainer/StarsLabel
@onready var score_label: Label        = $Panel/VBoxContainer/ScoreLabel
@onready var breakdown_label: Label    = $Panel/VBoxContainer/BreakdownLabel
@onready var next_button: Button       = $Panel/VBoxContainer/NextButton
@onready var menu_button: Button       = $Panel/VBoxContainer/MenuButton
@onready var result_title: Label       = $Panel/VBoxContainer/ResultTitle

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const GAME_LEVEL_SCENE: String = "res://scenes/game/game_level.tscn"

# -------------------------------------------------
func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# -------------------------------------------------
## Called by LevelManager / GameLevel when the level ends.
func show_results(score_data: Dictionary) -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var success: bool   = score_data.get("success", false)
	var stars: int      = score_data.get("stars", 0)
	var score: int      = score_data.get("score", 0)
	var stalls: int     = score_data.get("stalls_complete", 0)
	var time_left: float = score_data.get("time_remaining", 0.0)

	result_title.text = "✅ Level Complete!" if success else "⏰ Rush Arrived!"

	# Star display
	var star_str := ""
	for i in range(3):
		star_str += "⭐" if i < stars else "☆"
	stars_label.text = star_str

	score_label.text = "Score: %d" % score

	breakdown_label.text = (
		"Stalls cleaned: %d / 3\n" % stalls +
		"Time bonus: +%d pts\n" % (int(time_left * 2.0) if success else 0) +
		"Completion bonus: +%d pts" % (500 * stalls)
	)

	# Disable "Next" if level failed — player goes back to menu
	next_button.visible = success

# -------------------------------------------------
func _on_next_pressed() -> void:
	# TODO: Load the next level in the sequence
	get_tree().change_scene_to_file(GAME_LEVEL_SCENE)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
