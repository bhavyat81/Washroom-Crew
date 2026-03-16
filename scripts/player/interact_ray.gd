## interact_ray.gd
## Raycast-based interaction system.
## Attach to a Node3D (or directly to the Camera3D) under the Player.
## It fires a ray from the camera centre and detects objects that implement
## the InteractableBase interface (i.e. have an interact() method).
## Shows a HUD prompt when an interactable is in range.

class_name InteractRay
extends RayCast3D

# Maximum interaction distance (metres)
@export var interact_distance: float = 2.5

# Reference to the HUD label that shows the prompt (set via the editor or LevelManager)
@export var prompt_label: Label

# Currently targeted interactable (or null)
var _current_target: Node = null

# -------------------------------------------------
func _ready() -> void:
	# Configure the raycast
	target_position = Vector3(0.0, 0.0, -interact_distance)
	collision_mask = 0b11111111  # Collide with all layers; tune per project
	enabled = true

	if prompt_label:
		prompt_label.visible = false

# -------------------------------------------------
func _process(_delta: float) -> void:
	force_raycast_update()

	var hit := get_collider()

	# Check if we hit something that is interactable
	if hit and hit.has_method("get_interact_prompt"):
		if hit != _current_target:
			_current_target = hit
			_show_prompt(hit.get_interact_prompt())
	else:
		if _current_target != null:
			_current_target = null
			_hide_prompt()

	# Fire interaction when player presses interact key
	if Input.is_action_just_pressed("interact") and _current_target != null:
		if _current_target.has_method("interact"):
			_current_target.interact()

# -------------------------------------------------
func _show_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = true

func _hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false
