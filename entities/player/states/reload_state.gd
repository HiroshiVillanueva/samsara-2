extends State

var reload_timer: float = 0.0
var reload_tween: Tween

# --- Active Reload Variables ---
var sweet_spot_start: float = 0.0
var sweet_spot_window: float = 0.15 # Represents 15% of the total reload time
var is_active_reload_used: bool = false

func enter():
	reload_timer = player.reload_time
	is_active_reload_used = false
	
	# Randomize the sweet spot to appear somewhere between 20% and 75% of the bar
	sweet_spot_start = randf_range(0.2, 0.4)
	
	# USE THE NEW FUNCTION IN PLAYER_CORE.GD
	player.start_active_reload_ui(player.reload_time, sweet_spot_start, sweet_spot_window)
	
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
	
	# Calculate progress (from 0.0 to 1.0)
	var progress = 1.0 - (reload_timer / player.reload_time)
	
	# Listen for the second button press (Active Reload trigger)
	if (Input.is_action_just_pressed("reload") or Input.is_action_just_pressed("shoot")) and not is_active_reload_used:
		is_active_reload_used = true
		resolve_reload(progress)
		return # Exit the frame early since we are transitioning states
		
	# If the timer naturally hits 0 and the player never pressed the button
	if reload_timer <= 0 and not is_active_reload_used:
		is_active_reload_used = true
		resolve_reload(-1.0) # Passing a negative value guarantees it misses the sweet spot

func resolve_reload(current_progress: float):
	var sweet_spot_end = sweet_spot_start + sweet_spot_window
	var final_ammo_amount: int = 0
	
	# Check if the player hit the window
	if current_progress >= sweet_spot_start and current_progress <= sweet_spot_end:
		# Perfect Reload!
		final_ammo_amount = player.max_ammo
	else:
		# Imperfect Reload. floori() enforces your "round down" rule automatically.
		final_ammo_amount = floori(player.max_ammo * 0.75)
		
	# Apply ammo and update UI
	player.current_ammo = final_ammo_amount
	player.update_ammo_ui()
	
	# Standardize the exit routing
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0:
		state_machine.transition_to("Move")
	else:
		state_machine.transition_to("Idle")

func exit():
	# Hide the bar when we finish or stopped
	player.reload_bar.hide()
	
	# Stop the bar from filling if we cancel the reload early (like an instant active reload)
	if reload_tween:
		reload_tween.kill()
