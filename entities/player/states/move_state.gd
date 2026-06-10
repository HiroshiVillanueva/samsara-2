extends State

func enter():
	# The animation set used is finally scalable :D very happy about this!
	var run_start_name = "Run" + player.anim_suffix + " Start"
	player.anim_state.travel(run_start_name)

func physics_update(delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() == 0:
		# Tell the tree to stop using the correct suffix
		var run_stop_name = "Run" + player.anim_suffix + " Stop"
		player.anim_state.travel(run_stop_name)
		
		state_machine.transition_to("Idle")
		return

	# Movement Logic
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, deg_to_rad(45)).normalized()
	var target_speed = player.speed * player.speedMultiplier
	
	player.velocity.x = lerp(player.velocity.x, direction.x * target_speed, player.acceleration * delta)
	player.velocity.z = lerp(player.velocity.z, direction.z * target_speed, player.acceleration * delta)
	
	# Rotation
	var target_angle = atan2(direction.x, direction.z)
	player.visuals.rotation.y = lerp_angle(player.visuals.rotation.y, target_angle, delta * 25.0)
	
	player.move_and_slide()

	# Animation Speed Scaling
	var horizontal_speed = Vector2(player.velocity.x, player.velocity.z).length()
	#var final_scale = (horizontal_speed / player.speed) * player.runAnimationSpeed
	
	var idle_name = "Idle" + player.anim_suffix
	var run_start_name = "Run" + player.anim_suffix + " Start"
	var run_name = "Run" + player.anim_suffix
	#var timescale_path = "parameters/Run" + player.anim_suffix + "/TimeScale/scale"
	#player.anim_tree.set(timescale_path, final_scale)
	
	if horizontal_speed < 0.5: # 0.5 instead of 0 to allow for sliding effect
		player.anim_state.travel(idle_name)
	else:
		# If we were previously stuck against a wall in the Idle animation, 
		# kickstart the run sequence again.
		var current_anim = player.anim_state.get_current_node()
		if current_anim == idle_name:
			player.anim_state.travel(run_start_name)
		
		# Update the running animation timescale just like before
		var final_scale = (horizontal_speed / player.speed) * player.runAnimationSpeed
		var timescale_path = "parameters/" + run_name + "/TimeScale/scale"
		player.anim_tree.set(timescale_path, final_scale)
	
	# Check for dash input AND if we have charges available
	if Input.is_action_just_pressed("dash") and player.current_dash_charges > 0:
		state_machine.transition_to("Dash")
		
	if Input.is_action_just_pressed("melee") and player.is_weapon_drawn:
		state_machine.transition_to("Melee")
		return # I still don't know how this works! Please don't touch it
		
	# In both idle_state.gd and move_state.gd
	if Input.is_action_just_pressed("shoot") and player.is_weapon_drawn:
		if player.weapon_cooldown <= 0:
			if player.current_ammo > 0 or player.infinite_ammo:
				state_machine.transition_to("Shoot")
			else:
				state_machine.transition_to("Reload")
			return
	
	if Input.is_action_just_pressed("reload") and player.is_weapon_drawn:
		if player.current_ammo < player.max_ammo:
			state_machine.transition_to("Reload")
			return
