## trash_item.gd
## An individual piece of trash (paper ball, wrapper, cup) scattered in a stall.
## Player looks at it and presses E to pick it up — it scales down and disappears.
## Emits picked_up so the TaskManager can track progress.

class_name TrashItem
extends CSGBox3D

# -------------------------------------------------
# Signals
signal picked_up(item: TrashItem)

# -------------------------------------------------
@export var item_name: String = "trash"

# -------------------------------------------------
func _ready() -> void:
	# Enable collision so InteractRay can detect this CSGBox3D
	use_collision = true

# -------------------------------------------------
## Returns the HUD prompt when the player aims at this node.
func get_interact_prompt() -> String:
	return "Press E to pick up %s" % item_name

# -------------------------------------------------
## Called by InteractRay when the player presses the interact key.
func interact() -> void:
	emit_signal("picked_up", self)
	# Quick scale-down tween for satisfying pickup feel
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(queue_free)
