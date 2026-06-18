extends Area3D

# Drag and drop all your ItemData resources into this array in the Inspector!
@export var loot_pool: Array[ItemData] 

# --- Animation Settings ---
@export_group("Logo Animation")
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2
@export var twist_speed: float = 1.0
@export var twist_amount: float = 0.5

@export_group("UI Pop Settings")
@export var pop_duration: float = 0.4

# --- Child Nodes ---
@onready var logo: Node3D = $Logo 
@onready var name_label = $Name
@onready var btn_label = $Btn

var player_in_range: Node3D = null
var is_opened: bool = false

# Animation math & state variables
var time_passed: float = 0.0
var initial_logo_y: float = 0.0
var initial_logo_rot_y: float = 0.0

var initial_name_scale: Vector3 = Vector3.ONE
var initial_btn_scale: Vector3 = Vector3.ONE
var ui_tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 1. Setup the Logo for bobbing
	if logo:
		initial_logo_y = logo.position.y
		initial_logo_rot_y = logo.rotation.y
		
	# 2. Setup the Labels for popping (Skipping text modification!)
	if name_label and btn_label:
		initial_name_scale = name_label.scale
		initial_btn_scale = btn_label.scale
		
		# Shrink to zero to hide initially
		name_label.scale = Vector3.ZERO
		btn_label.scale = Vector3.ZERO

func _on_body_entered(body):
	# Only pop up the UI if the player enters and the box is still closed
	if body.is_in_group("Player") and not is_opened:
		player_in_range = body
		if name_label and btn_label:
			_animate_ui(initial_name_scale, initial_btn_scale, Tween.EASE_OUT)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		if name_label and btn_label:
			_animate_ui(Vector3.ZERO, Vector3.ZERO, Tween.EASE_IN)

func _animate_ui(target_name_scale: Vector3, target_btn_scale: Vector3, ease_type: Tween.EaseType):
	if ui_tween and ui_tween.is_valid():
		ui_tween.kill()
		
	ui_tween = create_tween()
	ui_tween.set_parallel(true)
	
	ui_tween.tween_property(name_label, "scale", target_name_scale, pop_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(ease_type)
	ui_tween.tween_property(btn_label, "scale", target_btn_scale, pop_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(ease_type)

func _process(delta):
	# --- Logo Animation Logic ---
	if logo:
		time_passed += delta
		logo.position.y = initial_logo_y + sin(time_passed * bob_speed) * bob_height
		logo.rotation.y = initial_logo_rot_y + sin(time_passed * twist_speed) * twist_amount

	# --- Interaction Logic ---
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
