## hud.gd
## Heads-up display overlay.
## Shows: current stall name, timer countdown, dirt bar, foam bar,
## spray ammo bar, and the interaction prompt label.

extends Control

# -------------------------------------------------
@onready var stall_name_label: Label    = $MarginContainer/VBoxContainer/StallNameLabel
@onready var timer_label: Label         = $MarginContainer/VBoxContainer/TimerLabel
@onready var dirt_bar: ProgressBar      = $MarginContainer/VBoxContainer/DirtBar
@onready var foam_bar: ProgressBar      = $MarginContainer/VBoxContainer/FoamBar
@onready var spray_bar: ProgressBar     = $MarginContainer/VBoxContainer/SprayBar
@onready var prompt_label: Label        = $PromptLabel

# -------------------------------------------------
func _ready() -> void:
	foam_bar.visible = false
	prompt_label.visible = false
	update_timer(180.0)
	update_dirt(1.0)
	spray_bar.max_value = 100.0
	spray_bar.value = 100.0

# -------------------------------------------------
## Updates the stall name shown at the top of the HUD.
func set_stall_name(name_text: String) -> void:
	stall_name_label.text = name_text

# -------------------------------------------------
## Called by LevelManager every frame with remaining seconds.
func update_timer(seconds: float) -> void:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	# Colour the timer red when under 30 seconds
	timer_label.add_theme_color_override("font_color",
		Color.RED if seconds < 30.0 else Color.WHITE)

# -------------------------------------------------
## Called by CleanableSurface dirt_changed signal (0.0 = clean, 1.0 = dirty).
func update_dirt(dirt_value: float) -> void:
	dirt_bar.value = (1.0 - dirt_value) * 100.0   # Bar shows cleanliness

# -------------------------------------------------
## Called by FoamSystem foam_progress_changed signal (0.0 .. 1.0).
func update_foam(progress: float) -> void:
	foam_bar.visible = progress > 0.0 and progress < 1.0
	foam_bar.value = progress * 100.0

# -------------------------------------------------
## Called by SprayTool ammo_changed signal.
func update_ammo(current: float, maximum: float) -> void:
	spray_bar.max_value = maximum
	spray_bar.value = current

# -------------------------------------------------
## Shows or hides the interaction prompt.
func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text.length() > 0
