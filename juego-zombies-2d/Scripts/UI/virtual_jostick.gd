extends Control

# Referencias a los nodos hijos. Se recomienda usar @onready para que
# estén disponibles y cacheados una vez la escena carga en el árbol.
@onready var base_rect: TextureRect = $Base
@onready var stick_rect: TextureRect = $Stick

# Estado interno para saber si el usuario está interactuando.
var is_pressed: bool = false
var touch_index: int = -1 # Guarda el índice del dedo que tocó (preparando multitouch)

func _ready() -> void:
	# Centrar el stick visualmente al iniciar.
	_reset_stick_position()

func _gui_input(event: InputEvent) -> void:
	# 1. Detectar inicio o fin del toque en la pantalla
	if event is InputEventScreenTouch:
		if event.pressed and not is_pressed:
			# El usuario acaba de tocar el joystick
			is_pressed = true
			touch_index = event.index
			_update_stick_position(event.position)
		elif not event.pressed and event.index == touch_index:
			# El usuario soltó el joystick
			is_pressed = false
			touch_index = -1
			_reset_stick_position()
			
	# 2. Detectar arrastre del dedo mientras está presionado
	elif event is InputEventScreenDrag:
		if is_pressed and event.index == touch_index:
			# Actualizamos la posición para que el stick siga al dedo
			_update_stick_position(event.position)

func _update_stick_position(touch_pos: Vector2) -> void:
	# En esta etapa, el centro del stick simplemente iguala la posición del toque.
	# La posición de 'touch_pos' es relativa a este nodo Control padre (Joystick).
	
	# Calculamos la posición centrada considerando el tamaño del stick
	var new_pos: Vector2 = touch_pos - (stick_rect.size / 2.0)
	stick_rect.position = new_pos

func _reset_stick_position() -> void:
	# Retorna el stick exactamente al centro del área Base
	var center_pos: Vector2 = (base_rect.size / 2.0) - (stick_rect.size / 2.0)
	stick_rect.position = center_pos
