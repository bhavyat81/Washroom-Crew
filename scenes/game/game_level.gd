## game_level.gd
## Root script for the main game level scene.
## Wires together the LevelManager, HUD, and Checklist UI.

extends Node3D

# -------------------------------------------------
@onready var level_manager: LevelManager = $LevelManager
@onready var hud: Control                = $UILayer/HUD
@onready var checklist: Control          = $UILayer/Checklist
@onready var level_complete: Control     = $UILayer/LevelComplete

# -------------------------------------------------
func _ready() -> void:
	# Wire level manager signals to UI
	if level_manager:
		level_manager.level_complete.connect(_on_level_complete)
		level_manager.stall_activated.connect(_on_stall_activated)
		level_manager.timer_updated.connect(_on_timer_updated)

	# Hide level complete overlay at start
	if level_complete:
		level_complete.visible = false

	# Assign level complete screen to level manager
	if level_manager and level_complete:
		level_manager.level_complete_screen = level_complete

# -------------------------------------------------
func _on_level_complete(score_data: Dictionary) -> void:
	if checklist:
		checklist.visible = false
	if level_complete:
		level_complete.visible = true
		if level_complete.has_method("show_results"):
			level_complete.show_results(score_data)

func _on_stall_activated(stall_index: int) -> void:
	if checklist and checklist.has_method("set_active_stall"):
		checklist.set_active_stall(stall_index)

func _on_timer_updated(seconds_remaining: float) -> void:
	if hud and hud.has_method("update_timer"):
		hud.update_timer(seconds_remaining)

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# TODO: Show pause menu
		pass
