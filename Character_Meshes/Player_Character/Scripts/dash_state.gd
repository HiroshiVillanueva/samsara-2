extends State

var timer: float = 0.0
var dash_ignore_mask = (1 << 2) | (1 << 3) | (1 << 5) # Wtf???

# I know this whole process looks inefficient af but we optimize as we go along.
func enter():
	player.collision_mask &= ~dash_ignore_mask

	var mat = player.dash_particles2.draw_pass_1.surface_get_material(0) as ShaderMaterial
	var mat1 = player.dash_particles1.draw_pass_1.surface_get_material(0) as ShaderMaterial
	#var mat2 = player.dash_particles2.draw_pass_1.surface_get_material(1) as ShaderMaterial
	if player.dash_buff == player.Status.BASIC:
		mat.set_shader_parameter("primary_color", player.weapon_colors[0]) 
		mat1.set_shader_parameter("primary_color", Color("046380"))
		#mat2.set_shader_parameter("primary_color", player.weapon_colors[0]) 
	elif player.dash_buff == player.Status.BRAND:
		mat.set_shader_parameter("primary_color", player.weapon_colors[1]) 
		mat1.set_shader_parameter("primary_color", Color("9f1160"))
		#mat2.set_shader_parameter("primary_color", player.weapon_colors[1]) 
	if player.dash_buff == player.Status.BLIGHT:
		mat.set_shader_parameter("primary_color", player.weapon_colors[2]) 
		mat1.set_shader_parameter("primary_color", Color("41661e"))
		#mat2.set_shader_parameter("primary_color", player.weapon_colors[2]) 
	
	#player.dash_particles2.set_shader_parameter("tint_color", player.weapon_colors[2])
	
	# Set all necessary Visual Changes
	player.update_mesh_visibility(true)
	player.dash_particles1.restart()
	player.dash_particles2.restart()
	player.dash_particles3.restart()
	
	# Consume charge
	player.current_dash_charges -= 1
	
	# Start the background stopwatch ONLY if this is the first missing dash
	if player.current_dash_charges == player.max_dash_charges - 1:
		player.dash_recharge_timer = 0.0 
	
	player.get_node("InventoryManager").trigger_durability(ItemData.DurabilityTrigger.ON_DASH, 1)
	
	# Snap the UI so the used square empties instantly
	player.update_dash_ui(0.0)
	print("Dash used! Charges left: ", player.current_dash_charges)
	
	# Reset the dash timer
	timer = player.dash_duration
	
	#  Strt animation
	var dash_anim_name = "Dash" + player.anim_suffix
	player.anim_state.start(dash_anim_name)
	# Apply velocity
	var dash_dir = player.visuals.global_transform.basis.z.normalized()
	player.velocity = dash_dir * player.dash_speed

func physics_update(delta: float):
	timer -= delta
	player.move_and_slide()
	
	if timer <= 0:
		if player.area_detection.has_overlapping_bodies():
			# This organically extends the dash at full speed until they pop out.
			# Pretty smart I know.
			return
		
		# Return to normal logic when the dash is done
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0:
			state_machine.transition_to("Move")
		else:
			state_machine.transition_to("Idle")

func exit():
	# passables
	player.collision_mask |= dash_ignore_mask
	player.restore_weapons_after_delay(0.2)
