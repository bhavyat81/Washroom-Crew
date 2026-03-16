## player_controller.gd
## First-person CharacterBody3D controller.
## Handles WASD movement, mouse-look, gravity, jumping, and mobile touch input.
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

# --- Touch camera settings ---
@export var touch_sensitivity: float = 0.005

# Gravity pulled from project physics settings
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Internal state
var _head: Node3D          # Camera pitch pivot
var _camera: Camera3D      # The actual camera
var _is_sprinting: bool = false

# Touch camera state
var _touch_look_index: int = -1   # Finger index controlling camera
var _mouse_captured: bool = false  # Cached mouse capture state

# Reference to virtual joystick (set by game_level.gd after instantiation)
var _joystick = null

# Minimum joystick magnitude to override keyboard input
const JOYSTICK_DEADZONE: float = 0.01

# -------------------------------------------------
func _ready() -> void:
	_head   = $Head
	_camera = $Head/Camera3D

	# On mobile don't capture the mouse; on desktop capture for mouse-look
	if OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

# -------------------------------------------------
## Called by game_level.gd to wire up the joystick node.
func set_joystick(joystick_node) -> void:
	_joystick = joystick_node

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# ---- Desktop mouse-look ----
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(
			_head.rotation.x,
			deg_to_rad(-max_look_angle_deg),
			deg_to_rad(max_look_angle_deg)
		)

	# Release / recapture mouse on desktop with Escape
	if event.is_action_pressed("ui_cancel") and not OS.has_feature("mobile"):
		if _mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	# ---- Touch camera (mobile only) ----
	# On desktop (mouse captured): InputEventMouseMotion handles the camera.
	# On mobile: right half of the screen controls the camera via touch.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var half_w := get_viewport().get_visible_rect().size.x * 0.5
		if touch.pressed:
			if _touch_look_index == -1 and not _mouse_captured and touch.position.x >= half_w:
				_touch_look_index = touch.index
		else:
			if touch.index == _touch_look_index:
				_touch_look_index = -1

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _mouse_captured and drag.index == _touch_look_index:
			rotate_y(-drag.relative.x * touch_sensitivity)
			_head.rotate_x(-drag.relative.y * touch_sensitivity)
			_head.rotation.x = clamp(
				_head.rotation.x,
				deg_to_rad(-max_look_angle_deg),
				deg_to_rad(max_look_angle_deg)
			)

# -------------------------------------------------
func _physics_process(delta: float) -> void:
	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Jump (keyboard only)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# ---- Build movement direction ----
	# Start with keyboard WASD
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Blend in virtual joystick if present and actively being touched
	if _joystick != null and _joystick.is_active():
		var joy_dir: Vector2 = _joystick.get_direction()
		# Joystick takes priority over keyboard when a finger is active
		if joy_dir.length_squared() > JOYSTICK_DEADZONE:
			input_dir = joy_dir

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
