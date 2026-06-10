extends Node3D

## Allows the player to use weapons within the level / environment.
@export var allows_weapons: bool = true

## Distance of camera relative to the player. 35 = default.
@export var camera_settings: int = 35

func _ready():
	#some weird shit thats in every level, we add more stuff to this as we add more features in a level.
	call_deferred("_setup_player_weapons")
	call_deferred("_setup_camera", camera_settings)

func _setup_player_weapons():
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player.is_weapon_drawn = allows_weapons
	else:
		printerr("ERROR: add player in your scene!1")
		
func _setup_camera(setting: int):
	var camera = get_viewport().get_camera_3d()
	camera.size = setting
