## dirt_blob.gd
## A physics-driven dirt chunk that sits on the bathroom floor.
## The player uses the jet spray to push it toward the floor drain.
## When it enters the drain's Area3D trigger it gets cleaned up automatically.

class_name DirtBlob
extends RigidBody3D

# -------------------------------------------------
# Signals
signal blob_drained(blob: DirtBlob)

# -------------------------------------------------
## How hard the spray pushes this blob (multiplied by spray power * delta)
@export var push_multiplier: float = 8.0

# -------------------------------------------------
var _is_draining: bool = false

# -------------------------------------------------
func _ready() -> void:
	# Sit on floor (layer 1), detected by spray ray and drain area
	collision_layer = 1
	collision_mask = 1

	# Prevent the blob from tipping over — lock rotation on X and Z
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	# Damping so blobs don't slide forever
	linear_damp = 4.0
	angular_damp = 4.0

	# Build brownish dirt visual if no mesh child exists yet
	if get_child_count() == 0 or not _has_mesh_child():
		_build_visual()

	# Build collision shape if none present
	if not _has_collision_child():
		_build_collision()

# -------------------------------------------------
## Called by SprayTool when the spray ray hits this blob.
## direction should be the camera-forward ray projected onto XZ (horizontal only).
func apply_spray(direction: Vector3, power: float) -> void:
	if _is_draining:
		return
	# Flatten to XZ plane so the spray never launches the blob into the air
	var push := Vector3(direction.x, 0.0, direction.z).normalized()
	apply_central_impulse(push * power * push_multiplier)

# -------------------------------------------------
## Called when this blob enters the FloorDrain's Area3D.
## Animates being sucked into the drain then frees itself.
func drain() -> void:
	if _is_draining:
		return
	_is_draining = true
	# Freeze physics so it doesn't jitter during the animation
	freeze = true
	emit_signal("blob_drained", self)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.35)
	tween.tween_property(self, "rotation", Vector3(0.0, TAU * 2.0, 0.0), 0.35)
	tween.chain().tween_callback(queue_free)

# -------------------------------------------------
func _has_mesh_child() -> bool:
	for child in get_children():
		if child is CSGShape3D or child is MeshInstance3D:
			return true
	return false

func _has_collision_child() -> bool:
	for child in get_children():
		if child is CollisionShape3D:
			return true
	return false

# -------------------------------------------------
func _build_visual() -> void:
	var sphere := CSGSphere3D.new()
	sphere.radius = 0.07
	sphere.use_collision = false  # collision handled by CollisionShape3D sibling
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.24, 0.12)
	mat.roughness = 0.9
	mat.metallic = 0.0
	sphere.material = mat
	add_child(sphere)

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.07
	col.shape = shape
	add_child(col)
