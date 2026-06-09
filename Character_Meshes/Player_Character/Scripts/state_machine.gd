extends Node

@export var initial_state: State
@onready var current_state: State = initial_state

func _ready():
	# Wait for the player to be ready, then start
	await owner.ready
	
	# Only enter the starting state, ignore the rest!
	current_state.enter()

func _physics_process(delta):
	current_state.physics_update(delta)

func transition_to(target_state_name: String):
	if not has_node(target_state_name):
		return

	current_state.exit()
	current_state = get_node(target_state_name)
	current_state.enter()
