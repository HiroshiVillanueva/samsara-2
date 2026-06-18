extends Node

# The Backpack (Un-equipped items)
const MAX_BACKPACK_SIZE = 24
var backpack: Array[ItemData] = []

# The Equipment Slots
var equipment: Dictionary = {
	"Gun": null,
	"Dash": null,
	"Grenade": null,
	"Gen1": null,
	"Gen2": null,
	"Gen3": null,
	"Gen4": null,
	"Cell1": null, # cell slots or "clots" are what gives items the buffs.
	"Cell2": null,
	"Cell3": null,
	"Ability": null
}

var base_stats: Dictionary = {}
@onready var player = get_parent()

@onready var stat_targets: Array[Node] = [
	player,
	player.get_node_or_null("GrenadeAbility"),
	# player.get_node_or_null("DashAbility") Add future components here.
]

const STACKABLE_STATS = [
	"sweet_spot_window",
	"max_health",
	"armor",
	"speedMultiplier", 
	"max_dash_charges",
	"dash_recharge_time",
	"max_ammo",
	"reload_time",
	"projectiles_per_shot",
	"spread_angle_degrees",
	"fire_rate",
	"gun_crit_chance",
	"gun_crit_multiplier",
	"gun_knockback",
	"burst_count",
	"burst_rate",
	"hitscan_damage",
	"hitscan_range",
	"cooldown_time",
	"travel_time",
	"max_throw_distance",
	"damage",
	"explosion_radius",
	"knockback_intensity",
	"spread_angle_degrees"
]

const OVERRIDE_STATS = [
	"range_shake_intensity",
	"dash_buff",
	"infinite_ammo",
	"ammo_type",
	"fire_mode",
	"shoot_type",
	"weapon_buff",
	"muzzleType",
	"grenade_buff",
	"grenade_type",
	"has_grenade_unlocked",
	"projectiles_per_throw"
]

func _ready():
	backpack.resize(MAX_BACKPACK_SIZE)
	_take_naked_snapshot()
	
	Events.inventory_slots_swapped.connect(_on_inventory_ui_changed)
	Events.item_right_clicked.connect(_on_right_clicked)

# Helper to find a stat, no matter which component owns it
func _get_stat_from_target(stat_name: String):
	for target in stat_targets:
		if target == null: continue
		
		# Godot's get() returns null if the variable doesn't exist on that specific node
		var val = target.get(stat_name)
		if val != null:
			return val
	#else:
	push_error("Inventory Error: Nobody owns the stat: " + stat_name)
	return null

# Helper to apply math directly to the component that owns the stat
func _set_stat_on_target(stat_name: String, value):
	for target in stat_targets:
		if target == null: continue
		
		if target.get(stat_name) != null:
			target.set(stat_name, value)
			return # Stop searching once we found the owner.

func _take_naked_snapshot():
	var all_stats = STACKABLE_STATS + OVERRIDE_STATS
	for stat_name in all_stats:
		base_stats[stat_name] = _get_stat_from_target(stat_name)
		
	print("It works!")
	print("Vault Hitscan Damage saved as: ", base_stats["hitscan_damage"]) # add more if you are testing if you want.

func reset_stats():
	var all_stats = STACKABLE_STATS + OVERRIDE_STATS
	
	for stat_name in all_stats:
		var naked_value = base_stats[stat_name]
		print("reset values: ", stat_name, base_stats[stat_name])
		player.set(stat_name, naked_value) 	

func recalculate_player_stats():
	if base_stats.is_empty(): ## Gemini suggested this, idk how this would happen but sure.
		push_error("Inventory tried to calculate before snapshot was taken!")
		return
		
	reset_stats()	
	if player.hitscan_damage != base_stats["hitscan_damage"]:
		push_error("Inventory Error: u suck at managing player stats in the inventory")
		
	# Re-apply buffs
	for slot_key in equipment.keys():
		var item = equipment[slot_key]
		
		if item != null:
			print("Applying item: ", item.item_name)
			
			# Apply stackables stats first.
			for stat_name in STACKABLE_STATS:
				var bonus_name = "bonus_" + stat_name
				var bonus_value = item.get(bonus_name)
				
				if bonus_value != null and typeof(bonus_value) in [TYPE_INT, TYPE_FLOAT] and bonus_value != 0.0 and item.get(bonus_name+ "_bool"):
					#var current_player_val = player.get(stat_name)
					#player.set(stat_name, current_player_val + bonus_value)
					var current_val = _get_stat_from_target(stat_name)
					_set_stat_on_target(stat_name, current_val + bonus_value)
					print("  -> Stacked: ", stat_name, " (+", bonus_value, ")")
					
			# Overrides second.
			for stat_name in OVERRIDE_STATS:
				var override_name = "bonus_" + stat_name
				var override_value = item.get(override_name)
				
				if override_value != null and item.get(override_name+ "_bool"):
					var should_override = false
					match typeof(override_value):
						TYPE_STRING:
							if override_value != "": should_override = true
						TYPE_INT, TYPE_BOOL, TYPE_FLOAT: 
							if typeof(override_value) == TYPE_BOOL and override_value == true: should_override = true
							if typeof(override_value) == TYPE_INT or typeof(override_value) == TYPE_FLOAT: should_override = true
							
					if should_override:
						_set_stat_on_target(stat_name, override_value)

	# FAILSAFES, ignore this, if the code works we shouldn't need this and I got tired making this.
	if player.current_health > player.max_health:
		player.current_health = player.max_health
		
	if Events.has_user_signal("player_health_changed"):
		Events.player_health_changed.emit(player.current_health, player.max_health)
		
	print("Final Damage: ", player.hitscan_damage, " ---\n")

func add_to_backpack(item: ItemData):
	var empty_index = backpack.find(null)
	
	if empty_index != -1:
		# Create a unique clone of the base item
		var new_item = item.duplicate() 
		
		# Basically, to add a level of interest in the game, we slightly randomize the stats of the items.
		# This forces you to save the stronger items for tougher levels or bosses.
		# What i'm thinking also is currently it's only tiers, we could implement levels where it weighs the rolls for better stats.
		new_item.roll_stats() 
		
		# Put the freshly rolled item in the bag
		backpack[empty_index] = new_item
		Events.inventory_updated.emit() 
		print("Picked up: ", new_item.item_name, " | Max Dura: ", new_item.max_durability)
	else:
		print("Backpack is completely full!")

# DURABILITY DRAIN
func trigger_durability(trigger_type: ItemData.DurabilityTrigger, amount: int = 1):
	var did_durability_change = false # Track if anything actually degraded
	
	for key in equipment.keys():
		var item = equipment[key]
		if item != null and item.durability_trigger == trigger_type:
			item.current_durability -= amount
			did_durability_change = true 
			
			if item.current_durability <= 0:
				print(item.item_name, " BROKE!")
				equipment[key] = null 
				recalculate_player_stats()
				
	# If any item lost durability, update UI.
	if did_durability_change:
		Events.inventory_updated.emit()

func _on_inventory_ui_changed(origin_slot, new_slot):
	# Sync our internal memory to whatever the UI just visually did.
	_sync_single_slot(origin_slot)
	_sync_single_slot(new_slot)
	recalculate_player_stats()
	Events.inventory_updated.emit()

# Helper to safely move data in and out of the backpack array versus equipment dictionary.
func _sync_single_slot(slot):
	if slot.is_equip_slot:
		equipment[slot.equip_slot_name] = slot.current_item
	else:
		# Because the slot knows its own index, we just overwrite the backend array 
		# directly. No more erasing or appending, which preserves empty spaces.
		backpack[slot.backpack_index] = slot.current_item

# QUICK EQUIP
func _on_right_clicked(slot):
	if slot.is_equip_slot:
		if slot.current_item != null:
			# Find an empty space to put the unequipped item
			var empty_index = backpack.find(null)
			if empty_index != -1:
				backpack[empty_index] = slot.current_item
				equipment[slot.equip_slot_name] = null
			else:
				print("Cannot unequip, backpack is full!")
	else:
		var item = slot.current_item
		var target_slot = _find_valid_equip_slot(item)
		
		if target_slot != "":
			if equipment[target_slot] != null:
				# Swap them: Put the equipped item into the exact slot we clicked from
				backpack[slot.backpack_index] = equipment[target_slot]
			else:
				# It was empty, so clear the backpack slot.
				backpack[slot.backpack_index] = null
				
			equipment[target_slot] = item
			
	Events.inventory_updated.emit()
	recalculate_player_stats()

func _find_valid_equip_slot(item: ItemData) -> String:
	match item.category:
		ItemData.Category.GUN: return "Gun"
		ItemData.Category.DASH: return "Dash"
		ItemData.Category.GRENADE: return "Grenade"
		ItemData.Category.ABILITY: return "Ability"
		ItemData.Category.CELL1: return "Cell1" # Cells are seperate because each slot uses unique cells exclusive to itself.
		ItemData.Category.CELL2: return "Cell2"
		ItemData.Category.CELL3: return "Cell3"
		ItemData.Category.GENERAL:
			if equipment["Gen1"] == null: return "Gen1"
			if equipment["Gen2"] == null: return "Gen2"
			if equipment["Gen3"] == null: return "Gen3"
			return "Gen4"
	return ""
