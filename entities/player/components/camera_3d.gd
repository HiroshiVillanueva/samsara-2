extends Camera3D
#found this camera function online so I can't help you here.

@export_category("Camera Shake")
## Rate at which the shake dissipates.
@export var decay: float = 0.8  
## The level of displacement both in X and Y upon camera shake.
@export var max_offset: Vector2 = Vector2(0.5, 0.5)  
## The level of displacement in the z axis(?) both in the positive and negative distance upon camera shake.
@export var max_roll: float = 0.1  

var trauma: float = 0.0  
var trauma_power: int = 2  
var noise = FastNoiseLite.new()
var noise_speed: float = 50.0 

# Grabs the original position of the camera
var initial_position: Vector3
var initial_rotation: Vector3

func _ready():
	noise.seed = randi()
	noise.frequency = 0.5
	
	# Save the exact spot and angle the camera starts at
	initial_position = position
	initial_rotation = rotation

func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		shake()
	else:
		# Reset position of camera to orginal before shake
		position = initial_position
		rotation = initial_rotation

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	var time = Time.get_ticks_msec() / 1000.0 * noise_speed
	position.x = initial_position.x + max_offset.x * amount * noise.get_noise_2d(0, time)
	position.y = initial_position.y + max_offset.y * amount * noise.get_noise_2d(100, time)
	rotation.z = initial_rotation.z + max_roll * amount * noise.get_noise_2d(200, time)
