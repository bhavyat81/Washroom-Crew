## foam_system.gd
## Foam / disinfectant timed-application step.
## After the jet spray removes visible dirt, the player holds the foam button
## to apply disinfectant.  A progress bar fills over foam_duration seconds.
## When full the surface is considered "disinfected" and
## the "foam_complete" signal is emitted (TaskManager listens).
##
## Attach this node as a child of the same object that has CleanableSurface,
## and assign the progress_bar export to the HUD foam-progress ProgressBar.

class_name FoamSystem
extends Node

# -------------------------------------------------
# Signals
signal foam_complete            # Foam application finished
signal foam_progress_changed(progress)   # 0.0 .. 1.0

# -------------------------------------------------
@export var foam_duration: float = 3.0          # Seconds to hold for full disinfection
@export var requires_pre_clean: bool = true     # Must spray first before foaming works
@export var progress_bar: ProgressBar           # Optional HUD bar reference

# -------------------------------------------------
var foam_progress: float = 0.0     # 0.0 .. 1.0
var is_complete: bool = false
var _cleanable = null   # Sibling CleanableSurface (resolved in _ready)

# -------------------------------------------------
func _ready() -> void:
	# Try to find a sibling CleanableSurface
	if get_parent():
		for child in get_parent().get_children():
			if child.has_method("get_cleanliness_percent"):
				_cleanable = child
				break

	if progress_bar:
		progress_bar.value = 0.0
		progress_bar.visible = false

# -------------------------------------------------
## Called by SprayTool._do_foam() every frame while foam button is held.
func apply_foam(delta: float) -> void:
	if is_complete:
		return

	# Optionally require the surface to be mostly clean first
	if requires_pre_clean and _cleanable and _cleanable.dirt_value > _cleanable.clean_threshold:
		return   # Surface still too dirty — spray first

	foam_progress = min(1.0, foam_progress + delta / foam_duration)
	emit_signal("foam_progress_changed", foam_progress)

	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = foam_progress * 100.0

	if foam_progress >= 1.0:
		_on_foam_complete()

# -------------------------------------------------
func reset() -> void:
	foam_progress = 0.0
	is_complete = false
	if progress_bar:
		progress_bar.value = 0.0
		progress_bar.visible = false

# -------------------------------------------------
func _on_foam_complete() -> void:
	is_complete = true
	if progress_bar:
		progress_bar.visible = false
	emit_signal("foam_complete")
