extends State

func enter():
	# Determines the animation set used depending on the level or weapon
	var anim_name = "Idle" + player.anim_suffix
	player.anim_state.travel(anim_name)
	player.velocity = Vector3.ZERO

func physics_update(_delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() > 0:
		state_machine.transition_to("Move")
		
	if Input.is_action_just_pressed("dash") and player.current_dash_charges > 0:
		state_machine.transition_to("Dash")
		
	if Input.is_action_just_pressed("melee") and player.is_weapon_drawn:
		state_machine.transition_to("Melee")
		return # Not sure why this is here but it works.
		# update: wrote this in february, I don't remember anymore now.
	
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
