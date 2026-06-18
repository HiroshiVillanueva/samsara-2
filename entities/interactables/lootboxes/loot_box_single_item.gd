extends Area3D

@export var item_to_give: ItemData

# --- Animation Settings ---
@export_group("Logo Animation")
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2
@export var twist_speed: float = 1.0
@export var twist_amount: float = 0.5

@export_group("UI Pop Settings")
@export var pop_duration: float = 0.4  # How long the pop animation takes

# --- Child Nodes ---
@onready var logo: Node3D = $Logo 
@onready var name_label = $Name
@onready var btn_label = $Btn

var player_in_range: Node3D = null

# Animation math & state variables
var time_passed: float = 0.0
var initial_logo_y: float = 0.0
var initial_logo_rot_y: float = 0.0

# Store initial scales so we know what size to bounce back to
var initial_name_scale: Vector3 = Vector3.ONE
var initial_btn_scale: Vector3 = Vector3.ONE

# Store the active tween so we can interrupt it if the player runs in and out quickly
var ui_tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 1. Store the logo's starting position
	if logo:
		initial_logo_y = logo.position.y
		initial_logo_rot_y = logo.rotation.y
		
	# 2. Setup the Labels for popping
	if name_label and btn_label:
		# Save their original sizes from the editor
		initial_name_scale = name_label.scale
		initial_btn_scale = btn_label.scale
		
		# Shrink them to 0 immediately so they are hidden
		name_label.scale = Vector3.ZERO
		btn_label.scale = Vector3.ZERO
		
		if item_to_give:
			name_label.text = item_to_give.item_name
	else:
		push_warning("Could not find 'Name' or 'Btn' nodes. Check your node names!")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = body
		
		if name_label and btn_label:
			_animate_ui(initial_name_scale, initial_btn_scale, Tween.EASE_OUT)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		
		if name_label and btn_label:
			_animate_ui(Vector3.ZERO, Vector3.ZERO, Tween.EASE_IN)

func _animate_ui(target_name_scale: Vector3, target_btn_scale: Vector3, ease_type: Tween.EaseType):
	# If an animation is already playing (e.g., they entered then left really fast), stop it
	if ui_tween and ui_tween.is_valid():
		ui_tween.kill()
		
	# Create a new tween
	ui_tween = create_tween()
	
	# Make both labels animate at the exact same time
	ui_tween.set_parallel(true)
	
	# Animate the Name label
	ui_tween.tween_property(name_label, "scale", target_name_scale, pop_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(ease_type)
		
	# Animate the Btn label
	ui_tween.tween_property(btn_label, "scale", target_btn_scale, pop_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(ease_type)

func _process(delta):
	# --- Logo Animation Logic ---
	if logo:
		time_passed += delta
		logo.position.y = initial_logo_y + sin(time_passed * bob_speed) * bob_height
		logo.rotation.y = initial_logo_rot_y + sin(time_passed * twist_speed) * twist_amount

	# --- Interaction Logic ---
	if player_in_range and Input.is_action_just_pressed("interact"):
		if player_in_range.has_node("InventoryManager"):
			var inv = player_in_range.get_node("InventoryManager")
			inv.add_to_backpack(item_to_give)
			queue_free()
