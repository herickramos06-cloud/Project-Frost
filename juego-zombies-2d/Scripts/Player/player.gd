extends CharacterBody2D
## Controla el movimiento top-down del jugador en 8 direcciones.

## Emitida cuando el jugador muere. World la escuchará para gestionar
## el respawn en la tarea 4.2.
signal player_died

## Velocidad en píxeles por segundo. Editable desde el inspector.
@export var speed: float = 180.0

## Grupo por el que los infectados localizan al jugador.
## Un grupo en lugar de una ruta escrita a mano: el infectado no necesita saber
## dónde vive el Player dentro del árbol, y si el Player sale del árbol el grupo
## deja de contenerlo solo, sin referencias obsoletas que revalidar.
const GROUP: StringName = &"player"

@onready var _colision: CollisionShape2D = $CollisionShape2D
@onready var _health: Node = $HealthComponent


func _ready() -> void:
	add_to_group(GROUP)

	# La percepción del infectado pide una media silueta y la usa mire desde
	# donde mire. Eso sólo vale con un cuerpo redondo: una cápsula alta se ve
	# casi el doble de ancha desde el lado que desde arriba, y ahí un solo
	# número deja de describirla.
	if not (_colision.shape is CircleShape2D):
		push_warning("Player: el cuerpo no es un círculo, así que su silueta cambia según desde dónde se le mire y la línea de visión del infectado la medirá mal.")

	_health.died.connect(_on_died)


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


## Punto de entrada para recibir daño desde cualquier fuente. El infectado
## llama aquí; el Player delega en su HealthComponent. Si algún día hay más
## fuentes de daño (trampas, frío), todas pasan por el mismo sitio.
func receive_damage(amount: float) -> void:
	_health.take_damage(amount)


## El HealthComponent avisa de que la salud llegó a cero.
func _on_died() -> void:
	# Desactiva el movimiento: el jugador deja de responder al joystick.
	set_physics_process(false)
	velocity = Vector2.ZERO

	# Sale del grupo para que los infectados dejen de percibirlo al instante.
	# Sin esto, _jugador() seguiría devolviéndolo y la percepción leería
	# una posición que ya no se actualiza.
	remove_from_group(GROUP)

	player_died.emit()
