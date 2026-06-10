extends Control

@onready var equip_slots = $EquipContainer.get_children() # Adjust paths based on your layout.
@onready var bag_slots = $BagContainer.get_children()

#We need better tool tip visuals and infromation.
@onready var tooltip = $Tooltip
@onready var tooltip_name = $Tooltip/MarginContainer/VBoxContainer/ItemName
@onready var tooltip_desc = $Tooltip/MarginContainer/VBoxContainer/ItemDesc
@onready var tooltip_dura = $Tooltip/MarginContainer/VBoxContainer/ItemDura

func _ready():
	Events.inventory_updated.connect(_refresh_ui)
	
	Events.item_hovered.connect(_on_item_hovered)
	
	hide()
	tooltip.hide() # Make sure the tooltip starts invisible!
	
	for i in range(bag_slots.size()):
		bag_slots[i].backpack_index = i

func _process(delta):
	if Input.is_action_just_pressed("toggle_inventory"): 
		if Events.is_choosing_loot:
			return
		
		visible = !visible
		
		if visible:
			_refresh_ui()
			get_tree().paused = true # Freeze the game
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Show the mouse cursor.
		else:
			get_tree().paused = false # Unfreeze.
			# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if tooltip.visible:
		# Added a slight offset
		# so the window doesn't physically cover the mouse cursor!
		tooltip.global_position = get_global_mouse_position() + Vector2(15, 15)

func _on_item_hovered(item: ItemData, is_hovering: bool):
	if is_hovering and item != null:
		tooltip_name.text = item.item_name
		
		# Color the name based on the Tier.
		tooltip_name.add_theme_color_override("font_color", item.get_tier_color())
		
		# Add the Tier name to the description for extra clarity
		var tier_string = ItemData.Tier.keys()[item.item_tier]
		tooltip_desc.text = "[" + tier_string + "]\n" + item.description
		
		if item.durability_trigger != ItemData.DurabilityTrigger.NONE:
			tooltip_dura.text = "Durability: " + str(item.current_durability) + " / " + str(item.max_durability)
			tooltip_dura.show()
		else:
			tooltip_dura.hide()
			
		tooltip.show()
	else:
		tooltip.hide()
func _refresh_ui():
	var player = get_tree().get_first_node_in_group("Player")
	if player == null or not player.has_node("InventoryManager"): return
	var inv = player.get_node("InventoryManager")
	
	# Create Equip Slots.
	for slot in equip_slots:
		if slot.is_equip_slot:
				slot.set_item(inv.equipment[slot.equip_slot_name])
			
	# Create Backpack Slots
	for i in range(bag_slots.size()):
		# Check if the backend array is big enough
		if i < inv.backpack.size():
			bag_slots[i].set_item(inv.backpack[i])
