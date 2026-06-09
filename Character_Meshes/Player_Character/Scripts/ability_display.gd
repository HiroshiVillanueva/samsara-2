extends VBoxContainer

@onready var icon_rect = $Icon
@onready var durability_bar = $DurabilityBar

func setup(item: ItemData):
	icon_rect.texture = item.icon
	
	# If the item actually uses durability, set up the bar. CARLOS REMEMBER THIS
	if item.durability_trigger != ItemData.DurabilityTrigger.NONE:
		durability_bar.max_value = item.max_durability
		durability_bar.value = item.current_durability
		durability_bar.show()
	else:
		# If it's an unbreakable item, hide the bar completely for a cleaner look
		durability_bar.hide()
