## stain.gd
## A visible dirt stain on a floor, wall, or toilet surface.
## Responds to spray from SprayTool and fades out when fully cleaned.
## Notifies the parent stall's TaskManager via the stain_cleaned signal.

class_name Stain
extends CSGBox3D

# -------------------------------------------------
# Signals
signal stain_cleaned(stain)

# -------------------------------------------------
## Total spray power required to remove this stain
@export var spray_required: float = 2.0

# -------------------------------------------------
var _accumulated: float = 0.0
var _is_cleaned: bool = false
var _mat: StandardMaterial3D

# -------------------------------------------------
func _ready() -> void:
	# Enable collision so the spray ray and interact ray can detect this CSGBox3D
	use_collision = true
	# Duplicate the shared material so each stain instance can fade independently
	if material and material is StandardMaterial3D:
		_mat = (material as StandardMaterial3D).duplicate() as StandardMaterial3D
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material = _mat

# -------------------------------------------------
## Called by SprayTool when this node is hit by the spray ray.
func apply_spray(amount: float) -> void:
	if _is_cleaned:
		return
	_accumulated += amount
	# Partially fade the stain as spray accumulates (visual feedback)
	if _mat:
		var ratio := clampf(_accumulated / spray_required, 0.0, 1.0)
		_mat.albedo_color.a = 1.0 - ratio * 0.5
	if _accumulated >= spray_required:
		_do_clean()

# -------------------------------------------------
func _do_clean() -> void:
	if _is_cleaned:
		return
	_is_cleaned = true
	emit_signal("stain_cleaned", self)
	# Fade out then free
	var tween := create_tween()
	if _mat:
		tween.tween_property(_mat, "albedo_color:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
