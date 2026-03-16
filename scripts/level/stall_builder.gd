## stall_builder.gd
## Procedurally builds a polished 3D bathroom stall structure from CSG primitives.
## Attach one StallBuilder node inside each stall root node.
## It creates partition walls, a door, a toilet, a floor drain, a paper holder,
## a soap dispenser mount, a trash bin, and (for stall 0) the shared sink counter.
##
## All geometry is constructed entirely in _ready() so the .tscn file
## doesn't need manual editing.

class_name StallBuilder
extends Node3D

# -------------------------------------------------
## Width of the stall in metres
@export var stall_width: float = 1.8
## Depth (front to back) of the stall
@export var stall_depth: float = 2.2
## Height of the partition panels (gap at top and bottom)
@export var partition_height: float = 1.6
## Offset from the floor to the bottom of the partition panels
@export var partition_floor_gap: float = 0.15
## Whether to also build the shared sink counter (only for the outermost stall)
@export var build_sink_area: bool = false
## Number of DirtBlob instances to scatter on the stall floor
@export var dirt_blob_count: int = 4

# -------------------------------------------------
# Pre-built materials (created once in _ready)
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _porcelain_mat: StandardMaterial3D
var _metal_mat: StandardMaterial3D
var _door_mat: StandardMaterial3D

# -------------------------------------------------
func _ready() -> void:
	_create_materials()
	_build_partitions()
	_build_door()
	_build_toilet()
	_build_floor_drain()
	_build_paper_holder()
	_build_soap_mount()
	_build_trash_bin()
	_scatter_dirt_blobs()
	if build_sink_area:
		_build_sink_area()

# -------------------------------------------------
func _create_materials() -> void:
	# Beige/tan partition walls (school bathroom style)
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.82, 0.75, 0.63)
	_wall_mat.roughness = 0.85

	# Light grey tile floor
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.78, 0.78, 0.78)
	_floor_mat.roughness = 0.6
	_floor_mat.metallic = 0.02

	# White porcelain (toilet)
	_porcelain_mat = StandardMaterial3D.new()
	_porcelain_mat.albedo_color = Color(0.96, 0.96, 0.94)
	_porcelain_mat.roughness = 0.15
	_porcelain_mat.metallic = 0.05

	# Grey metal (fixtures)
	_metal_mat = StandardMaterial3D.new()
	_metal_mat.albedo_color = Color(0.55, 0.55, 0.58)
	_metal_mat.roughness = 0.2
	_metal_mat.metallic = 0.5

	# Door — slightly darker than wall
	_door_mat = StandardMaterial3D.new()
	_door_mat.albedo_color = Color(0.72, 0.65, 0.54)
	_door_mat.roughness = 0.8

# -------------------------------------------------
func _build_partitions() -> void:
	var panel_y := partition_floor_gap + partition_height * 0.5
	var thickness := 0.05

	# Left partition
	var left := _make_box(
		Vector3(thickness, partition_height, stall_depth),
		Vector3(-stall_width * 0.5, panel_y, 0.0),
		_wall_mat
	)
	left.name = "PartitionLeft"
	add_child(left)

	# Right partition
	var right := _make_box(
		Vector3(thickness, partition_height, stall_depth),
		Vector3(stall_width * 0.5, panel_y, 0.0),
		_wall_mat
	)
	right.name = "PartitionRight"
	add_child(right)

# -------------------------------------------------
func _build_door() -> void:
	var door_width := stall_width - 0.15
	var door_height := partition_height
	var panel_y := partition_floor_gap + door_height * 0.5
	var door := _make_box(
		Vector3(door_width, door_height, 0.04),
		Vector3(0.0, panel_y, stall_depth * 0.5),
		_door_mat
	)
	door.name = "StallDoor"
	add_child(door)

# -------------------------------------------------
func _build_toilet() -> void:
	# Bowl base — short wide cylinder
	var bowl := CSGCylinder3D.new()
	bowl.name = "ToiletBowl"
	bowl.radius = 0.22
	bowl.height = 0.28
	bowl.position = Vector3(0.0, 0.14, -stall_depth * 0.5 + 0.55)
	bowl.material = _porcelain_mat
	bowl.use_collision = true
	add_child(bowl)

	# Tank — taller narrower box behind the bowl
	var tank := _make_box(
		Vector3(0.34, 0.38, 0.16),
		Vector3(0.0, 0.37, -stall_depth * 0.5 + 0.24),
		_porcelain_mat
	)
	tank.name = "ToiletTank"
	add_child(tank)

	# Seat — flat ring on top of bowl (represented as thin flat box)
	var seat := _make_box(
		Vector3(0.42, 0.03, 0.46),
		Vector3(0.0, 0.29, -stall_depth * 0.5 + 0.55),
		_porcelain_mat
	)
	seat.name = "ToiletSeat"
	add_child(seat)

	# Flush handle (FlushHandle script) on the side of the tank
	var handle := FlushHandle.new()
	handle.name = "FlushHandle"
	handle.size = Vector3(0.10, 0.05, 0.04)
	handle.position = Vector3(0.22, 0.42, -stall_depth * 0.5 + 0.24)
	handle.use_collision = true
	var handle_mat := _metal_mat.duplicate() as StandardMaterial3D
	handle_mat.albedo_color = Color(0.6, 0.65, 0.72)
	handle.material = handle_mat
	add_child(handle)

# -------------------------------------------------
func _build_floor_drain() -> void:
	# Place in the back-right corner of the stall
	var drain := FloorDrain.new()
	drain.name = "FloorDrain"
	drain.position = Vector3(stall_width * 0.5 - 0.22, 0.0, -stall_depth * 0.5 + 0.22)
	add_child(drain)

# -------------------------------------------------
func _build_paper_holder() -> void:
	# Small bracket on the right wall
	var bracket := _make_box(
		Vector3(0.04, 0.14, 0.08),
		Vector3(stall_width * 0.5 - 0.04, 0.85, -stall_depth * 0.5 + 0.90),
		_metal_mat
	)
	bracket.name = "PaperBracket"
	add_child(bracket)

	# Roll — CSGCylinder on its side
	var roll := CSGCylinder3D.new()
	roll.name = "PaperRoll"
	roll.radius = 0.055
	roll.height = 0.12
	roll.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	roll.position = Vector3(stall_width * 0.5 - 0.10, 0.85, -stall_depth * 0.5 + 0.90)
	var paper_mat := StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.95, 0.95, 0.93)
	paper_mat.roughness = 0.9
	roll.material = paper_mat
	roll.use_collision = false
	add_child(roll)

# -------------------------------------------------
func _build_soap_mount() -> void:
	# SoapDispenser near the door on the right wall
	var dispenser := SoapDispenser.new()
	dispenser.name = "SoapDispenser"
	dispenser.position = Vector3(stall_width * 0.5 - 0.04, 1.1, stall_depth * 0.5 - 0.35)

	# Give it a simple box collision body so the interact ray can hit it
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.12, 0.18, 0.08)
	col.shape = box
	body.add_child(col)
	dispenser.add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.18, 0.08)
	mesh_inst.mesh = mesh
	var soap_mat := StandardMaterial3D.new()
	soap_mat.albedo_color = Color(0.3, 0.55, 0.85)
	soap_mat.roughness = 0.3
	mesh_inst.material_override = soap_mat
	dispenser.add_child(mesh_inst)
	add_child(dispenser)

# -------------------------------------------------
func _build_trash_bin() -> void:
	# TrashBin near the door on the left side
	var bin := TrashBin.new()
	bin.name = "TrashBin"
	bin.position = Vector3(-stall_width * 0.5 + 0.20, 0.0, stall_depth * 0.5 - 0.25)

	# Collision body
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 0.14
	cyl_shape.height = 0.38
	col.shape = cyl_shape
	col.position = Vector3(0.0, 0.19, 0.0)
	body.add_child(col)
	bin.add_child(body)

	# Mesh
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.14
	mesh.bottom_radius = 0.14
	mesh.height = 0.38
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(0.0, 0.19, 0.0)
	var bin_mat := StandardMaterial3D.new()
	bin_mat.albedo_color = Color(0.28, 0.28, 0.28)
	bin_mat.roughness = 0.6
	mesh_inst.material_override = bin_mat
	bin.add_child(mesh_inst)
	add_child(bin)

# -------------------------------------------------
## Scatter DirtBlob physics objects across the stall floor.
func _scatter_dirt_blobs() -> void:
	if dirt_blob_count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = get_path().hash()
	var half_w := stall_width * 0.5 - 0.25
	var z_min := -stall_depth * 0.5 + 0.3
	var z_max := stall_depth * 0.5 - 0.4
	for i in range(dirt_blob_count):
		var blob := DirtBlob.new()
		blob.name = "DirtBlob%d" % i
		blob.position = Vector3(
			rng.randf_range(-half_w, half_w),
			0.07,
			rng.randf_range(z_min, z_max)
		)
		add_child(blob)

# -------------------------------------------------
## Builds a shared sink counter outside the stalls (attach to the room root, not a stall).
func _build_sink_area() -> void:
	# Counter top
	var counter := _make_box(
		Vector3(2.4, 0.05, 0.55),
		Vector3(0.0, 0.82, -stall_depth * 0.5 - 0.30),
		_porcelain_mat
	)
	counter.name = "SinkCounter"
	add_child(counter)

	# Two basin cutouts — represented as dark inset cylinders
	for i in [-0.55, 0.55]:
		var basin := CSGCylinder3D.new()
		basin.name = "Basin_%s" % str(i)
		basin.radius = 0.18
		basin.height = 0.12
		basin.position = Vector3(i, 0.77, -stall_depth * 0.5 - 0.30)
		var basin_mat := StandardMaterial3D.new()
		basin_mat.albedo_color = Color(0.12, 0.12, 0.15)
		basin_mat.roughness = 0.5
		basin.material = basin_mat
		basin.use_collision = false
		add_child(basin)

# -------------------------------------------------
## Helper: create a StaticBody3D with a CSGBox3D child.
func _make_box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos

	var box := CSGBox3D.new()
	box.size = size
	box.use_collision = true
	box.material = mat
	body.add_child(box)

	return body
