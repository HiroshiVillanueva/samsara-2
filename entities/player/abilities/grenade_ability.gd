extends Node
# Script where we make all other grenade variations and its properties from.
# If you think theres a better class you can make instead, do tell.

enum Buffs {SHRAPNEL, SLOWED, COVERED, ATTRACTED}
enum Explosion {ONE, TWO, THREE}

@export_group("Ability Settings")
@export var grenade_scene: PackedScene
## Default = 3.5 in seconds
@export var cooldown_time: float = 3.5
## Default = 1.0 in seconds
@export var travel_time: float = 1.0
## Default = 20
@export var max_throw_distance: float = 20.0 
## Default = SHRAPNEL since this is buffless.
@export var grenade_buff: Buffs = Buffs.SHRAPNEL

@export_group("Projectile Stats")
## Default = 25
@export var damage: int = 25
## Default = 7.5
@export var explosion_radius: float = 7.5
## Default = 15.00
@export var knockback_intensity: float = 15.0
## Default = 1
@export_range(1, 9, 2) var projectiles_per_throw: int = 1 
## Default = 45.00
@export_range(0.0, 180.0) var spread_angle_degrees: float = 45.0

@export_group("Visuals")
## Same as the others, showcases the buffs that the grenade has.
@export var grenade_colors: Array[Color] = []
## Type of explosion used. Intensity increases with count.
@export var grenade_type: Explosion = Explosion.ONE
## Marker of the area of effect within a grenade.
@export var outline_scene: PackedScene

var current_cooldown: float = 0.0

func _physics_process(delta: float):
	if current_cooldown > 0:
		current_cooldown -= delta

func try_throw(spawn_position: Vector3, target_position: Vector3) -> bool:
	if grenade_scene == null or current_cooldown > 0:
		return false 
		
	# Base Distance Math & Clamping
	var base_displacement = target_position - spawn_position
	if base_displacement.length() > max_throw_distance:
		base_displacement = base_displacement.limit_length(max_throw_distance)
		
	current_cooldown = cooldown_time
	var count = projectiles_per_throw
	
	# Multishot Arc Logic
	if count == 1:
		var final_target = spawn_position + base_displacement
		spawn_single_grenade(spawn_position, final_target)
	else:
		var spread_rads = deg_to_rad(spread_angle_degrees)
		var start_angle = -spread_rads / 2.0
		var angle_step = spread_rads / (count - 1)
		
		for i in range(count):
			var current_angle = start_angle + (i * angle_step)
			var rotated_displacement = base_displacement.rotated(Vector3.UP, current_angle)
			var final_target = spawn_position + rotated_displacement
			spawn_single_grenade(spawn_position, final_target)
			
	return true

func spawn_single_grenade(spawn_pos: Vector3, target_pos: Vector3):
	var grenade = grenade_scene.instantiate()
	grenade.damage = damage
	grenade.explosion_radius = explosion_radius
	grenade.knockback_intensity = knockback_intensity

	#grenade.grenade_buff = grenade_buff 
	#grenade.grenade_type = grenade_type
	#if grenade_colors.size() > 0:
		#grenade.grenade_colors = grenade_colors
	
	get_tree().root.add_child(grenade)
	
	if outline_scene:
		var outline = outline_scene.instantiate()
		
		# Added to root so it stays perfectly still on the ground!
		get_tree().root.add_child(outline) 
		
		var mesh = outline.get_node("BorderOutline")
		mesh.scale.x = explosion_radius * 1.8
		mesh.scale.y = explosion_radius * 1.8
		outline.global_position = target_pos
		
		
		outline.global_position.y += 0.05 # Uses the player as a reference, hence this.
		get_tree().create_timer(travel_time * 1.05).timeout.connect(outline.queue_free) #1.05 so theres a delay in its despawning.

	grenade.throw_at(spawn_pos, target_pos, travel_time)

#var knockback_velocity: Vector3 = Vector3.ZERO
#
#func apply_knockback(force_vector: Vector3):
	## Add the explosion force to this character
	#knockback_velocity += force_vector
#
#func _physics_process(delta: float):
	## ... (Your normal AI or movement code goes here) ...
	#
	## Apply the knockback to the actual movement
	#velocity += knockback_velocity
	#
	## Quickly degrade the knockback over time so they slide to a halt
	#knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 50.0 * delta)
	#
	#move_and_slide()
