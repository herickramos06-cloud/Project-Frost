extends Control
class_name VirtualJoystick

# --- Referencias a nodos hijos ---
@onready var base_rect: TextureRect = $Base
@onready var stick_rect: TextureRect = $Stick

# --- Configuración exportada ---
## Porcentaje del radio de la Base que define el límite máximo del Stick.
## 1.0 = llega exactamente al borde. 0.9 deja un pequeño margen visual.
@export_range(0.1, 1.0, 0.05) var max_radius_ratio: float = 0.9

## Zona muerta cerca del centro: evita que micro-temblores del dedo
## generen input residual cuando el jugador "cree" que está quieto.
## 0.0 = desactivada.
@export_range(0.0, 0.5, 0.05) var deadzone: float = 0.15

# --- Estado interno ---
var _is_pressed: bool = false
var _touch_index: int = -1
var _output: Vector2 = Vector2.ZERO


func _ready() -> void:
	_reset_stick_position()


func _input(event: InputEvent) -> void:
	# Usamos _input (no _gui_input) para no perder el drag ni el release
	# cuando el dedo se mueve fuera del área visual del joystick.
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and not _is_pressed:
		# Solo iniciamos el seguimiento si el toque empezó dentro del área.
		if base_rect.get_global_rect().has_point(event.position):
			_is_pressed = true
			_touch_index = event.index
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
	elif not event.pressed and event.index == _touch_index:
		_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if _is_pressed and event.index == _touch_index:
		_update_stick(event.position)
		get_viewport().set_input_as_handled()


func _update_stick(global_touch_pos: Vector2) -> void:
	var center: Vector2 = base_rect.size / 2.0
	var max_radius: float = (base_rect.size.x / 2.0 - stick_rect.size.x / 2.0) * max_radius_ratio

	var local_touch_pos: Vector2 = base_rect.get_global_transform().affine_inverse() * global_touch_pos
	var offset: Vector2 = local_touch_pos - center
	var clamped_offset: Vector2 = offset.limit_length(max_radius)

	stick_rect.position = center + clamped_offset - (stick_rect.size / 2.0)

	var raw: Vector2 = clamped_offset / max_radius
	_output = raw if raw.length() >= deadzone else Vector2.ZERO


func _release() -> void:
	_is_pressed = false
	_touch_index = -1
	_output = Vector2.ZERO
	_reset_stick_position()


func _reset_stick_position() -> void:
	stick_rect.position = (base_rect.size / 2.0) - (stick_rect.size / 2.0)


## Interfaz pública: esto es lo que Player.gd debe leer cada frame.
## Devuelve un Vector2 normalizado entre (0,0) y longitud 1.0.
func get_vector() -> Vector2:
	return _output


func is_active() -> bool:
	return _is_pressed
