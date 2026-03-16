## interactable_base.gd
## Base class for all interactable objects in the world
## (tissue holder, soap dispenser, trash bin, etc.).
##
## Subclasses override:
##   - get_interact_prompt() → String
##   - interact()
##   - is_available() → bool
##
## The InteractRay looks for has_method("get_interact_prompt") and
## has_method("interact") so this class_name is optional, but useful for
## type-checking.

class_name InteractableBase
extends Node3D

# -------------------------------------------------
# Signals
signal interacted(interactable)

# -------------------------------------------------
@export var prompt_text: String = "Press E to interact"
@export var is_enabled: bool = true

# -------------------------------------------------
## Returns the prompt string shown in the HUD.
## Override in subclasses for dynamic text (e.g., "Press E to replace tissue").
func get_interact_prompt() -> String:
	return prompt_text if is_enabled else ""

# -------------------------------------------------
## Called when the player presses the interact key while aiming at this object.
## Override in subclasses to perform the actual interaction logic.
func interact() -> void:
	if not is_enabled:
		return
	emit_signal("interacted", self)
	_on_interact()

# -------------------------------------------------
## Override this in subclasses instead of overriding interact() directly.
func _on_interact() -> void:
	pass

# -------------------------------------------------
## Returns whether this interactable is currently available to use.
func is_available() -> bool:
	return is_enabled
