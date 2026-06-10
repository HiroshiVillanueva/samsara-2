extends CharacterBody3D # Gave up halfway and had Gemini finish the comments

enum FireMode { SEMI_AUTO, AUTOMATIC, BURST }
enum MuzzleType {
	PRECISION, ## Value 1
	WIDE ## Value 2
	}
enum Status { BASIC, BRAND, BLIGHT }
enum ShootType { RAYCAST, PROJECTILE }

@export_group("Player Stats")
@export var max_health: int = 100:
	set(value):
		max_health = value
		# is_node_ready() prevents crashes when the game first boots up
		if is_node_ready():
			health_bar.max_value = max_health
			health_bar.value = clamp(current_health, 0, max_health)
			health_label.text = str(current_health)
var current_health: int = 100
@export var armor: int = 0
@export var hurt_shake_decay: float = 0.55

@export_group("Combat Settings")
@export var is_weapon_drawn: bool = false : set = update_weapon_mode
@export var weapon_colors: Array[Color] = []
# When a scene changes this boolean, it automatically runs the update_weapon_mode function

@export_group("Movement Settings")
@export var speed: float = 23.4
@export var acceleration: float = 15.0
@export var runAnimationSpeed: float = 1.43
@export_range(0.5, 2.0) var speedMultiplier: float = 1.0

@export_group("Dash Settings")
@export var dash_speed: float = 100.0
@export var dash_duration: float = 0.1
@export var max_dash_charges: int = 1:
	set(value):
		max_dash_charges = value
		if is_node_ready():
			setup_dash_ui() # Instantly adds/removes squares!
			
@export var dash_recharge_time: float = 0.8 # Time to regain 1 charge
@export var dash_buff: Status = Status.BASIC

@export_group("Melee Settings")
@export var melee_duration: float = 0.7 # How long the whole attack takes
@export var melee_dash_speed: float = 38.0 # High speed for the burst
@export var melee_dash_duration: float = 0.09 # Very short duration (e.g., 6 frames)
@export var base_damage: int = 15.0
@export var knockback_force: float = 20.0
@export var crit_chance: float = 0.15 # 15% chance
@export var crit_multiplier: float = 2.0
@export_range(0.0, 1.0) var melee_shake_intensity: float = 0.45

@export_group("Ammo Settings")
@export var max_ammo: int = 20:
	set(value):
		max_ammo = value
		if current_ammo > max_ammo:
			current_ammo = max_ammo	
		if is_node_ready():
			update_ammo_ui()
@export var infinite_ammo: bool = false
@export var reload_time: float = 1.0
@export var ammo_type: String = "Standard" 

var current_ammo: int = 30

@export_group("Range Settings")
@export var fire_mode: FireMode = FireMode.SEMI_AUTO
@export var shoot_type: ShootType = ShootType.RAYCAST
@export var weapon_buff: Status = Status.BASIC
## Location and placement for the origin of the attack.
@export var muzzleType: MuzzleType = MuzzleType.PRECISION
@export_range(1, 9, 2) var projectiles_per_shot: int = 1
@export_range(0.0, 180.0) var spread_angle_degrees: float = 45.0
## Speed of the interv
@export var fire_rate: float = 0.15
@export var action_lock_duration: float = 0.25
@export var gun_crit_chance: float = 0.15
@export var gun_crit_multiplier: float = 2.0
@export var gun_knockback: float = 20.0

@export_subgroup("VFX Settings")
@export_range(0.0, 1.0) var range_shake_intensity: float = 0.15
@export var impact_scene: PackedScene
#@export var tracer_scene: PackedScene
@export var tracer_scene: PackedScene = preload("res://VFX/Beams/TracerVFX.tscn")

@export_subgroup("Burst Settings")
@export var burst_count: int = 3
@export var burst_rate: float = 0.08 # Delay between bullets DURING a burst

@export_subgroup("Raycast Settings")
@export var hitscan_damage: int = 10
@export var hitscan_range: float = 15.0


@export_subgroup("Projectile Settings")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 30.0

# Track the current state of charges
var current_dash_charges: int
var dash_recharge_timer: float = 0.0
var anim_suffix: String = "_Weaponless"
var weapon_cooldown: float = 0.0

var knockback_velocity: Vector3 = Vector3.ZERO

# Model Compenents
var camera
@onready var visuals = $Visuals
@onready var anim_tree = $AnimationTree
@onready var area_detection = $AreaDetection
@onready var gun_mesh = $"Visuals/Samsara Rig/Skeleton3D/BoneAttachment3D2/Gun2"
@onready var muzzle = $"Visuals/Samsara Rig/Skeleton3D/Gun/Muzzle"
@onready var knife_mesh = $"Visuals/Samsara Rig/Skeleton3D/Knife "
@onready var melee_hitbox = $"Visuals/Samsara Rig/Skeleton3D/Knife /MeleeHitbox"
@onready var muzzle_flash = $"Visuals/Samsara Rig/Skeleton3D/BoneAttachment3D/MuzzleFlash"
@onready var muzzle_flash2 = $"Visuals/Samsara Rig/Skeleton3D/BoneAttachment3D/MuzzleFlash2"
@onready var anim_state = $AnimationTree.get("parameters/playback")
@onready var health_bar = $CanvasLayer/HealthBar
@onready var health_label = $CanvasLayer/HealthBar/HealthLabel
@onready var reload_bar = $CanvasLayer/ReloadBar
@onready var dash_container = $CanvasLayer/DashContainer

# Dash Effects
@onready var dash_particles1 = $Visuals/Dash_VFX/DashParticles1
@onready var dash_particles2 = $Visuals/Dash_VFX/DashParticles2
@onready var dash_particles3 = $Visuals/Dash_VFX/DashParticles3

# Melee Effects
@onready var slash_particles1 = $Visuals/Melee_VFX/SlashParticle1
@onready var slash_particles2 = $Visuals/Melee_VFX/SlashParticle2
@onready var slash_particles3 = $Visuals/Melee_VFX/SlashParticle3

@onready var ammo_label = $CanvasLayer/AmmoLabel


@onready var grenade_ability = $GrenadeAbility
@export_group("Abilities")
@export var has_grenade_unlocked: bool = true

func _ready():
	anim_tree.active = true
	
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = str(current_health)
	
	# --- Setup Reload ---
	reload_bar.max_value = reload_time
	reload_bar.value = 0 # Starts empty/hidden
	reload_bar.hide()
	
	setup_dash_ui()
	
	# Start the game with full dashes
	current_dash_charges = max_dash_charges
	current_ammo = max_ammo
	update_ammo_ui()

func _physics_process(delta):
	if weapon_cooldown > 0:
		weapon_cooldown -= delta
	
	if muzzleType == MuzzleType.PRECISION:
		muzzle.position.z = 5.69
		muzzle_flash.scale = Vector3(2.0, 2.0, 2.0)
		muzzle_flash2.scale = Vector3(2.0, 2.0, 2.0)
	elif muzzleType == MuzzleType.WIDE:
		muzzle.position.z = 3.5
		muzzle_flash.scale = Vector3(0.6, 2.8, 2.0)
		muzzle_flash2.scale = Vector3(0.6, 2.8, 2.0)
	
	# If we are missing charges, start counting up
	if current_dash_charges < max_dash_charges:
		# 2. TICK THE TIMER UP
		dash_container.show()
		dash_recharge_timer += delta
		# 3. Calculate the percentage (from 0.0 to 1.0)
		var progress_percentage = dash_recharge_timer / dash_recharge_time
		# 4. SEND THE UPDATE TO THE UI IMMEDIATELY
		update_dash_ui(progress_percentage)
		# 5. If the timer finishes a full dash...
		if dash_recharge_timer >= dash_recharge_time:
			current_dash_charges += 1  # Give back 1 charge
			dash_recharge_timer = 0.0  # Reset the stopwatch for the next missing dash
			# Safety check: If we are fully maxed out, snap the UI to perfect 1.0s
			if current_dash_charges == max_dash_charges:
				update_dash_ui(0.0)
	else:
		dash_container.hide()

	if knockback_velocity != Vector3.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 50.0 * delta)

func update_ammo_ui():
	if infinite_ammo:
		ammo_label.text = "AMMO: ∞ / ∞"
	else:
		# Create the numbers
		var text = "AMMO: " + str(current_ammo) + " / " + str(max_ammo)
		# This will draw a line of vertical bars representing your exact ammo count.
		var bullet_visual = "|".repeat(current_ammo)
		
		ammo_label.text = text + "\n" + bullet_visual

func update_weapon_mode(value: bool):
	is_weapon_drawn = value
	if is_weapon_drawn:
		anim_suffix = "_Weaponed"
	else:
		anim_suffix = "_Weaponless"
		
	# NEW: Recalculate visibility immediately when the mode changes
	update_mesh_visibility()
	
	var state_machine = $StateMachine 
	if state_machine and state_machine.current_state:
		state_machine.current_state.enter()
		
func update_mesh_visibility(is_dashing: bool = false, is_meleeing: bool = false):
	# Rule 1: Dash overrides EVERYTHING. Hide all.
	if is_dashing:
		gun_mesh.hide()
		knife_mesh.hide()
		return
		
	# Rule 2: Melee overrides normal weapon state. Show knife, hide gun.
	if is_meleeing:
		gun_mesh.hide()
		knife_mesh.show()
		return
		
	# Rule 3: Normal idle/moving rules
	knife_mesh.hide() # Knife is always hidden unless meleeing
	if is_weapon_drawn:
		gun_mesh.show()
	else:
		gun_mesh.hide()

func restore_weapons_after_delay(delay_time: float):
	# Wait for the specified time
	await get_tree().create_timer(delay_time).timeout
	# Makes sure the gun doesnt show up again during chained attacks
	var current_state = $StateMachine.current_state.name
	if current_state != "Dash" and current_state != "Melee":
		update_mesh_visibility()

func aim_at_mouse():
	camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var floor_plane = Plane(Vector3.UP, global_position.y)
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var intersection = floor_plane.intersects_ray(ray_origin, ray_dir)
	
	if intersection != null and global_position.distance_to(intersection) > 0.1:
		var dir_to_mouse = intersection - global_position
		var attack_point = global_position - dir_to_mouse
		visuals.look_at(attack_point, Vector3.UP)
		visuals.rotation.x = 0
		visuals.rotation.z = 0
		return intersection

func take_damage(hit_data: Dictionary):
	if camera.has_method("add_trauma"):
		camera.add_trauma(hurt_shake_decay)
	
	var incoming_damage = hit_data.get("damage", 0.0)
	if hit_data.has("crit_chance"):
		var c_chance = hit_data.get("crit_chance", 0.0)
		var c_mult = hit_data.get("crit_mult", 1.0)
		
		var is_crit = randf() <= c_chance
		if is_crit:
			incoming_damage *= c_mult
	#if hit_data.has("knockback"):
	var knockback_vector = hit_data.get("knockback", Vector3.ZERO)
	
	var final_damage = max(1.0, incoming_damage - armor)
	
	current_health -= final_damage
	current_health = clamp(current_health, 0, max_health)
	health_label.text = str(current_health)
	
	if has_node("InventoryManager"):
		var inv = get_node("InventoryManager")
		inv.trigger_durability(ItemData.DurabilityTrigger.ON_TAKE_DAMAGE, 1)
	
	# Animate the health bar shrinking using a Tween!
	var tween = get_tree().create_tween()
	if self.is_in_group("Player"):
		tween.tween_property(health_bar, "value", current_health, 0.2).set_trans(Tween.TRANS_SINE)
	
	if current_health <= 0:
		print("Player Died!") # Handle death later
	
	#if has_method("apply_knockback") and knockback_vector != Vector3.ZERO:
		#apply_knockback(knockback_vector)

#func apply_knockback(force_vector: Vector3):
	## Add the explosion force to this character
	#knockback_velocity += force_vector

func setup_dash_ui():
	for child in dash_container.get_children():
		child.queue_free()
		
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8) 
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_bottom_right = 10
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color("e0dfe6ff") 
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_bottom_right = 10
		
	for i in range(max_dash_charges):
		var new_bar = ProgressBar.new()
		new_bar.custom_minimum_size = Vector2(32, 4) 
		new_bar.show_percentage = false
		new_bar.max_value = 1.0
		
		# --- THE MAGIC FIX ---
		# Setting step to 0.0 allows it to draw smooth decimals like 0.45!
		new_bar.step = 0.0 
		
		new_bar.value = 1.0 
		
		new_bar.add_theme_stylebox_override("background", bg_style)
		new_bar.add_theme_stylebox_override("fill", fill_style)
		
		dash_container.add_child(new_bar)


func update_dash_ui(recharge_progress: float = 0.0):
	# Loop through every bar in the container
	for i in range(dash_container.get_child_count()):
		var bar = dash_container.get_child(i)
		
		if i < current_dash_charges:
			# If this bar's index is LESS than our current charges, it's fully ready!
			bar.value = 1.0 
		elif i == current_dash_charges:
			# If this bar's index MATCHES our current charges, this is the one actively filling!
			bar.value = recharge_progress 
		else:
			# Any bar higher than that is totally empty and waiting its turn.
			bar.value = 0.0

# --- ADD THIS TO player.gd ---

func _unhandled_input(event: InputEvent):
	# event.is_action_pressed is highly optimized for single clicks
	if event.is_action_pressed("throw_grenade"):
		if has_grenade_unlocked:
			
			if grenade_ability.current_cooldown <= 0:
				get_node("InventoryManager").trigger_durability(ItemData.DurabilityTrigger.ON_THROW_GRENADE, 1)
				var target_pos = aim_at_mouse()
			
				# 2. Tell the component to do its job!
				# (Assuming your muzzle/hand is where you want it to spawn from)
				var spawn_pos = global_position + Vector3(0, 5.3, 0) # Just an example offset so it doesn't spawn in your feet
				var success = grenade_ability.try_throw(spawn_pos, target_pos)
					
				if success:
					print("Grenade thrown successfully!")
					# If you have an AnimationTree with an upper-body Additive Blend,
					# you could trigger a quick arm toss animation right here!
