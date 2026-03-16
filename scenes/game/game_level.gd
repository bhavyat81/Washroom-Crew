## game_level.gd
## Root script for the main game level scene.
## Wires together the LevelManager, HUD, Checklist, SprayTool ammo bar,
## and mobile touch controls.

extends Node3D

# -------------------------------------------------
@onready var level_manager: LevelManager = $LevelManager
@onready var hud: Control                = $UILayer/HUD
@onready var checklist: Control          = $UILayer/Checklist
@onready var level_complete: Control     = $UILayer/LevelComplete

# Stall root node names — must match the scene
const STALL_NODE_NAMES: Array[String] = ["Stall0", "Stall1", "Stall2"]
const STALL_NAMES: Array[String] = [
	"STALL 1 — The Messy One",
	"STALL 2 — The Clogged One",
	"STALL 3 — The Vandalized One",
]

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

	# Wire SprayTool ammo signal to HUD
	var spray_tool := get_node_or_null("Player/Head/Camera3D/SprayTool") as SprayTool
	if spray_tool and hud and hud.has_method("update_ammo"):
		spray_tool.ammo_changed.connect(hud.update_ammo)

	# Wire virtual joystick to player controller
	var joystick := get_node_or_null("TouchControls/VirtualJoystick")
	var player := get_node_or_null("Player")
	if joystick and player and player.has_method("set_joystick"):
		player.set_joystick(joystick)

# -------------------------------------------------
func _on_level_complete(score_data: Dictionary) -> void:
	if checklist:
		checklist.visible = false
	if level_complete:
		level_complete.visible = true
		if level_complete.has_method("show_results"):
			level_complete.show_results(score_data)

func _on_stall_activated(stall_index: int) -> void:
	# Update checklist stall label
	if checklist and checklist.has_method("set_active_stall"):
		checklist.set_active_stall(stall_index)

	# Update HUD stall name
	if hud and hud.has_method("set_stall_name"):
		if stall_index < STALL_NAMES.size():
			hud.set_stall_name(STALL_NAMES[stall_index])

	# Wire the active stall's TaskManager to the checklist
	if stall_index < STALL_NODE_NAMES.size():
		var stall := get_node_or_null(STALL_NODE_NAMES[stall_index])
		if stall:
			var tm := stall.find_child("TaskManager", true, false) as TaskManager
			if tm and checklist and checklist.has_method("connect_task_manager"):
				checklist.connect_task_manager(tm)

func _on_timer_updated(seconds_remaining: float) -> void:
	if hud and hud.has_method("update_timer"):
		hud.update_timer(seconds_remaining)

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# TODO: Show pause menu
		pass
