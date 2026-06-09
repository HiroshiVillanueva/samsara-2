extends ItemData
class_name GrenadeItemData #TEMPLATE FOR GRENADES

enum Buffs {SHRAPNEL, SLOWED, COVERED, ATTRACTED}
enum Explosion {ONE, TWO, THREE}

func _init():
	category = Category.GRENADE

@export_group("Ability Settings")
@export var bonus_cooldown_time: float = 3.5
@export var bonus_cooldown_time_bool: bool = false

@export var bonus_travel_time: float = 1.0
@export var bonus_travel_time_bool: bool = false

@export var bonus_max_throw_distance: float = 20.0 
@export var bonus_max_throw_distance_bool: bool = false

@export var bonus_grenade_buff: Buffs = Buffs.SHRAPNEL
@export var bonus_grenade_buff_bool: bool = false

@export var bonus_has_grenade_unlocked: bool = true
@export var bonus_has_grenade_unlocked_bool: bool = false

@export_group("Projectile Stats")
@export var bonus_damage: int = 25
@export var bonus_damage_bool: bool = false

@export var bonus_explosion_radius: float = 7.5
@export var bonus_explosion_radius_bool: bool = false

@export var bonus_knockback_intensity: float = 15.0
@export var bonus_knockback_intensity_bool: bool = false

@export_range(1, 9, 2) var bonus_projectiles_per_throw: int = 1 
@export var bonus_projectiles_per_throw_bool: bool = false

@export_range(0.0, 180.0) var sbonus_pread_angle_degrees: float = 45.0
@export var sbonus_pread_angle_degrees_bool: bool = false

@export var bonus_grenade_type: Explosion = Explosion.ONE
@export var bonus_grenade_type_bool: bool = false
