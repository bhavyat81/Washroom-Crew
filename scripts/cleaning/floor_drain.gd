## floor_drain.gd
## A metal floor-drain grate placed in the corner of each bathroom stall.
## The player pushes DirtBlob nodes toward it using the jet spray.
## When a DirtBlob enters the Area3D trigger zone, it gets sucked in,
## and the dirt_drained signal is emitted so TaskManager can track progress.

class_name FloorDrain
extends StaticBody3D

# -------------------------------------------------
# Signals
signal dirt_drained(blob: DirtBlob)

# -------------------------------------------------
## Radius of the drain Area3D trigger (slightly larger than the visual grate)
@export var trigger_radius: float = 0.18

# -------------------------------------------------
var _area: Area3D

# -------------------------------------------------
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	_build_visual()
	_build_collision()
	_build_trigger()

# -------------------------------------------------
func _build_visual() -> void:
	# --- Base recessed slab (dark metal, slightly below floor level) ---
	var base := CSGBox3D.new()
	base.size = Vector3(0.28, 0.025, 0.28)
	base.position = Vector3(0.0, -0.012, 0.0)
	base.use_collision = false
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.18, 0.18, 0.18)
	base_mat.metallic = 0.6
	base_mat.roughness = 0.35
	base.material = base_mat
	add_child(base)

	# --- Grate bars (3 thin strips across the opening) ---
	var grate_mat := StandardMaterial3D.new()
	grate_mat.albedo_color = Color(0.35, 0.35, 0.35)
	grate_mat.metallic = 0.7
	grate_mat.roughness = 0.25

	for i in range(3):
		var bar := CSGBox3D.new()
		bar.size = Vector3(0.24, 0.02, 0.04)
		bar.position = Vector3(0.0, 0.0, -0.08 + i * 0.08)
		bar.use_collision = false
		bar.material = grate_mat
		add_child(bar)

	# --- Subtle glow ring so the player can spot the drain ---
	var glow := CSGCylinder3D.new()
	glow.radius = 0.16
	glow.height = 0.005
	glow.position = Vector3(0.0, 0.003, 0.0)
	glow.use_collision = false
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.55)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.1, 0.4, 0.9)
	glow_mat.emission_energy_multiplier = 0.6
	glow.material = glow_mat
	add_child(glow)

# -------------------------------------------------
func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.28, 0.025, 0.28)
	col.shape = box
	col.position = Vector3(0.0, -0.012, 0.0)
	add_child(col)

# -------------------------------------------------
func _build_trigger() -> void:
	_area = Area3D.new()
	_area.name = "DrainArea"
	_area.collision_layer = 0
	_area.collision_mask = 1   # detect RigidBody3D blobs on layer 1
	_area.body_entered.connect(_on_body_entered)

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = trigger_radius
	cyl.height = 0.3
	shape.shape = cyl
	shape.position = Vector3(0.0, 0.05, 0.0)
	_area.add_child(shape)
	add_child(_area)

# -------------------------------------------------
func _on_body_entered(body: Node3D) -> void:
	if body is DirtBlob:
		var blob := body as DirtBlob
		blob.drain()
		emit_signal("dirt_drained", blob)
