extends Area3D

# Drag and drop all your ItemData resources into this array in the Inspector!
@export var loot_pool: Array[ItemData] 

var player_in_range: Node3D = null
var is_opened: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _process(delta):
	if not is_opened and player_in_range and Input.is_action_just_pressed("interact"):
		open_box()

func open_box():
	is_opened = true
	var generated_choices: Array[ItemData] = []
	
	# Generate exactly 3 items
	for i in range(3):
		var new_item = _roll_weighted_item().duplicate()
		new_item.roll_stats() # Randomize its stats before we show it to the player!
		generated_choices.append(new_item)
		
	# Tell the UI to pop up with these 3 items
	Events.open_loot_choice.emit(generated_choices)
	
	# Optional: Delete the chest, or play an open animation
	queue_free()

# --- THE WEIGHTED RANDOMIZER ---
func _roll_weighted_item() -> ItemData:
	# Roll a number between 0.0 and 100.0
	var roll = randf() * 100.0
	var target_tier = ItemData.Tier.COMMON
	
	# 1% chance for Legendary
	if roll <= 1.0: target_tier = ItemData.Tier.LEGENDARY
	# 4% chance for Epic (1 to 5)
	elif roll <= 5.0: target_tier = ItemData.Tier.EPIC
	# 15% chance for Rare (5 to 20)
	elif roll <= 20.0: target_tier = ItemData.Tier.RARE
	# 30% chance for Uncommon (20 to 50)
	elif roll <= 50.0: target_tier = ItemData.Tier.UNCOMMON
	# 50% chance for Common (50 to 100)
	else: target_tier = ItemData.Tier.COMMON
		
	# Filter our master loot pool to find items that match the tier we just rolled
	var valid_items = []
	for item in loot_pool:
		if item.item_tier == target_tier:
			valid_items.append(item)
			
	# If you didn't put any Epic items in the inspector, 
	# but the player rolled an Epic, just give them a completely random item.
	if valid_items.is_empty():
		return loot_pool.pick_random()
		
	# Pick a random item from the correct tier.
	return valid_items.pick_random()
