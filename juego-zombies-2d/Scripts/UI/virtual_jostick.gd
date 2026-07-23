extends Control
class_name VirtualJoystick

# --- Referencias a nodos hijos ---
# --- Child node references ---
@onready var base_rect: TextureRect = $Base
@onready var stick_rect: TextureRect = $Stick

# --- Configuración exportada ---
# --- Exported configuration ---

# Porcentaje del radio de la Base que define el límite máximo del Stick.
# Percentage of the Base's radius that defines the Stick's max limit.
# 1.0 = llega exactamente al borde. 0.9 deja un pequeño margen visual.
# 1.0 = reaches exactly the edge. 0.9 leaves a small visual margin.
@export_range(0.1, 1.0, 0.05) var max_radius_ratio: float = 0.9

# Zona muerta cerca del centro: evita input residual por micro-temblores.
# Deadzone near the center: prevents residual input from tiny finger shakes.
# 0.0 = desactivada. / 0.0 = disabled.
@export_range(0.0, 0.5, 0.05) var deadzone: float = 0.15

# --- Estado interno ---
# --- Internal state ---
var _is_pressed: bool = false
var _touch_index: int = -1 # Índice del dedo que tocó / Index of the finger that touched
var _output: Vector2 = Vector2.ZERO # Vector normalizado de salida / Normalized output vector


func _ready() -> void:
	# Centrar el stick visualmente al iniciar.
	# Visually center the stick on start.
	_reset_stick_position()


func _input(event: InputEvent) -> void:
	# Usamos _input (no _gui_input) para no perder el drag ni el release
	# We use _input (not _gui_input) so we don't miss drag or release events
	# cuando el dedo se mueve fuera del área visual del joystick.
	# when the finger moves outside the joystick's visual area.
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and not _is_pressed:
		# Solo iniciamos el seguimiento si el toque empezó dentro del área.
		# Only start tracking if the touch began inside the area.
		if base_rect.get_global_rect().has_point(event.position):
			_is_pressed = true
			_touch_index = event.index
			_update_stick(event.position)
			# Evita que otros nodos (ej. botón de disparo) procesen el mismo touch.
			# Prevents other nodes (e.g. a fire button) from processing the same touch.
			get_viewport().set_input_as_handled()
	elif not event.pressed and event.index == _touch_index:
		# El usuario soltó el dedo que controlaba el joystick.
		# The user released the finger controlling the joystick.
		_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if _is_pressed and event.index == _touch_index:
		# Seguimos actualizando mientras el dedo arrastra, esté donde esté.
		# Keep updating while the finger drags, wherever it is.
		_update_stick(event.position)
		get_viewport().set_input_as_handled()


func _update_stick(global_touch_pos: Vector2) -> void:
	# Centro geométrico del área Base en espacio local.
	# Geometric center of the Base area in local space.
	var center: Vector2 = base_rect.size / 2.0

	# Radio máximo en píxeles, descontando el radio del Stick.
	# Max radius in pixels, subtracting the Stick's own radius.
	var max_radius: float = (base_rect.size.x / 2.0 - stick_rect.size.x / 2.0) * max_radius_ratio

	# Convertimos la posición global del touch a espacio local de base_rect.
	# Convert the touch's global position into base_rect's local space.
	var local_touch_pos: Vector2 = base_rect.get_global_transform().affine_inverse() * global_touch_pos
	var offset: Vector2 = local_touch_pos - center

	# Clampeamos el offset al radio máximo (comportamiento de joystick real).
	# Clamp the offset to the max radius (real joystick behavior).
	var clamped_offset: Vector2 = offset.limit_length(max_radius)
	stick_rect.position = center + clamped_offset - (stick_rect.size / 2.0)

	# Normalizamos a un vector de -1..1 y aplicamos la zona muerta.
	# Normalize to a -1..1 vector and apply the deadzone.
	var raw: Vector2 = clamped_offset / max_radius
	_output = raw if raw.length() >= deadzone else Vector2.ZERO
	
	# Inyectar la dirección al InputManager (Autoload global)
	InputManager.set_joystick_vector(_output)


func _release() -> void:
	# Reseteamos todo el estado al soltar el joystick.
	# Reset all state when the joystick is released.
	_is_pressed = false
	_touch_index = -1
	_output = Vector2.ZERO
	_reset_stick_position()
	
	# Limpiar la dirección en el InputManager (Autoload global)
	InputManager.set_joystick_vector(Vector2.ZERO)


func _reset_stick_position() -> void:
	# Retorna el stick exactamente al centro del área Base.
	# Returns the stick exactly to the center of the Base area.
	stick_rect.position = (base_rect.size / 2.0) - (stick_rect.size / 2.0)


# Interfaz pública: esto es lo que Player.gd debe leer cada frame.
# Public interface: this is what Player.gd should read every frame.
# Devuelve un Vector2 normalizado entre (0,0) y longitud 1.0.
# Returns a Vector2 normalized between (0,0) and length 1.0.
func get_vector() -> Vector2:
	return _output


func is_active() -> bool:
	return _is_pressed
