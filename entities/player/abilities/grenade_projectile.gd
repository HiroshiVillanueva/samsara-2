extends Node3D
# The actial process of how a grenade is fired.

# we recieve the information from these externally.
var damage: int = 0
var explosion_radius: float = 0.0
var knockback_intensity: float = 0.0

# Interpolation variables replacing velocity/gravity
var travel_time: float = 1.0 
var time_elapsed: float = 0.0
var start_pos: Vector3
var target_pos: Vector3
var is_thrown: bool = false
var arc_height: float = 10.0 

@onready var player = get_tree().get_first_node_in_group("Player") 
@onready var grenade = player.get_node("GrenadeAbility")

@onready var explosion_area = $Area3D
@onready var collision_shape = $Area3D/CollisionShape3D 
## Scenes used to represent each explosion from diffrent grenade types.
@export var impact_scene: Array[PackedScene] = []

var color: Color

func _ready() -> void:
	if grenade.grenade_buff == grenade.Buffs.SHRAPNEL:
		color = grenade.grenade_colors[0]
	elif grenade.grenade_buff == grenade.Buffs.COVERED:
		color = grenade.grenade_colors[1]
	elif grenade.grenade_buff == grenade.Buffs.SLOWED:
		color = grenade.grenade_colors[2]
	elif grenade.grenade_buff == grenade.Buffs.ATTRACTED:
		color = grenade.grenade_colors[3]
		
func throw_at(p_start_pos: Vector3, p_end_pos: Vector3, time: float):
	start_pos = p_start_pos
	target_pos = p_end_pos
	travel_time = time
	time_elapsed = 0.0
	global_position = start_pos
	
	# adjust size of the explosion
	if collision_shape.shape is CylinderShape3D:
		collision_shape.shape.radius = explosion_radius

	is_thrown = true

# Use _process instead of _physics_process for smoother visual interpolation
func _process(delta: float):
	if not is_thrown:
		return

	# Keep track of how long it has been in the air
	time_elapsed += delta
	
	# "t" is our progress from 0.0 (start) to 1.0 (arrived)
	var t = time_elapsed / travel_time 
	
	# If we reached the target time, snap to the end and explode!
	if t >= 1.0:
		t = 1.0
		is_thrown = false
		explode() # t - 0 = boom B>

	var current_pos = start_pos.lerp(target_pos, t)
	var highest_point = max(start_pos.y, target_pos.y)
	var target_peak_y = highest_point + arc_height
	var midpoint_y = (start_pos.y + target_pos.y) / 2.0
	var height_difference = target_peak_y - midpoint_y

	current_pos.y += height_difference * 4.0 * t * (1.0 - t)
	
	# Move the actual node and mesh
	global_position = current_pos
	if has_node("MeshInstance3D"):
		$MeshInstance3D.rotate_x(10 * delta)

func explode():
	var targets = explosion_area.get_overlapping_bodies()
	var explosion_center = global_position
	var impact = null # Initialize to prevent errors
	
	if impact_scene:
		
		# I have a lot of things that are variations of this.
		# If you can think of a method that is better than this, do tell.
		if grenade.grenade_type == grenade.Explosion.ONE:
			impact = impact_scene[0].instantiate()
		elif grenade.grenade_type == grenade.Explosion.TWO:
			if impact_scene.size() > 1:
				impact = impact_scene[1].instantiate()
		elif grenade.grenade_type == grenade.Explosion.THREE:
			if impact_scene.size() > 1:
				impact = impact_scene[2].instantiate()
				
		if impact != null:
			get_tree().root.add_child(impact)
			impact.primary_color = color
			impact.secondary_color = color
			impact.light_color = color
			#impact.scale = Vector3(explosion_radius, explosion_radius, explosion_radius)
			impact.global_position = global_position
			
	var hit_data = {
			"damage": damage,
			"Weapon_knockback": knockback_intensity,
			"grenade_buff": grenade.grenade_buff
	}	
		
	for body in targets:
		if body.has_method("take_damage"):
			body.take_damage(hit_data)
			
		if body.has_method("apply_knockback"):
			var push_direction = explosion_center.direction_to(body.global_position)
			push_direction.y += 0.5 
			
			var final_knockback = push_direction.normalized() * knockback_intensity
			body.apply_knockback(final_knockback)
			
	print("Exploded at: ", global_position)
	get_tree().create_timer(travel_time * 1.15).timeout.connect(impact.queue_free)
	queue_free()
