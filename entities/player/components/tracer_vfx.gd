extends Node3D 
# HOLY SHIT THIS TOOK ME 5 DAYS, I DON'T UNDERSTAND A SINGLE THING AT ALL.
# HALF OF THIS IS STOLEN, THE OTHER IS AI 

@export var fake_speed: float = 85.0 
@export var trail_linger_time: float = 0.4 
@export var spawn_offset: float = 1.0

@onready var mesh_instance = $MeshInstance3D

# --- WE NOW GRAB BOTH THE PIVOT AND THE MESH ---
@onready var trail_pivot = $TrailPivot
@onready var trail_mesh = $TrailPivot/TrailMesh 
@onready var trail_mesh2 = $TrailPivot/TrailMesh2
@onready var trail_mesh3 = $TrailPivot/TrailMesh3

func setup_tracer(start_pos: Vector3, end_pos: Vector3):
	global_position = start_pos
	look_at(end_pos, Vector3.UP)
	
	# Lay the meshes flat so the Quad faces the right way
	trail_mesh.rotation_degrees = Vector3(0, 90, 0)
	trail_mesh2.rotation_degrees = Vector3(0, 90, 0)
	trail_mesh3.rotation_degrees = Vector3(0, 90, 0)
	
	var distance = start_pos.distance_to(end_pos)
	var safe_offset = min(spawn_offset, distance * 0.5)
	var travel_distance = distance - safe_offset
	var travel_time = distance / fake_speed
	var trail_length = distance * 0.8
	var gap = (distance * 0.95) - trail_length
	
	
	# 1. Setup the flying bullet
	var base_bullet_length = 2.0 
	mesh_instance.scale.z = min(base_bullet_length, travel_distance)
	mesh_instance.position.z = -safe_offset
	mesh_instance.show()
	
	# 2. Setup the Stretched Trail (USING THE PIVOT!)
	# We scale the PIVOT to the distance, not the mesh!
	trail_pivot.scale.z = trail_length
	trail_pivot.position.z = -gap
	
	trail_mesh.scale.x = 0.5 
	trail_mesh.scale.y = 0.5
	trail_mesh.show()
	
	trail_mesh2.scale.x = 0.5 
	trail_mesh2.scale.y = 0.5
	trail_mesh2.show()
	
	trail_mesh3.scale.x = 0.5 
	trail_mesh3.scale.y = 0.5
	trail_mesh3.show()
	
	var trail_mat = trail_mesh.get_active_material(0).duplicate()
	trail_mesh.material_override = trail_mat
	var trail_mat2 = trail_mesh2.get_active_material(0).duplicate()
	trail_mesh2.material_override = trail_mat2
	var trail_mat3 = trail_mesh3.get_active_material(0).duplicate()
	trail_mesh3.material_override = trail_mat3
	
	# --- 3. THE BULLET TWEEN ---
	var bullet_tween = get_tree().create_tween()
	bullet_tween.tween_property(mesh_instance, "position:z", -distance, travel_time)
	bullet_tween.tween_callback(mesh_instance.hide) 
	
	# --- 4. THE TRAIL TWEEN ---
	var trail_tween = get_tree().create_tween()
	trail_tween.set_parallel(true) 
	var trail_tween2 = get_tree().create_tween()
	trail_tween2.set_parallel(true) 
	var trail_tween3 = get_tree().create_tween()
	trail_tween2.set_parallel(true) 
	
	# 1. Fade the color and shrink the width normally
	trail_tween.tween_property(trail_mat, "shader_parameter/master_alpha", 0.0, trail_linger_time * 0.05) 
	trail_tween.tween_property(trail_mesh, "scale:x", 0.0, trail_linger_time)
	trail_tween.tween_property(trail_mesh, "scale:y", 0.0, trail_linger_time)
	
	trail_tween2.tween_property(trail_mat2, "shader_parameter/master_alpha", 0.0, trail_linger_time * 0.10) 
	trail_tween2.tween_property(trail_mesh2, "scale:x", 0.0, trail_linger_time)
	trail_tween2.tween_property(trail_mesh2, "scale:y", 0.0, trail_linger_time)
	
	trail_tween3.tween_property(trail_mat3, "shader_parameter/master_alpha", 0.0, trail_linger_time * 0.05) 
	trail_tween3.tween_property(trail_mesh3, "scale:x", 0.0, trail_linger_time)
	trail_tween3.tween_property(trail_mesh3, "scale:y", 0.0, trail_linger_time)
	
	# 2. THE UPGRADE: Slower, less intense retraction!
	# We multiply the linger time by 1.5 so the retraction takes 50% longer than the fade
	var retract_time = trail_linger_time * 1.5
	
	# We add a Sine curve and Ease Out to make it smoothly decelerate to a stop
	trail_tween.tween_property(trail_pivot, "position:z", -distance, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	trail_tween.tween_property(trail_pivot, "scale:z", 0.0, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	trail_tween.set_parallel(false)
	trail_tween.tween_callback(queue_free)
	
	trail_tween2.tween_property(trail_pivot, "position:z", -distance, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	trail_tween2.tween_property(trail_pivot, "scale:z", 0.0, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	trail_tween2.set_parallel(false)
	trail_tween2.tween_callback(queue_free)
	
	trail_tween3.tween_property(trail_pivot, "position:z", -distance, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	trail_tween3.tween_property(trail_pivot, "scale:z", 0.0, retract_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	trail_tween3.set_parallel(false)
	trail_tween3.tween_callback(queue_free)
