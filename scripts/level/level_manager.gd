## level_manager.gd
## Orchestrates stall progression, the rush timer, and the level-complete flow.
##
## Scene tree expectation:
##   LevelManager (this script)
##   ├─ Stall0 (Node3D)  ← contains TaskManager, CleanableSurface, etc.
##   ├─ Stall1 (Node3D)
##   └─ Stall2 (Node3D)
##
## The LevelManager activates one stall at a time, listens for stall_complete,
## then advances to the next stall.  When all stalls are done it triggers the
## level-complete screen.

class_name LevelManager
extends Node

# -------------------------------------------------
# Signals
signal level_complete(score_data: Dictionary)
signal stall_activated(stall_index: int)
signal timer_updated(seconds_remaining: float)

# -------------------------------------------------
@export var total_time: float = 180.0          # Seconds before rush arrives
@export var stall_count: int = 3

## NodePaths to each stall root (each must have a TaskManager child)
@export var stall_nodes: Array[NodePath] = []

## UI references
@export var level_complete_screen: Control
@export var hud: Control

# -------------------------------------------------
# State
var current_stall_index: int = 0
var time_remaining: float = 0.0
var _task_managers: Array = []
var _level_started: bool = false
var _level_finished: bool = false
var _stalls_complete: int = 0

# Per-stall timing (for score calculation)
var _stall_start_times: Array[float] = []
var _stall_finish_times: Array[float] = []

# -------------------------------------------------
func _ready() -> void:
	time_remaining = total_time

	# Resolve stall node paths → TaskManager references
	for path in stall_nodes:
		var stall := get_node(path)
		if stall == null:
			push_warning("LevelManager: stall node not found at path %s" % path)
			continue
		var tm = stall.find_child("TaskManager", true, false)
		if tm == null:
			push_warning("LevelManager: no TaskManager found under stall %s" % path)
			continue
		tm.stall_complete.connect(_on_stall_complete)
		_task_managers.append(tm)

	# Deactivate all stalls visually; activate the first
	_set_all_stalls_visible(false)
	start_level()

# -------------------------------------------------
func _process(delta: float) -> void:
	if not _level_started or _level_finished:
		return

	time_remaining -= delta
	emit_signal("timer_updated", time_remaining)

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_end_level(false)   # Time's up — rush arrived

# -------------------------------------------------
func start_level() -> void:
	_level_started = true
	_level_finished = false
	_stalls_complete = 0
	current_stall_index = 0
	time_remaining = total_time
	_stall_start_times.clear()
	_stall_finish_times.clear()

	_activate_stall(0)

# -------------------------------------------------
func _activate_stall(index: int) -> void:
	if index >= _task_managers.size():
		return

	current_stall_index = index
	_stall_start_times.append(total_time - time_remaining)

	# Make the stall visible / interactable
	if index < stall_nodes.size():
		var stall := get_node(stall_nodes[index])
		if stall:
			stall.visible = true

	emit_signal("stall_activated", index)

# -------------------------------------------------
func _on_stall_complete(stall_index: int) -> void:
	_stall_finish_times.append(total_time - time_remaining)
	_stalls_complete += 1

	# Advance to the next stall
	var next := stall_index + 1
	if next < _task_managers.size():
		_activate_stall(next)
	else:
		# All stalls done!
		_end_level(true)

# -------------------------------------------------
func _end_level(success: bool) -> void:
	_level_finished = true

	var score_data := _calculate_score(success)
	emit_signal("level_complete", score_data)

	if level_complete_screen:
		level_complete_screen.visible = true
		if level_complete_screen.has_method("show_results"):
			level_complete_screen.show_results(score_data)

# -------------------------------------------------
## Calculates a score and star rating based on time and completion.
func _calculate_score(success: bool) -> Dictionary:
	var completion_bonus := 500 * _stalls_complete
	var time_bonus := int(time_remaining * 2.0) if success else 0
	var total_score := completion_bonus + time_bonus

	var stars := 0
	if success:
		var percent_time_left := time_remaining / total_time
		if percent_time_left >= 0.5:
			stars = 3
		elif percent_time_left >= 0.25:
			stars = 2
		else:
			stars = 1

	return {
		"success":          success,
		"stalls_complete":  _stalls_complete,
		"time_remaining":   time_remaining,
		"score":            total_score,
		"stars":            stars,
	}

# -------------------------------------------------
func _set_all_stalls_visible(visible_flag: bool) -> void:
	for path in stall_nodes:
		var stall := get_node_or_null(path)
		if stall:
			stall.visible = visible_flag
