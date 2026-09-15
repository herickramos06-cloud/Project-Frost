extends CharacterBody2D
## Cuerpo del infectado. Camina hasta un punto fijo usando la navegación del mundo.
## Todavía sin comportamiento propio: no percibe, no decide y no persigue a nadie.

## Velocidad en píxeles por segundo. Editable desde el inspector.
## Es un valor de partida, no una fase de comportamiento: las fases del GDD
## (Alteración, Hostilidad, Adaptación) llegan como perfiles de datos más adelante.
@export var speed: float = 220.0

## Destino de esta primera prueba de navegación. Fijo y elegido a mano:
## aquí no hay percepción ni selección de objetivo.
@export var target_point: Vector2 = Vector2(200, 400)

## Cada cuántos segundos se vuelve a entregar el destino al agente.
## Recalcular la ruta es lo único caro de la navegación: hacerlo cada fotograma,
## multiplicado por todos los infectados, es lo que hunde el rendimiento en móvil.
@export var repath_interval: float = 0.25

## Distancia a la que dos infectados empiezan a separarse. Dos cápsulas de
## radio 24 se tocan a 48 px, así que por debajo de eso ya están solapados.
@export var separation_radius: float = 48.0

## Fuerza máxima de esa separación, en píxeles por segundo. Deliberadamente
## suave: queremos que se amontonen sin fundirse, no que se eviten con cortesía.
@export var separation_strength: float = 60.0

## Grupo al que se apuntan todos los infectados, para poder separarse entre sí.
const GROUP: StringName = &"infected"

@onready var _agent: NavigationAgent2D = $NavigationAgent2D

# El destino sólo se entrega al agente una vez que el mapa está sincronizado.
var _navigation_started: bool = false

# Cuenta atrás hasta el siguiente recálculo. Arranca con un desfase propio
# para que varios infectados no recalculen todos en el mismo fotograma.
var _repath_countdown: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)

	# El radio de llegada TIENE que ser mayor que el de separación, o aparece
	# un bucle: llego -> la repulsión me empuja fuera -> ya no cuento como
	# llegado -> vuelvo a caminar -> me empuja otra vez. El infectado rebota
	# en el sitio indefinidamente.
	#
	# Con varios infectados yendo al mismo punto, los de fuera se quedan a una
	# distancia parecida al radio de separación: por eso la tolerancia tiene
	# que cubrir esa corona.
	_agent.target_desired_distance = separation_radius * 1.25


func _physics_process(delta: float) -> void:
	if not _navigation_started:
		_try_start_navigation()
		return

	_tick_repath(delta)

	# El agente devuelve el siguiente punto de la ruta que ya calculó.
	# Mismo patrón de movimiento que player.gd; lo único que cambia es de
	# dónde viene la dirección: allí del joystick, aquí de la navegación.
	var desired: Vector2 = Vector2.ZERO
	if not _agent.is_navigation_finished():
		var next_point: Vector2 = _agent.get_next_path_position()
		desired = global_position.direction_to(next_point) * speed

	# La separación se aplica también al llegar, para que no se apilen encima
	# del destino unos sobre otros.
	velocity = desired + _separation()
	move_and_slide()


func _try_start_navigation() -> void:
	# El servidor de navegación no está operativo al arrancar: necesita varios
	# fotogramas de física para sincronizar el mapa. Antes de eso, cualquier
	# consulta devuelve (0,0) — que parece «aquí no hay suelo» y en realidad
	# significa «todavía no sé dónde estás».
	#
	# Contar fotogramas sería frágil: el número cambia según el contexto y el
	# dispositivo. map_get_iteration_id() vale 0 hasta la primera sincronización,
	# así que preguntamos al servidor en lugar de adivinar.
	if NavigationServer2D.map_get_iteration_id(_agent.get_navigation_map()) == 0:
		return

	# Desfase inicial aleatorio dentro del propio intervalo: reparte a los
	# infectados por distintos fotogramas en lugar de sincronizarlos a todos.
	_repath_countdown = randf_range(0.0, repath_interval)

	_agent.target_position = target_point
	_navigation_started = true


func _separation() -> Vector2:
	# Los infectados ya no chocan físicamente entre sí: comparten capa propia y
	# sólo colisionan con el mundo. Sin esto se solaparían hasta parecer uno solo.
	#
	# Coste: cada infectado mira a los demás, así que crece con el cuadrado de
	# cuántos haya. Con los 4 a 20 previstos son unas pocas restas por fotograma.
	var push: Vector2 = Vector2.ZERO

	for otro in get_tree().get_nodes_in_group(GROUP):
		if otro == self:
			continue

		var hacia: Vector2 = global_position - (otro as Node2D).global_position
		var distancia: float = hacia.length()
		if distancia <= 0.0 or distancia >= separation_radius:
			continue

		# Cuanto más cerca, más empuja: nulo al borde del radio, máximo al centro.
		push += hacia.normalized() * (1.0 - distancia / separation_radius)

	return push * separation_strength


func _tick_repath(delta: float) -> void:
	_repath_countdown -= delta
	if _repath_countdown > 0.0:
		return

	_repath_countdown = repath_interval

	# Hoy el destino es fijo, así que volver a asignarlo no recalcula nada:
	# el agente descarta el valor si no ha cambiado. La estructura existe para
	# cuando el destino sea el Player y sí se mueva, en el Bloque 2.
	_agent.target_position = target_point
