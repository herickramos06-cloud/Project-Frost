extends Node

var _joystick_direction: Vector2 = Vector2.ZERO

func set_joystick_vector(direction: Vector2) -> void:
	_joystick_direction = direction

func get_move_direction() -> Vector2:
	# En un entorno estrictamente móvil, la única fuente de movimiento
	# es el joystick táctil. Retornamos directamente su valor.
	return _joystick_direction
