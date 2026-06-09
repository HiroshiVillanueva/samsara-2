class_name CursorManager
extends Node

## We add more visuals to this as we go on.
@export_group("Icons")
@export var cursor_normal: Texture2D
@export var cursor_click: Texture2D

## the area of the mouse that actually interacts with the game. 16, 16 is the top right corner. 
@export var hotspot: Vector2 = Vector2(16, 16)

func _ready():
	# Set the default Idle cursor
	_set_standard_cursor(cursor_normal)

	if cursor_click:
		Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_DRAG, hotspot)
		Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_CAN_DROP, hotspot)
		Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_FORBIDDEN, hotspot)

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_set_standard_cursor(cursor_click)
		else:
			_set_standard_cursor(cursor_normal)

# Helper for just the standard arrow
func _set_standard_cursor(texture: Texture2D):
	if texture:
		Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, hotspot)
