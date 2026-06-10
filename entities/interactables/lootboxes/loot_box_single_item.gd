extends Area3D

@export var item_to_give: ItemData

var player_in_range: Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = body
		print("Press E to pick up ", item_to_give.item_name) # You can replace this with a 3D UI prompt later!

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _process(delta):
	# If the player is standing near it and presses Interact
	if player_in_range and Input.is_action_just_pressed("interact"):
		if player_in_range.has_node("InventoryManager"):
			var inv = player_in_range.get_node("InventoryManager")
			inv.add_to_backpack(item_to_give)
			queue_free() # Delete from the world
