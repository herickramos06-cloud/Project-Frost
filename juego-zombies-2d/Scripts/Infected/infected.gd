extends CharacterBody2D
## Infectado. Detecta al Player por distancia y línea de visión, lo persigue, y
## al perderlo acude a la última posición donde lo vio.
##
## Ve dentro de un cono hacia donde mira, más un alcance corto en redondo para
## lo que tiene encima, y un muro entre los dos lo ciega. Lo que todavía no
## distingue es si te mueves: quedarse quieto no salva. Eso llega más adelante.

## Las tres conductas. Sólo una está activa a la vez.
## Rutina      — no sabe nada de ti. Sin rutas de patrulla, se queda donde está.
## Persecución — te tiene detectado y va hacia ti.
## Búsqueda    — te perdió. Acude a la última posición conocida y no te encuentra.
enum Estado { RUTINA, PERSECUCION, BUSQUEDA }

## Velocidad en píxeles por segundo. Editable desde el inspector.
## Es un valor de partida, no una fase de comportamiento: las fases del GDD
## (Alteración, Hostilidad, Adaptación) llegan como perfiles de datos más adelante.
@export var speed: float = 220.0

## Hasta dónde llega la vista dentro del cono, en píxeles. 224 son 7 tiles de 32.
## Valor de partida: no es ajustable de verdad hasta poder jugarlo en el teléfono.
@export var vision_radius: float = 224.0

## Apertura total del cono de visión, en grados. 120 es el valor que el GDD
## asigna a la fase Hostilidad: ancho a propósito, porque en un cenital táctil
## no hay forma clara de leer hacia dónde mira un sprite pequeño, y un cono
## estrecho se sentiría injusto.
##
## A 360 el cono abarca todo y vuelve a ver igual por detrás que por delante.
@export_range(10.0, 360.0, 5.0) var vision_angle: float = 120.0

## Alcance a quemarropa, en píxeles, que funciona en 360° mire donde mire.
## Es lo que impide que pegarse a su espalda salga gratis — y, cuando 3.3 haga
## del quedarse quieto una defensa, que congelarse encima de él sea un truco.
@export var close_radius: float = 64.0

## Cuánto tarda en girar la cabeza, en grados por segundo.
##
## Girar de golpe es ilegible: el jugador no podría anticipar hacia dónde va a
## mirar, y con el cono eso se convierte en detecciones que se sienten
## arbitrarias. 120 son tres segundos por vuelta, ajustado jugando.
@export var turn_speed: float = 120.0

## Qué capas cortan la línea de visión. Sólo el Mundo (capa 1).
## Player (capa 2) e Infectados (capa 4) se dejan fuera a propósito: si el rayo
## chocase con ellos, el infectado se cegaría contra el propio jugador al que
## apunta, y uno plantado delante de otro le taparía la vista al de atrás.
@export_flags_2d_physics var vision_mask: int = 1

## Cuánto de la silueta del jugador se tiene en cuenta, de 0 a 1.
##
## En 0 se lanza un solo rayo a su centro. En 1 se lanzan además dos a los
## bordes de su cuerpo, así que asomar un hombro por una esquina basta para que
## lo vean. Es un factor y no una medida en píxeles para no copiar aquí el ancho
## del Player, que es suyo y puede cambiar.
##
## Arranca en 0 a propósito. Con un solo rayo puedes asomarte sin que te vean,
## pero por una frontera invisible —tu centro— que no puedes ver ni aprender ni
## apuntar: es suerte, no habilidad. Esa fantasía la dará 3.3, cuando quedarse
## quieto sea una defensa de verdad. Ahí se sube a 1.
@export_range(0.0, 1.0, 0.05) var silueta_factor: float = 0.0

## Cuánto insiste buscando antes de rendirse, en segundos.
## 8 s es el valor que el GDD asigna a la memoria de la fase Hostilidad.
@export var search_duration: float = 8.0

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

# Hacia dónde mira. Es un dato propio y no se deduce de la velocidad en el
# momento: si se dedujera, al pararse la velocidad valdría cero y la mirada se
# quedaría indefinida. Arranca mirando hacia abajo, hacia la cámara.
var _mirada: Vector2 = Vector2.DOWN

# A dónde intenta ir la navegación, sin contar la repulsión de los compañeros.
# La mirada sigue la intención y no los empujones: un infectado apartado de un
# codazo no se gira a mirar a quien lo apartó.
var _rumbo: Vector2 = Vector2.ZERO


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
	_actualizar_mirada(delta)


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


## Hacia dónde mira, como vector unitario. Es el eje del cono de visión.
func mirada() -> Vector2:
	return _mirada


# --- Mirada ------------------------------------------------------------------

## Gira la cabeza hacia donde toca, sin pasar de `turn_speed` grados por segundo.
## Si no hay nada que mirar, la mirada **se queda donde estaba**: un infectado
## parado sigue encarando lo último que encaraba, que es lo que un cuerpo hace.
func _actualizar_mirada(delta: float) -> void:
	var deseada: Vector2 = _mirada_deseada()
	if deseada.is_zero_approx():
		return

	var giro_maximo: float = deg_to_rad(turn_speed) * delta
	_mirada = _mirada.rotated(clampf(_mirada.angle_to(deseada), -giro_maximo, giro_maximo))


## Qué querría estar mirando ahora mismo. Vector cero significa «nada nuevo».
func _mirada_deseada() -> Vector2:
	# Persiguiendo mira a su objetivo y no a su marcha. Si mirase hacia donde
	# camina, al rodear un obstáculo el jugador le saldría fuera del cono, lo
	# perdería, lo recuperaría al fotograma siguiente, y tendrías un parpadeo
	# permanente entre Persecución y Búsqueda. Persiguiéndote te mira: sólo un
	# muro te salva.
	if _estado == Estado.PERSECUCION and _tiene_memoria:
		return global_position.direction_to(_ultima_posicion_conocida)

	# Si no, mira hacia donde intenta ir. En Rutina no hay destino, así que esto
	# vale cero y la mirada no se toca.
	return _rumbo


# --- Percepción --------------------------------------------------------------

## Único sitio del script que sabe que el Player existe. Devuelve si lo tiene
## detectado ahora mismo y, de paso, refresca la memoria.
func _percibir() -> bool:
	var jugador: Node2D = _jugador()
	if jugador == null:
		return false

	# La geometría va antes que el rayo a propósito: es la comprobación barata y
	# hace de filtro. Con el jugador lejos o a la espalda no se lanza ni un rayo,
	# que es lo que mantiene plano el coste el día que haya veinte en pantalla.
	if not _esta_en_mi_campo(jugador.global_position):
		return false

	# Un muro en medio lo ciega. Como la memoria se escribe DESPUÉS, al taparte
	# deja de refrescarse y queda congelada en el último sitio donde te vio.
	if not _lo_veo(jugador):
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


## Si un punto cae dentro de lo que el infectado podría ver, sin contar muros.
## Es pura geometría: el cono hacia donde mira, más el alcance corto de 360°.
##
## No sustituye a la línea de visión, la precede. El alcance corto **también**
## respeta las paredes: es vista a quemarropa, no un sexto sentido.
func _esta_en_mi_campo(punto: Vector2) -> bool:
	var distancia: float = global_position.distance_to(punto)

	# Lo que tiene encima lo nota mire donde mire.
	if distancia <= close_radius:
		return true

	if distancia > vision_radius:
		return false

	# A 360° el cono lo abarca todo. Se atiende aparte para que apagarlo sea
	# exacto: con el ángulo justo en el límite, el redondeo podría decidir.
	if vision_angle >= 360.0:
		return true

	var desvio: float = absf(_mirada.angle_to(global_position.direction_to(punto)))
	return desvio <= deg_to_rad(vision_angle) / 2.0


## Si alcanza a ver alguna parte del jugador.
##
## El rayo al centro va primero y resuelve solo la mayoría de las veces:
## persiguiéndote estás a la vista, así que el caso normal —y el único que
## importa el día que haya veinte infectados— cuesta un único rayo. Los dos
## costados existen sólo para rescatar un «no» del centro, que es justo cuando
## asomas medio cuerpo por una esquina.
func _lo_veo(jugador: Node2D) -> bool:
	if _hay_linea_de_vision(jugador.global_position):
		return true

	if silueta_factor <= 0.0:
		return false

	# Los costados salen perpendiculares a la línea que os une, no fijos a los
	# lados de la pantalla. Si fueran fijos, al mirarte desde arriba los dos
	# rayos caerían uno detrás del otro y no medirían absolutamente nada.
	#
	# El ancho se lo pregunta al Player en lugar de guardarlo: un número copiado
	# aquí se desincronizaría en silencio el día que su cuerpo cambie de tamaño.
	var media: float = jugador.media_silueta() * silueta_factor
	var costado: Vector2 = global_position.direction_to(jugador.global_position).orthogonal() * media

	return (
		_hay_linea_de_vision(jugador.global_position + costado)
		or _hay_linea_de_vision(jugador.global_position - costado)
	)


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

	# Se guarda antes de sumar la repulsión, porque esto es a dónde QUIERE ir.
	# La mirada lee este dato y no la velocidad final: si leyera la velocidad,
	# un empujón de un compañero le giraría la cabeza.
	_rumbo = deseada.normalized()

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
