extends Camera2D
class_name CameraController

## Ruta al nodo objetivo (asignada desde el inspector).
@export var follow_target_path: NodePath
@export var follow_offset: Vector2 = Vector2.ZERO
@export_range(1.0, 30.0, 0.5) var follow_speed: float = 8.0

var _follow_target: Node2D
var _shake_offset: Vector2 = Vector2.ZERO
var _target_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	# Usar el suavizado NATIVO de Camera2D — no luchar contra él.
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	limit_smoothed = false
	# Resuelve el NodePath exportado a una referencia real.
	if follow_target_path != NodePath():
		_follow_target = get_node(follow_target_path) as Node2D
	if _follow_target != null:
		# Posicionar instantáneamente en el primer frame (sin transición).
		global_position = _get_desired_position()
		force_update_scroll()

func _physics_process(_delta: float) -> void:
	if _follow_target == null:
		return
	# Mover la cámara directamente al target.
	# Camera2D aplica el suavizado nativo internamente.
	global_position = _get_desired_position()

func _get_desired_position() -> Vector2:
	return _follow_target.global_position + follow_offset + _shake_offset

func apply_shake(_intensity: float, _duration: float) -> void:
	pass

func set_target_zoom(new_zoom: Vector2) -> void:
	_target_zoom = new_zoom

func set_map_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom
	limit_enabled = true
