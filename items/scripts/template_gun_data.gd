extends ItemData #TEMPORARY
class_name GunItemData #TEMPLATE FOR GUNS

enum FireMode { SEMI_AUTO, AUTOMATIC, BURST }
enum MuzzleType {
	PRECISION, ## Longer muzzle fash.
	WIDE ## shorter but sider muzzle flash.
	}
enum Status { BASIC, BRAND, BLIGHT }
enum ShootType { RAYCAST, PROJECTILE }

func _init():
	category = Category.GUN
	
@export_category("Active Reload Specs")
## How wide the "perfect" window is (e.g., 0.15 means 15% of the total reload time)
@export var sweet_spot_window: float = 0.15
## How many extra projectiles you get for hitting the active reload
@export var active_reload_bonus_projectiles: int = 1

@export_group("Ammo Settings")
@export var bonus_max_ammo: int = 0 ## Default is 100
@export var bonus_max_ammo_bool: bool = false ## Default is 100

@export var bonus_infinite_ammo: bool = false ## Default is false
@export var bonus_infinite_ammo_bool: bool = false ## Default is false

@export var bonus_reload_time: float = 0 ## Default is 1.2
@export var bonus_reload_time_bool: bool = false ## Default is 1.2

@export var reload_sweet_spot_window: float = 0.0 ## Default is 0.15
@export var reload_sweet_spot_window_bool: bool = false ## Default is 0.15

@export var bonus_ammo_type: String = "Standard" ## Default is "Standard"
@export var bonus_ammo_type_bool: bool = false ## Default is "Standard"

@export_group("Range Settings")
@export_range(0.0, 1.0) var range_shake_intensity: float = 0.0 ## Default is 0.15
@export var range_shake_intensity_bool: bool = false ## Default is 0.15

@export var bonus_fire_mode: FireMode = FireMode.SEMI_AUTO ## Default is "Semi Auto"
@export var bonus_fire_mode_bool: bool = false ## Default is "Semi Auto"

@export var bonus_shoot_type: ShootType = ShootType.RAYCAST ## Default is Raycast
@export var bonus_shoot_type_bool: bool = false ## Default is Raycast

@export var bonus_weapon_buff: Status = Status.BASIC ## Default is "Basic"
@export var bonus_weapon_buff_bool: bool = false ## Default is "Basic"

@export var bonus_muzzleType: MuzzleType = MuzzleType.PRECISION ## Default is "Precision"
@export var bonus_muzzleType_bool: bool = false ## Default is "Precision"

@export_range(1, 9, 2) var bonus_projectiles_per_shot: int = 0 ## Default is 1
@export var bonus_projectiles_per_shot_bool: bool = false ## Default is 1

@export_range(-180.0, 180.0) var bonus_spread_angle_degrees: float = 0 ## Default is 45.0
@export var bonus_spread_angle_degrees_bool: bool = false ## Default is 45.0

@export var bonus_fire_rate: float = 0 ## Default is 0.2 (Higher is Slower, Lower is Faster)
@export var bonus_fire_rate_bool: bool = false ## Default is 0.2 (Higher is Slower, Lower is Faster)

@export var bonus_gun_crit_chance: float = 0 ## Default is 0.15
@export var bonus_gun_crit_chance_bool: bool = false ## Default is 0.15

@export var bonus_gun_crit_multiplier: float = 0 ## Default is 2.0
@export var bonus_gun_crit_multiplier_bool: bool = false ## Default is 2.0

@export var bonus_gun_knockback: float = 0 ## Default is 20.0
@export var bonus_gun_knockback_bool: bool = false ## Default is 20.0

@export_subgroup("Burst Settings")
@export var bonus_burst_count: int = 0 ## Default is 3
@export var bonus_burst_count_bool: bool = false ## Default is 3

@export var bonus_burst_rate: float = 0 ## Default is 0.08 (Higher is slower, Lower is faster)
@export var bonus_burst_rate_bool: bool = false ## Default is 0.08 (Higher is slower, Lower is faster)

@export_subgroup("Raycast Settings")
@export var bonus_hitscan_damage: int = 0 ## Default is 10
@export var bonus_hitscan_damage_bool: bool = false ## Default is 10

@export var bonus_hitscan_range: float = 0 ## Default is 15.0
@export var bonus_hitscan_range_bool: bool = false ## Default is 15.0
