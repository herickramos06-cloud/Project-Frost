extends CharacterBody2D
## Controla el movimiento top-down del jugador en 8 direcciones.

## Velocidad en píxeles por segundo. Editable desde el inspector.
@export var speed: float = 500.0


func _physics_process(_delta: float) -> void:
	# Lee el Input Map y normaliza automáticamente en diagonales.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	move_and_slide()
