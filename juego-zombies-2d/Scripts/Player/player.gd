extends CharacterBody2D
## Controla el movimiento top-down del jugador en 8 direcciones.

## Velocidad en píxeles por segundo. Editable desde el inspector.
@export var speed: float = 500.0


func _physics_process(_delta: float) -> void:
	# Lee el vector unificado de movimiento a través del InputManager global
	var direction := InputManager.get_move_direction()

	velocity = direction * speed
	move_and_slide()
