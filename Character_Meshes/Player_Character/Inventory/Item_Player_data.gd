extends ItemData #TEMPORARY
class_name PlayerItemData

#enum FireMode { SEMI_AUTO, AUTOMATIC, BURST }
#enum MuzzleType {
	#PRECISION, ## Longer muzzle fash.
	#WIDE ## shorter but sider muzzle flash.
	#}
enum Status { BASIC, BRAND, BLIGHT }
#enum ShootType { RAYCAST, PROJECTILE }

func _init():
	category = Category.GENERAL

@export_group("Dash Settings")
@export var bonus_max_dash_charges: int = 0 ## Default is 1
@export var bonus_max_dash_charges_bool: bool = false ## Default is 1

@export var bonus_dash_recharge_time: float = 0 ## Default is 1.5
@export var bonus_dash_recharge_time_bool: bool = false ## Default is 1.5

@export var bonus_dash_buff: Status = Status.BASIC ## Default is "Basic"
@export var bonus_dash_buff_bool: bool = false ## Default is "Basic"

# Melee is disabled because im unsure if I want to have melee editable.
#@export_group("Melee Settings")
#@export var melee_duration: float = 0.7 # How long the whole attack takes
#@export var melee_dash_speed: float = 38.0 # High speed for the burst
#@export var melee_dash_duration: float = 0.09 # Very short duration (e.g., 6 frames)
#@export var base_damage: int = 15.0
#@export var knockback_force: float = 20.0
#@export var crit_chance: float = 0.15 # 15% chance
#@export var crit_multiplier: float = 2.0
#@export_range(0.0, 1.0) var melee_shake_intensity: float = 0.45
