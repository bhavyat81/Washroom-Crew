## tool_data.gd
## Resource that defines a cleaning tool and its upgrade stats.
## Create .tres files (one per tool tier) in resources/tools/.
##
## Example usage:
##   var basic_spray: ToolData = preload("res://resources/tools/basic_spray.tres")

class_name ToolData
extends Resource

# -------------------------------------------------
@export var tool_name: String = "Basic Spray Nozzle"
@export var tool_id: String = "basic_spray"
@export var description: String = "Standard issue spray nozzle. Gets the job done."
@export var icon: Texture2D

# Gameplay stats
@export var spray_power: float = 0.4           # Dirt removed per second
@export var spray_range: float = 3.0           # Ray distance in metres
@export var foam_speed_multiplier: float = 1.0 # Multiplier for foam application speed
@export var has_foam: bool = true
@export var has_uv_mode: bool = false          # UV stain detector (later tiers)

# Progression
@export var unlock_cost: int = 0               # In-game currency to unlock
@export var is_unlocked: bool = true           # Starter tool is free

# Visual / skin data
@export var model_scene: PackedScene           # 3D model of the tool
@export var skin_id: String = "default"        # Active skin (cosmetic)

# Tool tier label (used by progression UI)
@export_enum("Starter", "Improved", "Advanced", "Pro") var tier: int = 0
