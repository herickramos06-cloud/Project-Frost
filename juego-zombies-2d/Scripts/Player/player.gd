extends CharacterBody2D
## Controla el movimiento top-down del jugador en 8 direcciones.

## Velocidad en píxeles por segundo. Editable desde el inspector.
@export var speed: float = 180.0

## Grupo por el que los infectados localizan al jugador.
## Un grupo en lugar de una ruta escrita a mano: el infectado no necesita saber
## dónde vive el Player dentro del árbol, y si el Player sale del árbol el grupo
## deja de contenerlo solo, sin referencias obsoletas que revalidar.
const GROUP: StringName = &"player"


func _ready() -> void:
	add_to_group(GROUP)


func _physics_process(_delta: float) -> void:
	# Lee el vector unificado de movimiento a través del InputManager global
	var direction := InputManager.get_move_direction()

	velocity = direction * speed
	move_and_slide()
