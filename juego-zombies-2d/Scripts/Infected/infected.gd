extends CharacterBody2D
## Infectado. Detecta al Player por distancia y línea de visión, lo persigue, y
## al perderlo acude a la última posición donde lo vio.
##
## La detección sigue siendo tosca: un muro entre los dos lo ciega, pero te ve
## de espaldas y estando quieto. El cono de visión y la detección por movimiento
## llegan más adelante.

## Las tres conductas. Sólo una está activa a la vez.
## Rutina      — no sabe nada de ti. Sin rutas de patrulla, se queda donde está.
## Persecución — te tiene detectado y va hacia ti.
## Búsqueda    — te perdió. Acude a la última posición conocida y no te encuentra.
enum Estado { RUTINA, PERSECUCION, BUSQUEDA }

## Velocidad en píxeles por segundo. Editable desde el inspector.
## Es un valor de partida, no una fase de comportamiento: las fases del GDD
## (Alteración, Hostilidad, Adaptación) llegan como perfiles de datos más adelante.
@export var speed: float = 220.0

## Radio de detección, en píxeles. 224 son 7 tiles de 32.
## Valor de partida: no es ajustable de verdad hasta poder jugarlo en el teléfono.
@export var detection_radius: float = 224.0

## Qué capas cortan la línea de visión. Sólo el Mundo (capa 1).
## Player (capa 2) e Infectados (capa 4) se dejan fuera a propósito: si el rayo
## chocase con ellos, el infectado se cegaría contra el propio jugador al que
## apunta, y uno plantado delante de otro le taparía la vista al de atrás.
@export_flags_2d_physics var vision_mask: int = 1

## Cuánto insiste buscando antes de rendirse, en segundos.
## 8 s es el valor que el GDD asigna a la memoria de la fase Hostilidad.
@export var search_duration: float = 10000

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

## Grupo por el que se localiza al Player. Lo declara player.gd en su _ready().
const PLAYER_GROUP: StringName = &"player"

@onready var _agent: NavigationAgent2D = $NavigationAgent2D

# El destino sólo se entrega al agente una vez que el mapa está sincronizado.
var _navigation_started: bool = false

# Cuenta atrás hasta el siguiente recálculo. Arranca con un desfase propio
# para que varios infectados no recalculen todos en el mismo fotograma.
var _repath_countdown: float = 0.0

# Si el agente ha recibido ya algún destino. Hasta entonces su target_position
# vale (0,0), que no significa «la esquina del mapa» sino «todavía nada»:
# caminar hacia ahí mandaría al infectado en diagonal hacia arriba a la
# izquierda durante el desfase inicial. Prefiere quedarse quieto, que además se
# lee como un cuarto de segundo de reacción antes de arrancar.
var _ruta_entregada: bool = false

var _estado: Estado = Estado.RUTINA

# A dónde quiere ir la conducta activa. En Rutina no hay destino: se está quieto.
var _destino: Vector2 = Vector2.ZERO
var _tiene_destino: bool = false

# Perseguir no tiene «llegada»; buscar sí. Lo decide cada conducta.
var _detenerse_al_llegar: bool = true

# La memoria. Un Vector2 copiado, no una referencia que siga al Player: cuando
# deja de detectarlo, esto se queda exactamente donde estaba.
# Es también el destino de la búsqueda: un solo dato, no dos que puedan divergir.
var _ultima_posicion_conocida: Vector2 = Vector2.ZERO
var _tiene_memoria: bool = false

var _search_countdown: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)

	# Una máscara a cero no choca con nada, así que la línea de visión queda
	# desactivada y el infectado vuelve a verte a través de las paredes. Es un
	# ajuste legítimo para depurar, pero apaga en silencio una subetapa entera:
	# tiene que notarse en consola.
	if vision_mask == 0:
		push_warning("Infectado: vision_mask está a 0, no hay línea de visión. Te detecta a través de los muros.")

	# El radio de llegada TIENE que ser mayor que el de separación, o aparece
	# un bucle: llego -> la repulsión me empuja fuera -> ya no cuento como
	# llegado -> vuelvo a caminar -> me empuja otra vez. El infectado rebota
	# en el sitio indefinidamente.
	#
	# Sólo afecta a la búsqueda: la persecución ignora la llegada a propósito.
	_agent.target_desired_distance = separation_radius * 1.25


func _physics_process(delta: float) -> void:
	if not _navigation_started:
		_try_start_navigation()
		return

	_evaluar_transiciones(_percibir())

	# Cada conducta decide únicamente A DÓNDE quiere ir y si se detiene al
	# llegar. El movimiento en sí es común a las tres y vive en _avanzar().
	match _estado:
		Estado.RUTINA:
			_conducta_rutina()
		Estado.PERSECUCION:
			_conducta_persecucion()
		Estado.BUSQUEDA:
			_conducta_busqueda(delta)

	_avanzar(delta)


## Cambia de conducta. Pública porque la usan la percepción y las pruebas.
func cambiar_estado(nuevo: Estado) -> void:
	if nuevo == _estado:
		return

	_estado = nuevo

	if _estado == Estado.BUSQUEDA:
		_search_countdown = search_duration


func estado_actual() -> Estado:
	return _estado


## La última posición donde vio al Player. Sólo válida si tiene_memoria().
func ultima_posicion_conocida() -> Vector2:
	return _ultima_posicion_conocida


func tiene_memoria() -> bool:
	return _tiene_memoria


# --- Percepción --------------------------------------------------------------

## Único sitio del script que sabe que el Player existe. Devuelve si lo tiene
## detectado ahora mismo y, de paso, refresca la memoria.
func _percibir() -> bool:
	var jugador: Node2D = _jugador()
	if jugador == null:
		return false

	# La distancia va antes que el rayo a propósito: es la comprobación barata y
	# hace de filtro. Con el jugador lejos no se lanza ni un rayo, que es lo que
	# mantiene plano el coste el día que haya veinte infectados en pantalla.
	if global_position.distance_to(jugador.global_position) > detection_radius:
		return false

	# Un muro en medio lo ciega. Es la única diferencia con la etapa anterior, y
	# como la memoria se escribe DESPUÉS, al taparte deja de refrescarse y queda
	# congelada en el último sitio donde te vio de verdad.
	if not _hay_linea_de_vision(jugador.global_position):
		return false

	# Mientras lo detecta, la memoria se refresca. Al dejar de detectarlo
	# simplemente deja de escribirse, y lo que queda es una copia del último
	# sitio donde estuvo — no un puntero que lo siga.
	_ultima_posicion_conocida = jugador.global_position
	_tiene_memoria = true
	return true


func _jugador() -> Node2D:
	# Se consulta el grupo cada fotograma en lugar de cachear la referencia.
	# Cachearla obligaría a revalidarla, e is_instance_valid() NO basta: un nodo
	# sacado del árbol sin liberar sigue pasando esa comprobación y devuelve una
	# posición obsoleta. El grupo deja de contenerlo en cuanto sale del árbol.
	#
	# El coste es una consulta por infectado y fotograma, muy por debajo del
	# bucle que _separation() ya paga contra todos los demás.
	var nodos: Array = get_tree().get_nodes_in_group(PLAYER_GROUP)
	if nodos.is_empty():
		return null
	return nodos[0] as Node2D


## Si hay línea recta y limpia entre el infectado y un punto. Una sola pregunta
## al motor de física: ¿el segmento choca con algo de `vision_mask`?
##
## No hace falta lista de exclusiones: como la máscara es sólo la capa 1, ni el
## Player ni los otros infectados pueden aparecer en la respuesta.
##
## Sólo puede llamarse desde el proceso de física. Fuera de él el espacio está
## bloqueado y la consulta falla.
func _hay_linea_de_vision(destino: Vector2) -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(
		global_position, destino, vision_mask
	)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _evaluar_transiciones(detectado: bool) -> void:
	if detectado:
		cambiar_estado(Estado.PERSECUCION)
		return

	# Dejar de detectarlo sólo cambia algo si lo estaba persiguiendo: ahí es
	# cuando la memoria pasa a tener sentido. Esto cubre también que el Player
	# desaparezca del árbol en mitad de una persecución — sin este caso, el
	# infectado se quedaría clavado en persecución para siempre.
	if _estado == Estado.PERSECUCION:
		cambiar_estado(Estado.BUSQUEDA)


# --- Conductas ---------------------------------------------------------------

func _conducta_rutina() -> void:
	# Sin rutas de patrulla todavía, la rutina es quedarse donde esté.
	# No vuelve a ningún punto de origen: se detiene donde le pilló.
	_tiene_destino = false


func _conducta_persecucion() -> void:
	# La percepción acaba de refrescar la memoria con la posición del Player,
	# así que perseguir es sencillamente ir a la memoria.
	_destino = _ultima_posicion_conocida
	_tiene_destino = true

	# Perseguir no tiene llegada: el infectado sigue viniendo mientras te
	# detecte. Si se detuviera al «llegar», se aparcaría a la distancia de
	# tolerancia del agente y no te alcanzaría nunca.
	_detenerse_al_llegar = false


func _conducta_busqueda(delta: float) -> void:
	if not _tiene_memoria:
		# Nunca llegó a ver al Player: no hay nada que buscar.
		cambiar_estado(Estado.RUTINA)
		return

	_destino = _ultima_posicion_conocida
	_tiene_destino = true
	_detenerse_al_llegar = true

	_search_countdown -= delta

	# La llegada sólo cuenta si el agente YA tiene ruta hacia este punto.
	# Consultarlo antes devuelve «terminada» simplemente porque todavía no se
	# le ha dado destino, y la búsqueda se rendiría en su primer fotograma.
	var llego: bool = (
		_agent.target_position.is_equal_approx(_ultima_posicion_conocida)
		and _agent.is_navigation_finished()
	)

	# Se rinde por tiempo, o al llegar al punto y no encontrar nada.
	if _search_countdown <= 0.0 or llego:
		cambiar_estado(Estado.RUTINA)


# --- Movimiento común --------------------------------------------------------

func _avanzar(delta: float) -> void:
	var deseada: Vector2 = Vector2.ZERO

	if _tiene_destino:
		_tick_repath(delta)

		var parar: bool = _detenerse_al_llegar and _agent.is_navigation_finished()
		if _ruta_entregada and not parar:
			# El agente devuelve el siguiente punto de la ruta que ya calculó.
			# Mismo patrón de movimiento que player.gd; lo único que cambia es
			# de dónde viene la dirección: allí del joystick, aquí de la navegación.
			var next_point: Vector2 = _agent.get_next_path_position()
			deseada = global_position.direction_to(next_point) * speed

	# La separación se aplica siempre, incluso parado: si no, se apilarían unos
	# encima de otros al llegar o al quedarse en rutina.
	velocity = deseada + _separation()
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
	_navigation_started = true


func _tick_repath(delta: float) -> void:
	# El temporizador es la ÚNICA autoridad sobre cuándo se recalcula la ruta.
	# Ningún cambio de conducta lo adelanta: si lo hiciera, oscilar en el borde
	# del radio de detección forzaría un recálculo por fotograma —60 por segundo
	# en vez de 4— y además sincronizaría a todos los infectados que detectasen
	# al Player a la vez, anulando el desfase de arriba.
	_repath_countdown -= delta
	if _repath_countdown > 0.0:
		return

	_repath_countdown = repath_interval
	_agent.target_position = _destino
	_ruta_entregada = true


func _separation() -> Vector2:
	# Los infectados no chocan físicamente entre sí: comparten capa propia y
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
