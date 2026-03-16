## checklist.gd
## Per-stall task checklist UI.
## Displays a dynamic list of tasks for the current stall.
## Connects to the active TaskManager and updates counts in real time.

extends Control

# -------------------------------------------------
# Stall names shown in the header
const STALL_NAMES: Array = [
	"STALL 1 — The Messy One",
	"STALL 2 — The Clogged One",
	"STALL 3 — The Vandalized One",
]

# Initial task labels per stall index (task_id → display text)
const STALL_TASK_CONFIGS: Array = [
	# Stall 0 — The Messy One
	{
		"stains":       "🧹 Clean floor stains (0/5)",
		"trash_items":  "🗑️ Pick up trash (0/3)",
		"toilet_flush": "🚽 Flush toilet",
		"drain_dirt":   "🚿 Push dirt to drain (0/4)",
	},
	# Stall 1 — The Clogged One
	{
		"stains": "🧹 Clean water puddle",
		"soap":   "🧴 Refill soap dispenser",
		"drain_dirt": "🚿 Push dirt to drain (0/4)",
	},
	# Stall 2 — The Vandalized One
	{
		"stains":        "🎨 Clean graffiti (0/3)",
		"trash_items":   "🗑️ Pick up trash (0/6)",
		"toilet_flush":  "🚽 Flush toilet",
		"drain_dirt":    "🚿 Push dirt to drain (0/4)",
	},
]

# -------------------------------------------------
@onready var stall_label: Label            = $Panel/VBoxContainer/StallLabel
@onready var task_container: VBoxContainer = $Panel/VBoxContainer/TaskContainer

# Runtime-created task row labels keyed by task_id
var _task_rows: Dictionary = {}

# Reference to the currently active TaskManager
var _task_manager = null
var _active_stall_index: int = 0

# -------------------------------------------------
func _ready() -> void:
	_build_task_rows(0)

# -------------------------------------------------
## Called by GameLevel when a new stall is activated.
func set_active_stall(stall_index: int) -> void:
	_active_stall_index = clamp(stall_index, 0, STALL_NAMES.size() - 1)
	stall_label.text = STALL_NAMES[_active_stall_index]
	_build_task_rows(_active_stall_index)

# -------------------------------------------------
## Called by GameLevel to wire the active stall's TaskManager.
func connect_task_manager(tm) -> void:
	# Disconnect previous manager
	if _task_manager and _task_manager.task_updated.is_connected(_on_task_updated):
		_task_manager.task_updated.disconnect(_on_task_updated)
	_task_manager = tm
	if _task_manager:
		_task_manager.task_updated.connect(_on_task_updated)
	# Refresh display with current state
	_refresh_task_display()

# -------------------------------------------------
## Called by TaskManager when any task state changes.
func _on_task_updated(_task_id: String, _completed: bool) -> void:
	_refresh_task_display()

# -------------------------------------------------
## Rebuilds the task row labels from the stall-specific config.
func _build_task_rows(stall_index: int) -> void:
	for child in task_container.get_children():
		child.queue_free()
	_task_rows.clear()

	var config: Dictionary = {}
	if stall_index < STALL_TASK_CONFIGS.size():
		config = STALL_TASK_CONFIGS[stall_index]

	for task_id in config:
		var lbl := Label.new()
		lbl.name = task_id
		lbl.text = config[task_id]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		lbl.add_theme_font_size_override("font_size", 13)
		task_container.add_child(lbl)
		_task_rows[task_id] = lbl

# -------------------------------------------------
## Refreshes all task row texts and colours from the active TaskManager.
func _refresh_task_display() -> void:
	if _task_manager == null:
		return
	var s = _task_manager.get_task_summary()
	var idx := s.get("stall_index", 0) as int

	# Stain / graffiti row
	if _task_rows.has("stains"):
		var cleaned: int = s.get("stains_cleaned", 0)
		var total: int   = s.get("total_stains", 0)
		var label_prefix: String
		if idx == 2:
			label_prefix = "🎨 Clean graffiti"
		elif idx == 1:
			label_prefix = "🧹 Clean water puddle"
		else:
			label_prefix = "🧹 Clean stains"
		if total > 0:
			_task_rows["stains"].text = "%s (%d/%d)" % [label_prefix, cleaned, total]
		_set_row_done("stains", total > 0 and cleaned >= total)

	# Trash row
	if _task_rows.has("trash_items"):
		var picked: int = s.get("trash_picked", 0)
		var total: int  = s.get("total_trash", 0)
		if total > 0:
			_task_rows["trash_items"].text = "🗑️ Pick up trash (%d/%d)" % [picked, total]
		_set_row_done("trash_items", total > 0 and picked >= total)

	# Flush row
	if _task_rows.has("toilet_flush"):
		var flushed: bool = s.get("toilet_flushed", false)
		if flushed:
			_task_rows["toilet_flush"].text = "🚽 Flush toilet ✓"
		_set_row_done("toilet_flush", flushed)

	# Soap row
	if _task_rows.has("soap"):
		var soap_done: bool = s.get("soap_done", false)
		if soap_done:
			_task_rows["soap"].text = "🧴 Refill soap dispenser ✓"
		_set_row_done("soap", soap_done)

	# Drain dirt row
	if _task_rows.has("drain_dirt"):
		var drained: int = s.get("dirt_blobs_drained", 0)
		var total_blobs: int = s.get("total_dirt_blobs", 0)
		if total_blobs > 0:
			_task_rows["drain_dirt"].text = "🚿 Push dirt to drain (%d/%d)" % [drained, total_blobs]
		_set_row_done("drain_dirt", total_blobs > 0 and drained >= total_blobs)

# -------------------------------------------------
func _set_row_done(task_id: String, done: bool) -> void:
	if not _task_rows.has(task_id):
		return
	var row: Label = _task_rows[task_id]
	if done:
		row.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))
		if not row.text.ends_with(" ✓"):
			row.text += " ✓"
	else:
		row.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

# -------------------------------------------------
## Legacy: mark a specific task complete by task_id (kept for compatibility).
func mark_task_complete(task_id: String) -> void:
	_set_row_done(task_id, true)
