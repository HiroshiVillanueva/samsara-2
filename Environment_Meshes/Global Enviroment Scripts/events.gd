extends Node

var is_choosing_loot: bool = false

signal inventory_updated # Tells the UI to redraw itself
signal inventory_slots_swapped(slot_a: Control, slot_b: Control) # For Drag and Drop
signal item_right_clicked(slot: Control) # For Quick-Equip
signal item_hovered(item: ItemData, is_hovering: bool) # Should display infromation
signal open_loot_choice(choices: Array[ItemData]) # Grab item
