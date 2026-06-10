extends Resource
class_name ItemData #TEMPLATE FOR ALL SUBCLASSES

enum Category { DASH, GUN, GRENADE, GENERAL, ABILITY, CELL1, CELL2, CELL3 }
enum DurabilityTrigger { NONE, ON_TAKE_DAMAGE, ON_SHOOT, ON_DASH, ON_THROW_GRENADE, ON_ABILITY_USE }
enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_group("Metadata")
@export var item_name: String = "Unknown Item"
@export var item_tier: Tier = Tier.COMMON
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Rules & Randomization")
@export var category: Category = Category.GENERAL
@export var durability_trigger: DurabilityTrigger = DurabilityTrigger.NONE

@export var randomize_stats: bool = false
@export var base_durability: int = 100 
@export_range(0.0, 1.0) var stat_variance: float = 0.2 

@export_group("Player Stats")
@export var bonus_max_health: int = 0 ## Default is 100
@export var bonus_max_health_bool: bool = false ## Default is 100

@export var bonus_armor: int = 0 ## Default is 0
@export var bonus_armor_bool: bool = false ## Default is 0

@export_group("Movement Settings")
@export_range(0.0, 1.0) var bonus_speedMultiplier: float = 0 ## Default is 1.0
@export var bonus_speedMultiplier_bool: bool = false ## Default is 1.0

var current_durability: int = 100
var max_durability: int = 100

func roll_stats():
	if randomize_stats:
		var min_mult = 1.0 - stat_variance
		var max_mult = 1.0 + stat_variance
		
		# Roll the Durability 
		var dura_multiplier = randf_range(min_mult, max_mult)
		max_durability = int(base_durability * dura_multiplier)
		current_durability = max_durability
		
		# Roll the Ints and Floats
		var properties = get_property_list()
		for prop in properties:
			var prop_name = prop["name"] # Using dictionary syntax
			var prop_hint = prop["hint"] 
			
			# skip everything that is not a number
			if prop_hint == PROPERTY_HINT_ENUM:
				continue # Skip to the next variable immediately.
			
			# Proceed normally for safe variables
			if prop_name.begins_with("bonus_"):
				var val = get(prop_name)
				
				if val != null and typeof(val) in [TYPE_INT, TYPE_FLOAT] and val != 0.0:
					var random_multiplier = randf_range(min_mult, max_mult)
					
					if typeof(val) == TYPE_INT: #not entirely sure if I have to go through this if statement.
						set(prop_name, int(val * random_multiplier))
					else:
						set(prop_name, val * random_multiplier)
	else:
		max_durability = base_durability
		current_durability = max_durability

func get_tier_color() -> Color:
	match item_tier:
		Tier.COMMON: return Color(0.7, 0.7, 0.7)
		Tier.UNCOMMON: return Color(0.2, 0.8, 0.2)
		Tier.RARE: return Color(0.1, 0.5, 1.0)
		Tier.EPIC: return Color(0.6, 0.1, 0.8)
		Tier.LEGENDARY: return Color(1.0, 0.8, 0.1)
	return Color(0.939, 0.564, 0.736, 1.0)
