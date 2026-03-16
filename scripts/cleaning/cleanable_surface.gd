## cleanable_surface.gd
## Dirt system component.  Attach to any MeshInstance3D (or its parent)
## that should be cleanable.
##
## The surface maintains a dirt_value (0.0 = spotless, 1.0 = filthy).
## It updates a shader parameter "dirt_amount" on the mesh material so the
## surface visually transitions from dirty (dark) to clean (bright).
##
## Signal "surface_clean" is emitted when dirt_value drops to or below the
## clean_threshold — the TaskManager listens to this.

class_name CleanableSurface
extends Node

# -------------------------------------------------
# Signals
signal surface_clean(surface: CleanableSurface)
signal dirt_changed(new_value: float)

# -------------------------------------------------
# Exported settings
@export var initial_dirt: float = 1.0          # Start fully dirty
@export var clean_threshold: float = 0.05      # <= 5 % counts as clean
@export var mesh_node: MeshInstance3D          # The mesh whose material we drive

# Optional foam system attached to this surface
@export var foam_system: Node

# -------------------------------------------------
# State
var dirt_value: float = 1.0
var _is_clean: bool = false

# -------------------------------------------------
func _ready() -> void:
	dirt_value = initial_dirt
	_update_shader()

# -------------------------------------------------
## Called by SprayTool every frame while spraying hits this surface.
## amount: how much dirt to remove this frame (spray_power * delta)
func apply_spray(amount: float) -> void:
	if _is_clean:
		return
	dirt_value = max(0.0, dirt_value - amount)
	_update_shader()
	emit_signal("dirt_changed", dirt_value)
	_check_clean()

# -------------------------------------------------
## Called externally to reset the surface (e.g., next level / reset).
func reset() -> void:
	dirt_value = initial_dirt
	_is_clean = false
	_update_shader()

# -------------------------------------------------
## Returns 0..100 cleanliness percentage (100 = spotless).
func get_cleanliness_percent() -> float:
	return (1.0 - dirt_value) * 100.0

# -------------------------------------------------
func _check_clean() -> void:
	if not _is_clean and dirt_value <= clean_threshold:
		_is_clean = true
		emit_signal("surface_clean", self)

# -------------------------------------------------
## Push the dirt_value into the mesh's shader/material as a uniform.
## Expects the material to have a shader parameter named "dirt_amount".
## Falls back to modulating the material's albedo color if no shader param exists.
func _update_shader() -> void:
	if mesh_node == null:
		return

	var mat := mesh_node.get_surface_override_material(0)
	if mat == null:
		mat = mesh_node.mesh.surface_get_material(0) if mesh_node.mesh else null

	if mat == null:
		return

	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("dirt_amount", dirt_value)
	elif mat is StandardMaterial3D:
		# Simple fallback: lerp albedo between clean (white) and dirty (brown/dark)
		var clean_color := Color(0.9, 0.9, 0.9)    # Light grey — clean tile
		var dirty_color := Color(0.35, 0.28, 0.2)  # Brown — grime
		(mat as StandardMaterial3D).albedo_color = clean_color.lerp(dirty_color, dirt_value)
