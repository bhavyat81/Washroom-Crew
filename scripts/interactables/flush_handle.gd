## flush_handle.gd
## A small flush button on top of each toilet tank.
## Player looks at it and presses E to flush.
## Plays a quick colour animation and emits the flushed signal for TaskManager.

class_name FlushHandle
extends CSGBox3D

# -------------------------------------------------
# Signals
signal flushed(handle)

# -------------------------------------------------
var _has_flushed: bool = false
var _mat: StandardMaterial3D

# -------------------------------------------------
func _ready() -> void:
	# Enable collision so InteractRay can detect this CSGBox3D
	use_collision = true
	# Duplicate material so the colour animation doesn't affect other nodes
	if material and material is StandardMaterial3D:
		_mat = (material as StandardMaterial3D).duplicate() as StandardMaterial3D
		material = _mat

# -------------------------------------------------
## Returns the HUD prompt when the player aims at this node.
func get_interact_prompt() -> String:
	if _has_flushed:
		return ""
	return "Press E to flush"

# -------------------------------------------------
## Called by InteractRay when the player presses the interact key.
func interact() -> void:
	if _has_flushed:
		return
	_has_flushed = true
	emit_signal("flushed", self)
	_animate_flush()

# -------------------------------------------------
func _animate_flush() -> void:
	if _mat == null:
		return
	var original_color := _mat.albedo_color
	var tween := create_tween()
	tween.tween_property(_mat, "albedo_color", Color(0.2, 0.55, 1.0, 1.0), 0.2)
	tween.tween_property(_mat, "albedo_color", original_color, 0.35)
