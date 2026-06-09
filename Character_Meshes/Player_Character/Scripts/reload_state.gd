extends State

var reload_timer: float = 0.0
var reload_tween: Tween

func enter():
	reload_timer = player.reload_time
	
	player.reload_bar.max_value = player.reload_time
	player.reload_bar.value = 0
	player.reload_bar.show()
	
	reload_tween = get_tree().create_tween()
	reload_tween.tween_property(player.reload_bar, "value", player.reload_time, player.reload_time)
	
	var anim_name = "Reload" + player.anim_suffix
	
	# 1. Get the exact length of the raw animation in seconds
	var base_anim_length = 1.4
	
	# 2. Calculate the speed multiplier required to make it fit custom timer
	var speed_multiplier = base_anim_length / player.reload_time
	var scale_path = "parameters/" + anim_name + "/TimeScale/scale"
	
	# 4. Inject the speed multiplier into the TimeScale node
	player.anim_tree.set(scale_path, speed_multiplier * 0.8)
	
	# 5. Start the animation.
	player.anim_state.travel(anim_name)

func physics_update(delta: float):
	# Instantly stop the player
	player.velocity.x = move_toward(player.velocity.x, 0, 10.0)
	player.velocity.z = move_toward(player.velocity.z, 0, 10.0)
	player.move_and_slide()
	
	# Handle the timer
	reload_timer -= delta
	
	if reload_timer <= 0:
		player.current_ammo = player.max_ammo
		player.update_ammo_ui()
		
		# Exit
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0:
			state_machine.transition_to("Move")
		else:
			state_machine.transition_to("Idle")

func exit():
	# Hide the bar when we finish or stopped
	player.reload_bar.hide()
	
	# Stop the bar from filling if we cancel the reload early
	if reload_tween:
		reload_tween.kill()
