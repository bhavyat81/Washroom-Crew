## soap_dispenser.gd
## Interactable soap dispenser.
## Player presses E to refill.  Emits "task_completed" when refilled.

class_name SoapDispenser
extends "res://scripts/interactables/interactable_base.gd"

# -------------------------------------------------
signal task_completed(dispenser: SoapDispenser)

# -------------------------------------------------
@export var refilled: bool = false

## Mesh whose material changes to show empty/full state
@export var dispenser_mesh: MeshInstance3D

# -------------------------------------------------
func _ready() -> void:
	prompt_text = "Press E to refill soap dispenser"
	_update_visual()

# -------------------------------------------------
func get_interact_prompt() -> String:
	if refilled:
		return ""
	return prompt_text if is_enabled else ""

# -------------------------------------------------
func _on_interact() -> void:
	if refilled:
		return
	refilled = true
	_update_visual()
	emit_signal("task_completed", self)

# -------------------------------------------------
func is_available() -> bool:
	return is_enabled and not refilled

# -------------------------------------------------
func reset() -> void:
	refilled = false
	_update_visual()

# -------------------------------------------------
func _update_visual() -> void:
	if dispenser_mesh:
		var mat := dispenser_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			# Blue-ish when full/refilled, pale/empty otherwise
			(mat as StandardMaterial3D).albedo_color = Color(0.2, 0.5, 0.9) if refilled else Color(0.7, 0.7, 0.75)
