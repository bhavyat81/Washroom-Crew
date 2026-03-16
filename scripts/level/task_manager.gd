## task_manager.gd
## Manages the per-stall task checklist.
##
## One TaskManager node lives inside each stall (or is created by LevelManager).
## It holds references to the stall's CleanableSurface, FoamSystem, and
## interactable objects, and tracks completion of each task.
##
## Emit "stall_complete" when all tasks are done.

class_name TaskManager
extends Node

# -------------------------------------------------
# Signals
signal stall_complete(stall_index: int)
signal task_updated(task_id: String, completed: bool)

# -------------------------------------------------
# Stall index (set by LevelManager)
@export var stall_index: int = 0

# References to this stall's components
@export var cleanable_surface: CleanableSurface
@export var foam_system: FoamSystem
@export var tissue_holder: TissueHolder
@export var soap_dispenser: SoapDispenser
@export var trash_bin: TrashBin

# Task completion state
var tasks: Dictionary = {
	"clean_surface": false,
	"foam_applied":  false,
	"tissue":        false,
	"soap":          false,
	"trash":         false,
}

# -------------------------------------------------
func _ready() -> void:
	# Connect signals from each component
	if cleanable_surface:
		cleanable_surface.surface_clean.connect(_on_surface_clean)

	if foam_system:
		foam_system.foam_complete.connect(_on_foam_complete)

	if tissue_holder:
		tissue_holder.task_completed.connect(_on_tissue_replaced)

	if soap_dispenser:
		soap_dispenser.task_completed.connect(_on_soap_refilled)

	if trash_bin:
		trash_bin.task_completed.connect(_on_trash_changed)

# -------------------------------------------------
## Returns true when every required task is done.
func all_tasks_complete() -> bool:
	for key in tasks:
		if not tasks[key]:
			return false
	return true

# -------------------------------------------------
## Resets all tasks and component states for re-use.
func reset() -> void:
	for key in tasks:
		tasks[key] = false

	if cleanable_surface:
		cleanable_surface.reset()
	if foam_system:
		foam_system.reset()
	if tissue_holder:
		tissue_holder.reset()
	if soap_dispenser:
		soap_dispenser.reset()
	if trash_bin:
		trash_bin.reset()

# -------------------------------------------------
## Returns a list of task names that are not yet completed.
func get_pending_tasks() -> Array[String]:
	var pending: Array[String] = []
	for key in tasks:
		if not tasks[key]:
			pending.append(key)
	return pending

# -------------------------------------------------
# Internal signal handlers

func _on_surface_clean(_surface: CleanableSurface) -> void:
	_complete_task("clean_surface")

func _on_foam_complete() -> void:
	_complete_task("foam_applied")

func _on_tissue_replaced(_holder: TissueHolder) -> void:
	_complete_task("tissue")

func _on_soap_refilled(_dispenser: SoapDispenser) -> void:
	_complete_task("soap")

func _on_trash_changed(_bin: TrashBin) -> void:
	_complete_task("trash")

# -------------------------------------------------
func _complete_task(task_id: String) -> void:
	if tasks.has(task_id) and not tasks[task_id]:
		tasks[task_id] = true
		emit_signal("task_updated", task_id, true)

		if all_tasks_complete():
			emit_signal("stall_complete", stall_index)
