## virtual_joystick.gd
## On-screen virtual joystick for mobile touch input.
## Place this Control node in the bottom-left of the screen.
## Call get_direction() from the player controller each physics frame.

extends Control

# --- Settings ---
@export var joystick_radius: float = 80.0   # Outer ring radius in pixels
@export var knob_radius: float = 36.0       # Inner knob radius in pixels

# --- Nodes ---
@onready var _outer: ColorRect = $Outer
@onready var _knob: ColorRect  = $Outer/Knob

# --- State ---
var _touch_index: int = -1          # Which finger is controlling the joystick
var _base_position: Vector2         # Centre of the outer ring in local coords
var _direction: Vector2 = Vector2.ZERO

# -------------------------------------------------
func _ready() -> void:
	_base_position = _outer.size * 0.5

# -------------------------------------------------
## Returns true when a finger is actively touching the joystick.
func is_active() -> bool:
	return _touch_index != -1

# -------------------------------------------------
## Returns a normalised (or proportional) Vector2 direction.
## x = strafe (right positive), y = forward/back (down positive = backward).
func get_direction() -> Vector2:
	return _direction

# -------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Only claim a finger on the left half of the viewport
			if _touch_index == -1 and touch.position.x < get_viewport_rect().size.x * 0.5:
				_touch_index = touch.index
				_update_knob(touch.position)
		else:
			if touch.index == _touch_index:
				_release()

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_knob(drag.position)

# -------------------------------------------------
func _update_knob(global_pos: Vector2) -> void:
	# Convert global touch position to local space of the Outer ring
	var local_pos := _outer.get_global_rect().get_center()
	var delta := global_pos - local_pos
	var clamped := delta.limit_length(joystick_radius - knob_radius)

	# Position knob relative to the outer ring centre
	_knob.position = (_outer.size * 0.5) + clamped - (_knob.size * 0.5)

	# Normalise to [-1, 1] range (proportional within radius)
	_direction = clamped / (joystick_radius - knob_radius)

# -------------------------------------------------
func _release() -> void:
	_touch_index = -1
	_direction   = Vector2.ZERO
	# Snap knob back to centre
	_knob.position = (_outer.size * 0.5) - (_knob.size * 0.5)
