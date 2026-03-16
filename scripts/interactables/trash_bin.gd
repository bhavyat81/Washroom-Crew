## trash_bin.gd
## Interactable trash bin / waste bin.
## Player presses E to change the bag.  Emits "task_completed" when done.

class_name TrashBin
extends InteractableBase

# -------------------------------------------------
signal task_completed(bin: TrashBin)

# -------------------------------------------------
@export var bag_changed: bool = false

## Mesh whose material changes to show full/empty state
@export var bin_mesh: MeshInstance3D

# -------------------------------------------------
func _ready() -> void:
	prompt_text = "Press E to change trash bag"
	_update_visual()

# -------------------------------------------------
func get_interact_prompt() -> String:
	if bag_changed:
		return ""
	return prompt_text if is_enabled else ""

# -------------------------------------------------
func _on_interact() -> void:
	if bag_changed:
		return
	bag_changed = true
	_update_visual()
	emit_signal("task_completed", self)

# -------------------------------------------------
func is_available() -> bool:
	return is_enabled and not bag_changed

# -------------------------------------------------
func reset() -> void:
	bag_changed = false
	_update_visual()

# -------------------------------------------------
func _update_visual() -> void:
	if bin_mesh:
		var mat := bin_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			# Dark (full) when unchanged, lighter (empty/fresh) when bag swapped
			(mat as StandardMaterial3D).albedo_color = Color(0.85, 0.85, 0.85) if bag_changed else Color(0.25, 0.25, 0.25)
