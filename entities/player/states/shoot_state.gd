extends State # Gave up halfway and had Gemini finish the comments

#var fire_timer: float = 0.0
var shots_fired_in_burst: int = 0
var action_lock_timer: float = 0.0
var is_bursting: bool = false
var burst_timer: float = 0.0
var color: Color 

func enter():
	# Stop moving, make sure the gun is visible
	player.velocity = Vector3.ZERO 
	player.update_mesh_visibility(false, false)
	
	if player.weapon_buff == player.Status.BASIC:
		color = player.weapon_colors[0]
	elif player.weapon_buff == player.Status.BRAND:
		color = player.weapon_colors[1]
	if player.weapon_buff == player.Status.BLIGHT:
		color = player.weapon_colors[2]
	
	# Reset burst trackers and immediately fire the first shot
	is_bursting = false
	shots_fired_in_burst = 0
	player.aim_at_mouse()
	var camera = get_viewport().get_camera_3d()
	if camera.has_method("add_trauma"):
		camera.add_trauma(player.range_shake_intensity)
	fire_shot()
	
	player.muzzle_flash.primary_color = color
	player.muzzle_flash.secondary_color = color
		
	if player.weapon_cooldown <= 0:
		fire_shot()
	
func physics_update(delta: float):
	if Input.is_action_pressed("shoot"):
		player.aim_at_mouse()
	
	# --- 1. COUNT DOWN TIMERS ---
	#if fire_timer > 0:
		#fire_timer -= delta
	if action_lock_timer > 0:
		action_lock_timer -= delta
	
	# --- 2. BURST FIRE OVERRIDE ---
	if is_bursting:
		burst_timer -= delta
		if burst_timer <= 0:
			fire_shot()
		return
		
	# --- 3. INPUT CHECK ---
	var want_to_shoot = false
	if player.fire_mode == player.FireMode.AUTOMATIC:
		want_to_shoot = Input.is_action_pressed("shoot")
	else:
		want_to_shoot = Input.is_action_just_pressed("shoot")	
		
	# FIX: Check for trigger release globally, regardless of current fire mode
	if Input.is_action_just_released("shoot"):
		if player.muzzle_flash and player.muzzle_flash2:
			player.muzzle_flash.stop()
			player.muzzle_flash2.stop()
			
	if want_to_shoot and player.weapon_cooldown <= 0:
		if player.current_ammo > 0 or player.infinite_ammo:
			fire_shot()
		else:
			player.muzzle_flash.stop()
			player.muzzle_flash2.stop()
			state_machine.transition_to("Reload")
			return
		
	# --- 4. NEW EXIT LOGIC ---
	# We can only leave the state if the player isn't trying to shoot AND the lock is done!
	if not want_to_shoot and action_lock_timer <= 0:
		# Allow movement again
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0:
			player.muzzle_flash.stop()
			player.muzzle_flash2.stop()
			state_machine.transition_to("Move")
		else:
			player.muzzle_flash.stop()
			player.muzzle_flash2.stop()
			state_machine.transition_to("Idle")

func fire_shot():	
	if not player.infinite_ammo:
		# Failsafe: If a Burst Fire tries to shoot an empty gun, abort the burst!
		if player.current_ammo <= 0:
			is_bursting = false
			return
			
		player.current_ammo -= 1
		player.update_ammo_ui()
		
	if player.muzzle_flash and player.muzzle_flash2:
		player.muzzle_flash.play()
		player.muzzle_flash2.play()
		if player.fire_mode != player.FireMode.AUTOMATIC:
			stop_vfx_after_delay(0.15)
			
			
	action_lock_timer = player.action_lock_duration
	# --- 1. ANIMATION LOGIC ---
	if player.fire_mode == player.FireMode.BURST:
		# Only play the burst animation on the VERY FIRST bullet of the sequence!
		if shots_fired_in_burst == 0:
			var anim_name = "Burst"
			player.anim_state.start(anim_name)
	else:
		# Play the regular shoot animation for Semi-Auto and Automatic
		var anim_name = "Single"
		player.anim_state.start(anim_name)
	
	# --- 2. EXECUTE THE ATTACK ---
	var count = player.projectiles_per_shot
	# Get the true forward direction of the player
	var base_forward = -player.visuals.global_transform.basis.z.normalized()
	
	if count == 1:
		# Just shoot straight!
		execute_attack(base_forward)
	else:
		# Convert degrees to radians (Godot does math in radians)
		var spread_rads = deg_to_rad(player.spread_angle_degrees)
		
		# Find the starting angle (the far left of the arc)
		var start_angle = -spread_rads / 2.0
		# Find out how much space goes between each bullet
		var angle_step = spread_rads / (count - 1)
		
		# Loop through the bullets and fire them all!
		for i in range(count):
			var current_angle = start_angle + (i * angle_step)
			
			# Rotate the true forward vector around the Y-axis (Up/Down) 
			var arc_direction = base_forward.rotated(Vector3.UP, current_angle)
			
			execute_attack(arc_direction)
	
	#if player.shoot_type == player.ShootType.RAYCAST:
		#perform_raycast()
	#else:
		#spawn_projectile()
		
	# --- 3. HANDLE TIMERS & BURST STATE ---
	if player.fire_mode == player.FireMode.BURST:
		shots_fired_in_burst += 1
		if shots_fired_in_burst < player.burst_count:
			is_bursting = true
			burst_timer = player.burst_rate
		else:
			is_bursting = false
			shots_fired_in_burst = 0
			# Set the global cooldown after the burst finishes!
			player.weapon_cooldown = player.fire_rate 
	else:
		# Set the global cooldown for semi-auto and auto!
		player.weapon_cooldown = player.fire_rate

func execute_attack(direction: Vector3):
	player.get_node("InventoryManager").trigger_durability(ItemData.DurabilityTrigger.ON_SHOOT, 1)
	
	if player.shoot_type == player.ShootType.RAYCAST:
		perform_raycast(direction)
	else:
		spawn_projectile(direction)

func stop_vfx_after_delay(delay: float):
	await get_tree().create_timer(delay).timeout
	if player.muzzle_flash and player.muzzle_flash2:
		player.muzzle_flash.stop()
		player.muzzle_flash2.stop()

# --- MECHANICS ---

func perform_raycast(fire_dir: Vector3):
	var space_state = player.get_world_3d().direct_space_state
	var start_pos = player.muzzle.global_position
	
	#var forward_dir = player.visuals.global_transform.basis.z.normalized()
	var end_pos = start_pos + (-fire_dir * player.hitscan_range)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [player] # Don't shoot yourself
	query.collision_mask = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) # Hit Layers 3, 4, 5, 6
	
	var result = space_state.intersect_ray(query)
	var hit_position = end_pos # Default to max range if we hit nothing
	
	var hit_data = {
			"damage": player.hitscan_damage,
			"crit_chance": player.gun_crit_chance,
			"crit_mult": player.gun_crit_multiplier,
			"buff": player.weapon_buff,
			"knockback": player.global_transform.basis.z * player.gun_knockback
	}
	
	if result:
		print("Raycast Hit: ", result.collider.name)
		
		# FIX 2: We MUST update the hit_position to the exact wall impact point!
		hit_position = result.position	
		# Later, you can do: 
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(hit_data)
		
		if player.impact_scene:
			var impact = player.impact_scene.instantiate()
			player.get_tree().root.add_child(impact)
			impact.primary_color = color
			impact.secondary_color = color
			impact.light_color = color
			impact.global_position = result.position
			
			# Make the sparks bounce AWAY from the wall using the collision normal
			var look_target = result.position + result.normal
			
			# Failsafe: only look_at if the target isn't perfectly identical to the position
			if not impact.global_position.is_equal_approx(look_target):
				# Use Vector3.UP for walls, but if hitting the floor, use Vector3.RIGHT to avoid math errors
				var up_dir = Vector3.UP if abs(result.normal.y) < 0.99 else Vector3.RIGHT
				impact.look_at(look_target, up_dir)
				
	# 3. SPAWN TRACER VFX
	if player.tracer_scene:
		var tracer = player.tracer_scene.instantiate()
		player.get_tree().root.add_child(tracer)
		var trail_node = tracer.get_node("TrailPivot/TrailMesh")
		var particle_material = trail_node.get_active_material(0)
		var vfx_node = tracer.get_node("MeshInstance3D") 
		
		vfx_node.secondary_color = color # Set your secondary color here
		vfx_node.tertiary_color = color		
		vfx_node.light_color = color
		particle_material.set_shader_parameter("color2", color)
		
		# Call our custom function and pass the color variable!
		if tracer.has_method("setup_tracer"):
			tracer.setup_tracer(start_pos, hit_position)

func spawn_projectile(fire_dir: Vector3):
	if player.projectile_scene == null:
		printerr("No projectile scene assigned in Player Inspector!")
		return
		
	var proj = player.projectile_scene.instantiate()
	player.get_tree().root.add_child(proj)
	
	# Snap the bullet to the muzzle's position and rotation
	proj.global_transform = player.muzzle.global_transform
	
	var target_pos = player.muzzle.global_position + fire_dir
	proj.look_at(target_pos, Vector3.UP)
	
	# *Note: Your bullet scene will need a basic script attached to it 
	# that moves it forward using the player.projectile_speed!*

func exit() -> void:
	player.muzzle_flash.stop()
	player.muzzle_flash2.stop()
