## touch_buttons.gd
## Manages on-screen Spray and Interact touch buttons.
## Injects virtual input actions so existing game logic (spray_tool.gd,
## interact_ray.gd) keeps working without modification.

extends Control

@onready var _spray_btn:    Button = $SprayButton
@onready var _interact_btn: Button = $InteractButton

var _interact_busy: bool = false

# -------------------------------------------------
func _ready() -> void:
	# Spray — hold to spray (button_down / button_up)
	_spray_btn.button_down.connect(_on_spray_down)
	_spray_btn.button_up.connect(_on_spray_up)

	# Interact — tap to interact
	_interact_btn.pressed.connect(_on_interact_pressed)

# -------------------------------------------------
func _on_spray_down() -> void:
	Input.action_press("spray")

func _on_spray_up() -> void:
	Input.action_release("spray")

# -------------------------------------------------
func _on_interact_pressed() -> void:
	if _interact_busy:
		return
	_interact_busy = true
	Input.action_press("interact")
	await get_tree().process_frame
	Input.action_release("interact")
	_interact_busy = false
