extends Camera2D
class_name CameraController

## Grupo por el que se localiza dinámicamente al jugador según las convenciones de arquitectura.
const PLAYER_GROUP: StringName = &"player"

# Ruta al nodo objetivo (asignada desde el inspector).
# Path to the target node (assigned from the inspector).
@export var follow_target_path: NodePath

# Velocidad del suavizado nativo de Camera2D. Valores altos = sigue casi..
# Speed of Camera2D's native smoothing. High values = follows almost..

# ..instantáneo, valores bajos = más "lag" cinematográfico.
# ..instantly, low values = more cinematic "lag".

@export_range(1.0, 30.0, 0.5) var follow_speed: float = 8.0
var _follow_target: Node2D


func _ready() -> void:
	# Usar el suavizado NATIVO de Camera2D — no luchar contra él.
	# Use Camera2D's NATIVE smoothing — don't fight against it.
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed

	# El corte contra los límites del mapa es instantáneo, no suavizado,..
	# The cutoff against map limits is instant, not smoothed,..
	
	# ..para evitar que la cámara "tiemble" en los bordes.
	# ..to avoid the camera "jittering" at the edges.
	limit_smoothed = false

	# Resuelve el objetivo inicial.
	_follow_target = _find_target()

	if is_instance_valid(_follow_target):
		# Posicionar instantáneamente en el primer frame (sin transición).
		# Position instantly on the first frame (no transition).
		global_position = _follow_target.global_position
		reset_smoothing()
		force_update_scroll()


func _physics_process(_delta: float) -> void:
	# Si la referencia actual se liberó o aún no existe, intenta re-resolverla de forma segura.
	if not is_instance_valid(_follow_target):
		_follow_target = _find_target()
		if _follow_target == null:
			return

	# Mover la cámara directamente al target.
	# Move the camera directly to the target.
	
	# Camera2D aplica el suavizado nativo internamente.
	# Camera2D applies the native smoothing internally.
	global_position = _follow_target.global_position


## Resuelve dinámicamente el objetivo: primero busca por NodePath si es válido,
## y como alternativa robusta busca la instancia activa en el grupo "player".
func _find_target() -> Node2D:
	if follow_target_path != NodePath() and has_node(follow_target_path):
		var candidato := get_node(follow_target_path) as Node2D
		if is_instance_valid(candidato):
			return candidato

	var jugadores := get_tree().get_nodes_in_group(PLAYER_GROUP)
	if not jugadores.is_empty():
		var primer_jugador := jugadores[0] as Node2D
		if is_instance_valid(primer_jugador):
			return primer_jugador

	return null


## Permite reasignar explícitamente el objetivo (útil para el respawn en 4.2).
func set_target(new_target: Node2D, instant: bool = false) -> void:
	_follow_target = new_target
	if instant and is_instance_valid(_follow_target):
		global_position = _follow_target.global_position
		reset_smoothing()
		force_update_scroll()


func set_map_limits(left: int, top: int, right: int, bottom: int) -> void:
	# Configura los límites nativos de Camera2D en coordenadas globales.
	# Sets Camera2D's native limits in global coordinates.
	
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom
	limit_enabled = true
