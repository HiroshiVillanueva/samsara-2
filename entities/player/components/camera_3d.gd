# CameraShake.gd
extends Camera3D  # Change to Camera2D if you're using 2D

# Trauma system
var trauma: float = 0.0
var trauma_power: float = 2.0     # Higher = more violent at high trauma
var decay: float = 1.2            # How fast trauma fades (higher = faster decay)

# Shake strength
var max_offset: Vector3 = Vector3(0.8, 0.8, 0.0)
var max_roll: float = 0.15        # radians (~8.6 degrees)

# Noise settings
@onready var noise = FastNoiseLite.new()
var noise_speed: float = 8.0

# Store original transform
var initial_position: Vector3
var initial_rotation: Vector3

func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	
	# Noise setup
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.6
	noise.seed = randi()


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		_apply_shake()
	else:
		# Smoothly return to original position/rotation
		position = position.lerp(initial_position, 12.0 * delta)
		rotation = rotation.lerp(initial_rotation, 12.0 * delta)


func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)


func _apply_shake() -> void:
	var amount = pow(trauma, trauma_power)
	var time = Time.get_ticks_msec() / 1000.0 * noise_speed
	
	# Position shake
	position.x = initial_position.x + max_offset.x * amount * noise.get_noise_2d(0, time)
	position.y = initial_position.y + max_offset.y * amount * noise.get_noise_2d(100, time)
	position.z = initial_position.z + max_offset.z * amount * noise.get_noise_2d(200, time)
	
	# Rotation shake (roll)
	rotation.z = initial_rotation.z + max_roll * amount * noise.get_noise_2d(300, time)


# Optional: Convenience functions
func shake_light() -> void:
	add_trauma(0.35)

func shake_medium() -> void:
	add_trauma(0.65)

func shake_heavy() -> void:
	add_trauma(1.0)
