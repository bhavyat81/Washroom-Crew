## player_controller.gd
## First-person CharacterBody3D controller.
## Handles WASD movement, mouse-look, gravity, and jumping.
## Attach to a CharacterBody3D node that has:
##   - CollisionShape3D child
##   - Node3D "Head" child (for camera pivot)
##     - Camera3D child (inside Head)

class_name PlayerController
extends CharacterBody3D

# --- Movement settings ---
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5

# --- Mouse-look settings ---
@export var mouse_sensitivity: float = 0.003
@export var max_look_angle_deg: float = 80.0

# Gravity pulled from project physics settings
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Internal state
var _head: Node3D          # Camera pitch pivot
var _camera: Camera3D      # The actual camera
var _is_sprinting: bool = false

# -------------------------------------------------
func _ready() -> void:
	_head   = $Head
	_camera = $Head/Camera3D

	# Capture mouse so we can look around
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Mouse-look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Horizontal look — rotate the whole body
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical look — rotate only the head node (camera pivot)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(
			_head.rotation.x,
			deg_to_rad(-max_look_angle_deg),
			deg_to_rad(max_look_angle_deg)
		)

	# Release mouse cursor with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# -------------------------------------------------
func _physics_process(delta: float) -> void:
	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Build movement direction from input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	_is_sprinting = Input.is_action_pressed("sprint")
	var current_speed: float = sprint_speed if _is_sprinting else move_speed

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Smooth deceleration
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()

# -------------------------------------------------
## Returns the Camera3D node (used by other systems, e.g. InteractRay, SprayTool)
func get_camera() -> Camera3D:
	return _camera
