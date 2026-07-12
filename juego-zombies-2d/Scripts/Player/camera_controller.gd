extends Camera2D
class_name CameraController

@export var follow_target_path: NodePath
@export_range(1.0, 30.0, 0.5) var follow_speed: float = 8.0

var _follow_target: Node2D

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	limit_smoothed = false

	if follow_target_path != NodePath():
		_follow_target = get_node(follow_target_path) as Node2D

	if _follow_target != null:
		global_position = _follow_target.global_position
		force_update_scroll()

func _physics_process(_delta: float) -> void:
	if _follow_target == null:
		return
	global_position = _follow_target.global_position

func set_map_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom
	limit_enabled = true
