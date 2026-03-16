## main_menu.gd
## Main menu screen controller.
## Handles Play, Settings, and Quit buttons.

extends Control

# -------------------------------------------------
@onready var play_button: Button     = $VBoxContainer/PlayButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button     = $VBoxContainer/QuitButton
@onready var title_label: Label      = $TitleLabel
@onready var version_label: Label    = $VersionLabel

const GAME_LEVEL_SCENE: String = "res://scenes/game/game_level.tscn"

# -------------------------------------------------
func _ready() -> void:
	# Make sure cursor is visible on main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	version_label.text = "v0.1.0 — Alpha"

# -------------------------------------------------
func _on_play_pressed() -> void:
	# Transition to the first game level
	get_tree().change_scene_to_file(GAME_LEVEL_SCENE)

func _on_settings_pressed() -> void:
	# TODO: Show settings panel (audio, controls, graphics)
	push_warning("Settings panel not yet implemented.")

func _on_quit_pressed() -> void:
	get_tree().quit()
