## tissue_holder.gd
## Interactable tissue-roll holder.
## The player presses E when near this to "replace" the tissue roll.
## Emits "task_completed" when replaced (TaskManager listens).

class_name TissueHolder
extends InteractableBase

# -------------------------------------------------
signal task_completed(holder: TissueHolder)

# -------------------------------------------------
@export var replaced: bool = false

# Visual node to hide/show representing the empty/full roll
@export var tissue_mesh: MeshInstance3D

# -------------------------------------------------
func _ready() -> void:
	prompt_text = "Press E to replace tissue roll"
	_update_visual()

# -------------------------------------------------
func get_interact_prompt() -> String:
	if replaced:
		return ""   # Already done — hide prompt
	return prompt_text if is_enabled else ""

# -------------------------------------------------
func _on_interact() -> void:
	if replaced:
		return   # Already replaced — nothing to do
	replaced = true
	_update_visual()
	emit_signal("task_completed", self)

# -------------------------------------------------
func is_available() -> bool:
	return is_enabled and not replaced

# -------------------------------------------------
func reset() -> void:
	replaced = false
	_update_visual()

# -------------------------------------------------
func _update_visual() -> void:
	if tissue_mesh:
		# Show "empty" visual when replaced, keep default when dirty/empty
		# Adjust tint: grey when replaced (fresh roll), brownish-grey when empty
		var mat := tissue_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color = Color(0.95, 0.95, 0.95) if replaced else Color(0.6, 0.55, 0.5)
