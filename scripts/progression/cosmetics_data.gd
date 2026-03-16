## cosmetics_data.gd
## Resource for cosmetic items (glove/uniform skins, spray gun skins,
## restroom themes).
## Create .tres files in resources/cosmetics/.

class_name CosmeticsData
extends Resource

# -------------------------------------------------
@export_enum("GloveSkin", "UniformSkin", "SprayGunSkin", "RoomTheme") var cosmetic_type: int = 0

@export var cosmetic_name: String = "Default Gloves"
@export var cosmetic_id: String = "gloves_default"
@export var description: String = "Standard-issue cleaning gloves."
@export var icon: Texture2D

# Visual assets
@export var material_override: Material          # Applied to the relevant mesh
@export var preview_image: Texture2D

# Monetization
@export var is_unlocked: bool = true             # Default cosmetics are free
@export var unlock_cost: int = 0                 # Soft currency
@export var is_premium: bool = false             # True = hard currency / IAP
@export var iap_product_id: String = ""

# Rewarded-ad hook
## If true, player can watch a rewarded ad once to temporarily use this cosmetic
@export var trial_via_rewarded_ad: bool = false

# Rarity for UI display
@export_enum("Common", "Uncommon", "Rare", "Epic") var rarity: int = 0
