## spray_tool.gd
## Jet-spray cleaning tool held by the player.
## HOLD left-click (action "spray") to spray continuously — depletes an ammo meter.
## Right-click (action "foam") applies foam/disinfectant (timed hold).
## Attach to a Node3D under the camera so it moves with the player's view.

class_name SprayTool
extends Node3D

# --- Spray settings ---
@export var spray_distance: float = 3.0
@export var spray_power: float = 0.4       # Dirt reduced per second while spraying
@export var spray_collision_mask: int = 0b11111111

# --- Foam settings (handed off to FoamSystem on the surface) ---
@export var foam_distance: float = 2.5

# --- Ammo / pressure meter ---
@export var max_ammo: float = 100.0
@export var ammo_drain_rate: float = 22.0   # Units per second while spraying
@export var ammo_regen_rate: float = 16.0   # Units per second while not spraying

# --- Visual feedback ---
## Spray "particles" or mesh — swap with a GPUParticles3D for visual polish
@export var spray_particles: GPUParticles3D

# Emitted every frame so the HUD can display the ammo bar
signal ammo_changed(current, maximum)

# -------------------------------------------------
# Internal
var _camera: Camera3D
var _spray_ray: RayCast3D
var current_ammo: float
var _spraying: bool = false
var _foaming: bool = false

# -------------------------------------------------
func _ready() -> void:
	current_ammo = max_ammo

	# Walk up the scene tree to find the Camera3D
	var node := get_parent()
	while node != null:
		if node is Camera3D:
			_camera = node as Camera3D
			break
		if node.has_method("get_camera"):
			_camera = node.get_camera()
			break
		node = node.get_parent()

	# Create a RayCast3D child for spray hit detection
	_spray_ray = RayCast3D.new()
	_spray_ray.name = "SprayRay"
	_spray_ray.enabled = true
	_spray_ray.collision_mask = spray_collision_mask
	_spray_ray.target_position = Vector3(0.0, 0.0, -spray_distance)
	add_child(_spray_ray)

	# Create water spray GPUParticles3D if not assigned in the editor
	if spray_particles == null:
		spray_particles = GPUParticles3D.new()
		spray_particles.name = "SprayParticles"
		spray_particles.amount = 32
		spray_particles.lifetime = 0.3
		spray_particles.emitting = false
		spray_particles.one_shot = false
		spray_particles.explosiveness = 0.0
		spray_particles.local_coords = false

		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0.0, 0.0, -1.0)
		mat.spread = 15.0
		mat.initial_velocity_min = 4.0
		mat.initial_velocity_max = 6.0
		mat.gravity = Vector3(0.0, -2.0, 0.0)
		mat.scale_min = 0.02
		mat.scale_max = 0.04
		mat.color = Color(0.3, 0.7, 1.0, 0.8)

		# Fade out color over the particle lifetime
		var gradient := Gradient.new()
		gradient.set_point_color(0, Color(0.3, 0.7, 1.0, 0.8))
		gradient.add_point(1.0, Color(0.3, 0.7, 1.0, 0.0))
		var ramp := GradientTexture1D.new()
		ramp.gradient = gradient
		mat.color_ramp = ramp

		spray_particles.process_material = mat

		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.03, 0.03)
		spray_particles.draw_pass_1 = mesh

		add_child(spray_particles)

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spray"):
		_spraying = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("spray"):
		_spraying = false
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("foam"):
		_foaming = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("foam"):
		_foaming = false
		get_viewport().set_input_as_handled()

# -------------------------------------------------
func _physics_process(_delta: float) -> void:
	_spray_ray.force_raycast_update()

# -------------------------------------------------
func _process(delta: float) -> void:
	# Combine event-driven flags (desktop) with Input polling (mobile touch buttons
	# use Input.action_press() which does not dispatch input events).
	var is_spraying: bool = _spraying or Input.is_action_pressed("spray")
	var is_foaming: bool = _foaming or Input.is_action_pressed("foam")

	# --- Spraying (hold to spray, drains ammo) ---
	if is_spraying and current_ammo > 0.0:
		current_ammo = max(0.0, current_ammo - ammo_drain_rate * delta)
		_do_spray(delta)
		_set_particles_active(true)
	else:
		# Regenerate ammo when not spraying
		current_ammo = min(max_ammo, current_ammo + ammo_regen_rate * delta)
		_set_particles_active(false)

	emit_signal("ammo_changed", current_ammo, max_ammo)

	# --- Foam (delegated to FoamSystem on the surface) ---
	if is_foaming:
		_do_foam(delta)

# -------------------------------------------------
func _do_spray(delta: float) -> void:
	_spray_ray.force_raycast_update()
	var hit = _spray_ray.get_collider()
	if hit == null:
		return

	# Check for CleanableSurface component first
	var surface = _find_cleanable(hit)
	if surface:
		surface.apply_spray(spray_power * delta)
		return

	# Also check for Stain nodes (floor/wall stains)
	var stain = _find_stain(hit)
	if stain:
		stain.apply_spray(spray_power * delta)
		return

	# Check for DirtBlob — push it horizontally toward the drain
	var blob = _find_dirt_blob(hit)
	if blob:
		# Project camera forward onto XZ plane for horizontal-only push
		var spray_dir := Vector3.ZERO
		if _camera:
			spray_dir = -_camera.global_transform.basis.z
		else:
			spray_dir = -global_transform.basis.z
		blob.apply_spray(spray_dir, spray_power * delta)

# -------------------------------------------------
func _do_foam(delta: float) -> void:
	_spray_ray.force_raycast_update()
	var hit = _spray_ray.get_collider()
	if hit == null:
		return

	var surface = _find_cleanable(hit)
	if surface and surface.foam_system:
		surface.foam_system.apply_foam(delta)

# -------------------------------------------------
## Searches the hit node and its ancestors for a CleanableSurface component.
func _find_cleanable(node: Node) -> Node:
	var check = node
	while check != null:
		if check.has_method("get_cleanliness_percent"):
			return check
		# Also support CleanableSurface as a child component
		for child in check.get_children():
			if child.has_method("get_cleanliness_percent"):
				return child
		check = check.get_parent()
	return null

# -------------------------------------------------
## Searches the hit node and its ancestors for a Stain node.
func _find_stain(node: Node) -> Node:
	var check = node
	while check != null:
		if check.has_signal("stain_cleaned"):
			return check
		check = check.get_parent()
	return null

# -------------------------------------------------
## Searches the hit node and its ancestors for a DirtBlob.
func _find_dirt_blob(node: Node) -> Node:
	var check = node
	while check != null:
		if check.has_method("drain") and check.has_signal("blob_drained"):
			return check
		check = check.get_parent()
	return null

# -------------------------------------------------
func _set_particles_active(active: bool) -> void:
	if spray_particles:
		spray_particles.emitting = active
