extends VBoxContainer

@export var ability_display_scene: PackedScene

func _ready():
	# Listen to the exact same signal your main inventory uses!
	Events.inventory_updated.connect(refresh_hud)
	call_deferred("refresh_hud")

func refresh_hud():
	for child in get_children():
		child.queue_free()
		
	var player = get_tree().get_first_node_in_group("Player")
	if player == null or not player.has_node("InventoryManager"): return
	
	var inv = player.get_node("InventoryManager")
	
	# The exact order you want them to appear on screen (top to bottom)
	var display_order = ["Gun", "Dash", "Grenade", "Gen1", "Gen2", "Gen3", "Gen4"]
	
	# Spawn icons for every equipped item
	for slot_key in display_order:
		var item = inv.equipment[slot_key]
		
		if item != null:
			var display_widget = ability_display_scene.instantiate()
			add_child(display_widget)
			
			# Push the data into slots, we need more details!
			display_widget.setup(item)
