## checklist.gd
## Per-stall task checklist UI.
## Displays a list of tasks with checkboxes and animates a tick when
## each task is completed.

extends Control

# -------------------------------------------------
## Task display names keyed by task_id (matches TaskManager.tasks keys)
const TASK_LABELS: Dictionary = {
	"clean_surface": "🧹 Clean surfaces (< 5% dirt)",
	"foam_applied":  "🫧 Apply disinfectant foam",
	"tissue":        "🧻 Replace tissue roll",
	"soap":          "🧴 Refill soap dispenser",
	"trash":         "🗑️  Change trash bag",
}

# -------------------------------------------------
@onready var stall_label: Label         = $Panel/VBoxContainer/StallLabel
@onready var task_container: VBoxContainer = $Panel/VBoxContainer/TaskContainer

# Runtime-created task row labels keyed by task_id
var _task_rows: Dictionary = {}

# -------------------------------------------------
func _ready() -> void:
	_build_task_rows()

# -------------------------------------------------
## Called by GameLevel when a new stall is activated.
func set_active_stall(stall_index: int) -> void:
	stall_label.text = "Stall %d / 3" % (stall_index + 1)
	_reset_rows()

# -------------------------------------------------
## Called by TaskManager.task_updated signal.
func mark_task_complete(task_id: String) -> void:
	if not _task_rows.has(task_id):
		return
	var row: Label = _task_rows[task_id]
	row.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))  # Green
	# Append a checkmark if not already there
	if not row.text.ends_with(" ✓"):
		row.text += " ✓"

# -------------------------------------------------
func _build_task_rows() -> void:
	# Clear any existing children first
	for child in task_container.get_children():
		child.queue_free()
	_task_rows.clear()

	for task_id in TASK_LABELS:
		var lbl := Label.new()
		lbl.name = task_id
		lbl.text = TASK_LABELS[task_id]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		task_container.add_child(lbl)
		_task_rows[task_id] = lbl

func _reset_rows() -> void:
	for task_id in _task_rows:
		var row: Label = _task_rows[task_id]
		row.text = TASK_LABELS[task_id]
		row.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
