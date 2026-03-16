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

	# Walk up the parent chain from the raw collider to find a node that
	# implements the interact interface (e.g. CSGBox3D generates a child
	# StaticBody3D as its physics collider — we need to reach the CSGBox3D).
	var interactable = _find_interactable(hit)

	if interactable:
		var prompt := interactable.get_interact_prompt()
		if prompt != "":
			if interactable != _current_target:
				_current_target = interactable
			_show_prompt(prompt)
		else:
			# Interactable exists but prompt is empty (e.g. already used)
			_current_target = null
			_hide_prompt()
	else:
		if _current_target != null:
			_current_target = null
			_hide_prompt()

# -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Fire interaction when player presses interact key
	if event.is_action_pressed("interact") and _current_target != null:
		if _current_target.has_method("interact"):
			_current_target.interact()
		get_viewport().set_input_as_handled()

# -------------------------------------------------
## Walks up the scene tree from node to find the nearest ancestor (or self)
## that implements get_interact_prompt.  This is necessary because CSGBox3D
## nodes with use_collision=true create an auto-generated StaticBody3D child
## as the actual physics collider; the script lives on the parent CSGBox3D.
func _find_interactable(node: Node) -> Node:
	var check = node
	while check != null:
		if check.has_method("get_interact_prompt"):
			return check
		check = check.get_parent()
	return null

# -------------------------------------------------
func _show_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = true

func _hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false
