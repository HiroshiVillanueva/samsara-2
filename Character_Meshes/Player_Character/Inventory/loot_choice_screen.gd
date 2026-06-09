extends ColorRect

@onready var buttons = [
	$HBoxContainer/Choice1,
	$HBoxContainer/Choice2,
	$HBoxContainer/Choice3
]

var offered_items: Array[ItemData] = []

func _ready():
	hide()
	Events.open_loot_choice.connect(_on_loot_choice_opened)
	
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))

func _on_loot_choice_opened(choices: Array[ItemData]):
	#LOCK THE INVENTORY 
	Events.is_choosing_loot = true 
	
	offered_items = choices
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	for i in range(buttons.size()):
		var item = choices[i]
		var btn = buttons[i]
		
		btn.get_node("NameLabel").text = item.item_name
		btn.get_node("Icon").texture = item.icon
		btn.get_node("NameLabel").add_theme_color_override("font_color", item.get_tier_color())
		
		# BUILD THE DESCRIPTION TEXT
		var tier_string = ItemData.Tier.keys()[item.item_tier]
		var full_desc = "[" + tier_string + "]\n\n" + item.description
		
		# Show them the durability.
		if item.durability_trigger != ItemData.DurabilityTrigger.NONE:
			full_desc += "\n\nDurability: " + str(item.max_durability)
			
		btn.get_node("DescLabel").text = full_desc
		
	show()

func _on_button_pressed(index: int):
	var chosen_item = offered_items[index]
	
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("InventoryManager"):
		var inv = player.get_node("InventoryManager")
		inv.add_to_backpack(chosen_item)
		
	#UNLOCK THE UI
	Events.is_choosing_loot = false
	hide()
	get_tree().paused = false
