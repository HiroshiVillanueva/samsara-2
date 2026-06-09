extends Node3D
#script for allowing the camera to follow the player, we add more stuff to this as we go along.

@export_group("Tracking")
## The focus of the camera and what it tries to follow and keep center.
@export var target: Node3D
## Do I have to explain this? damn, why are you reading this.
@export var follow_speed: float = 8.0 

func _physics_process(delta):
	if target != null:
		# lerp(current_position, target_position, speed_with_delta)
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
