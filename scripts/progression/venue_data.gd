## venue_data.gd
## Resource that defines a venue/level pack.
## Create .tres files in resources/venues/.
##
## Venues group related levels together (e.g., "Airport Pack" = 10 levels
## set in an airport restroom).

class_name VenueData
extends Resource

# -------------------------------------------------
@export var venue_name: String = "Airport Terminal"
@export var venue_id: String = "airport"
@export var description: String = "Keep the gate restrooms spotless for thousands of daily travellers."
@export var icon: Texture2D
@export var preview_image: Texture2D

# Theme / atmosphere
@export_enum("Airport", "Stadium", "Mall", "Concert", "Outdoor Festival") var venue_type: int = 0

# Level pack contents
@export var level_scenes: Array[PackedScene] = []   # Ordered list of level scenes
@export var level_count: int = 10

# Unlock conditions
@export var is_unlocked: bool = false
@export var unlock_cost: int = 0                    # In-game currency
@export var is_iap: bool = false                    # True = paid DLC pack
@export var iap_product_id: String = ""             # Platform store product ID

# Monetization hooks
## "rewarded_ad_skip" = player can watch an ad to skip a level timer
@export var rewarded_ad_available: bool = true

# Progression metadata
@export var required_stars_to_unlock: int = 0       # Stars needed from previous pack
