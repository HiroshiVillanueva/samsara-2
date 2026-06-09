extends PanelContainer

## Whether the slot is gives the player the effect of the iem in the slot.
@export var is_equip_slot: bool = false
## Again, do I need to explain this?? Why are you reading it's tooltip??
@export var equip_slot_name: String = "" 
## The items that only able to be placed within this slot.
@export var allowed_category: ItemData.Category = ItemData.Category.GENERAL 

var backpack_index: int = -1
var is_mouse_inside: bool = false
var current_item: ItemData = null
var previous_item: ItemData = null # Helps the manager track what left the slot

func _ready():
	# Connect Godot's built-in hover signals to our own functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	is_mouse_inside = true # We know the mouse is here!
	if current_item != null:
		Events.item_hovered.emit(current_item, true)

func _on_mouse_exited():
	is_mouse_inside = false # Mouse left
	Events.item_hovered.emit(null, false)

func set_item(item: ItemData):
	previous_item = current_item
	current_item = item
	
	if item:
		$MarginContainer/IconDisplay.texture = item.icon
	else:
		$MarginContainer/IconDisplay.texture = null
		
	# FORCE TOOLTIP REFRESH
	# If item inside slot changes, AND the player is currently looking at the item inside slot.
	if is_mouse_inside:
		if current_item != null:
			# Tell the tooltip to instantly update to the new item.
			Events.item_hovered.emit(current_item, true)
		else:
			# If changes to empty, hide the tooltip.
			Events.item_hovered.emit(null, false)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		print("Right click detected on slot!")
		if current_item != null:
			Events.item_right_clicked.emit(self) 

func _get_drag_data(at_position):
	if current_item == null: 
		return null
		
	# SCALING THE RAW PNG TO FIT SLOT
	var preview_image = TextureRect.new()
	preview_image.texture = current_item.icon
	preview_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Set this to the exact size of your UI slots (e.g., 64x64).
	# Might change this when we add visuals.
	var slot_size = Vector2(64, 64) 
	preview_image.custom_minimum_size = slot_size
	preview_image.size = slot_size
	
	# Make it slightly transparent
	preview_image.modulate.a = 0.5 
	
	# CENTERING ON THE MOUSE
	# set_drag_preview() always glues the top-left (0,0) to the cursor.
	var preview_wrapper = Control.new()
	preview_wrapper.add_child(preview_image)
	
	# Shift the image left and up by exactly half its size to stay center.
	preview_image.position = -(slot_size / 2.0)
	set_drag_preview(preview_wrapper)
	
	return {"item": current_item, "origin_slot": self}

func _can_drop_data(at_position, data):
	var incoming_item = data["item"] as ItemData
	if is_equip_slot:
		if equip_slot_name in ["Gun", "Dash", "Grenade", "Ability", "Cell1", "Cell2", "Cell3"]:
			return incoming_item.category == allowed_category
		else:
			return incoming_item.category == ItemData.Category.GENERAL
	return true

func _drop_data(at_position, data):
	var origin_slot = data["origin_slot"]
	var item_to_move = data["item"]
	
	var my_old_item = current_item
	set_item(item_to_move)
	origin_slot.set_item(my_old_item)
	
	Events.inventory_slots_swapped.emit(origin_slot, self)
