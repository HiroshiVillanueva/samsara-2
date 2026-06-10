class_name State
extends Node

# We use 'owner' to access the Player (CharacterBody3D) 
# and 'get_parent()' to access the StateMachine
@onready var player: CharacterBody3D = owner
@onready var state_machine: Node = get_parent()

# Virtual functions (to be overwritten by children)
func enter():
	pass

func exit():
	pass

func handle_input(_event: InputEvent):
	pass

func physics_update(_delta: float):
	pass
