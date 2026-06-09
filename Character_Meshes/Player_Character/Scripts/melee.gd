extends State

var state_timer: float = 0.0
var dash_timer: float = 0.0
var knife_sheathed: bool

func enter():
	# Update visibility
	knife_sheathed = false # Reset the status of the knife (security reasons)
	player.update_mesh_visibility(false, true) # Show knife
	
	# Play Animation
	player.slash_particles1.restart()
	player.slash_particles2.restart()
	player.slash_particles3.restart()
	player.anim_state.start("Melee")
	
	player.melee_hitbox.swing_weapon()
	
	player.aim_at_mouse()
	
	# Set our two timers
	state_timer = player.melee_duration
	dash_timer = player.melee_dash_duration
	
	# Determine location of the attack using camera and mouse
	var camera = get_viewport().get_camera_3d()
	var forward_dir = player.visuals.global_transform.basis.z.normalized()
	player.velocity = forward_dir * player.melee_dash_speed
	
	# Apply shake for extra effects :D 
	if camera.has_method("add_trauma"):
		camera.add_trauma(player.melee_shake_intensity)
	

func physics_update(delta: float):
	state_timer -= delta
	
	if dash_timer > 0:
		dash_timer -= delta
		player.move_and_slide()
	else:
		player.velocity = Vector3.ZERO
	
	var dash_cancel_threshold = player.melee_duration * 0.70
	var general_cancel_threshold = player.melee_duration * 0.25
	
	if state_timer <= dash_cancel_threshold:
		if Input.is_action_just_pressed("dash") and player.current_dash_charges > 0:
			state_machine.transition_to("Dash")
			return
			
		if Input.is_action_just_pressed("shoot") and player.is_weapon_drawn:
			state_machine.transition_to("Shoot")
			return
				
	if state_timer <= general_cancel_threshold:
		if Input.is_action_just_pressed("melee") and player.is_weapon_drawn:
			state_machine.transition_to("Melee")
			return
			
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0:
			state_machine.transition_to("Move")
			return
			
	
	var sheathe_threshold = player.melee_duration * 0.1 # When the knife disappears in the whole sequence
	if state_timer <= sheathe_threshold and not knife_sheathed:
		# Tell the player script to return to normal visibility early.
		player.update_mesh_visibility(false, false) 
		knife_sheathed = true
			
	if state_timer <= 0:
		state_machine.transition_to("Idle")

func exit():
	player.update_mesh_visibility()
