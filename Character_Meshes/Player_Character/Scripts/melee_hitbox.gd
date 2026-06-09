extends Area3D

@onready var player = get_tree().get_first_node_in_group("Player") 

var base_damage: int = 0
var knockback_force: float = 0.0
var crit_chance: float = 0.0 # 15% chance??
var crit_multiplier: float = 0.0

@onready var hit_shape = $CollisionShape3D

func _ready():
	# Keep it turned off so you don't hurt things by just standing near them
	base_damage = player.base_damage
	knockback_force = player.knockback_force
	crit_chance = player.crit_chance
	crit_multiplier = player.crit_multiplier
	
	hit_shape.disabled = true
	body_entered.connect(_on_body_entered)

func swing_weapon():
	hit_shape.disabled = false
	
	# Instantly check if anything is ALREADY inside the box
	
	get_tree().create_timer(0.3).timeout.connect(func(): hit_shape.disabled = true)
	#var targets = get_overlapping_bodies()
	#for body in targets:
		#print("Body print works!")
		#print("Body is ", body)
		#_on_body_entered(body)
		
	#get_tree().create_timer(0.2).timeout.connect(func(): monitoring = false)

func _on_body_entered(body):
	print("Body is ", body)
	if body != owner and body.has_method("take_damage"):
		var push_dir = global_position.direction_to(body.global_position)
		push_dir.y += 0.2
		
		# dictionaries are fckn epic.
		var hit_data = {
			"damage": base_damage,
			"knockback": push_dir.normalized() * knockback_force,
			"crit_chance": crit_chance,
			"crit_mult": crit_multiplier
		}
		
		# Send the dictionary to the target
		body.take_damage(hit_data)
