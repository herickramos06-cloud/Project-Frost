extends CharacterBody2D
## Controla el movimiento top-down del jugador en 8 direcciones.

## Velocidad en píxeles por segundo. Editable desde el inspector.
@export var speed: float = 180.0

## Grupo por el que los infectados localizan al jugador.
## Un grupo en lugar de una ruta escrita a mano: el infectado no necesita saber
## dónde vive el Player dentro del árbol, y si el Player sale del árbol el grupo
## deja de contenerlo solo, sin referencias obsoletas que revalidar.
const GROUP: StringName = &"player"

@onready var _colision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(GROUP)

	# La percepción del infectado pide una media silueta y la usa mire desde
	# donde mire. Eso sólo vale con un cuerpo redondo: una cápsula alta se ve
	# casi el doble de ancha desde el lado que desde arriba, y ahí un solo
	# número deja de describirla.
	if not (_colision.shape is CircleShape2D):
		push_warning("Player: el cuerpo no es un círculo, así que su silueta cambia según desde dónde se le mire y la línea de visión del infectado la medirá mal.")


func _physics_process(_delta: float) -> void:
	# Lee el vector unificado de movimiento a través del InputManager global
	var direction := InputManager.get_move_direction()

	velocity = direction * speed
	move_and_slide()


## Cuánto sobresale el cuerpo a cada lado de su centro, en píxeles.
##
## La forma del Player es asunto del Player: el infectado pregunta en vez de
## leerle el CollisionShape2D por dentro. Así este número no acaba copiado en
## otro archivo, donde podría desincronizarse en silencio el día que el cuerpo
## cambie de tamaño.
func media_silueta() -> float:
	var forma: Shape2D = _colision.shape
	if forma is CircleShape2D:
		return (forma as CircleShape2D).radius
	if forma is CapsuleShape2D:
		return (forma as CapsuleShape2D).radius
	return 0.0
