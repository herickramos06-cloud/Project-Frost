extends CharacterBody2D
## Infectado. Detecta al Player por distancia y línea de visión, lo persigue, y
## al perderlo acude a la última posición donde lo vio.
##
## Ve dentro de un cono hacia donde mira, más un alcance corto en redondo para
## lo que tiene encima, y un muro entre los dos lo ciega. Sin nada que perseguir
## merodea: elige un sitio cerca, se para a encararlo y va. Lo que todavía no
## distingue es si te mueves: quedarse quieto no salva. Eso llega más adelante.

## Las tres conductas. Sólo una está activa a la vez.
## Rutina      — no sabe nada de ti. Sin rutas de patrulla, se queda donde está.
## Persecución — te tiene detectado y va hacia ti.
## Búsqueda    — te perdió. Acude a la última posición conocida y no te encuentra.
enum Estado { RUTINA, ALERTA, PERSECUCION, BUSQUEDA }

## Nivel de agitación del infectado, de 0.0 a 1.0. 
## Gobierna las transiciones entre estados.
var agitacion: float = 0.0

## Cuánto decae la agitación por segundo si no hay estímulos.
@export var agitacion_decaimiento: float = 0.08

## Velocidad en píxeles por segundo. Editable desde el inspector.
## Es un valor de partida, no una fase de comportamiento: las fases del GDD
## (Alteración, Hostilidad, Adaptación) llegan como perfiles de datos más adelante.
@export var speed: float = 220.0

## Velocidad en estado de Alerta, cuando camina investigando.
@export var alert_speed: float = 70.0

## Daño que aplica al Player al entrar en su radio de ataque o por cada segundo que permanezca dentro.
@export var damage_amount: float = 20.0

## Intervalo en segundos entre cada golpe consecutivo mientras el Player permanezca en el área.
@export var attack_cooldown: float = 1.0

## Hasta dónde llega la vista dentro del cono, en píxeles. 224 son 7 tiles de 32.
## Valor de partida: no es ajustable de verdad hasta poder jugarlo en el teléfono.
@export var vision_radius: float = 190.0

## Apertura total del cono de visión, en grados. 120 es el valor que el GDD
## asigna a la fase Hostilidad: ancho a propósito, porque en un cenital táctil
## no hay forma clara de leer hacia dónde mira un sprite pequeño, y un cono
## estrecho se sentiría injusto.
##
## A 360 el cono abarca todo y vuelve a ver igual por detrás que por delante.
@export_range(10.0, 360.0, 5.0) var vision_angle: float = 100.0

## Alcance a quemarropa, en píxeles, que funciona en 360° mire donde mire.
## Es lo que impide que pegarse a su espalda salga gratis — y, cuando 3.3 haga
## del quedarse quieto una defensa, que congelarse encima de él sea un truco.
@export var close_radius: float = 64.0

## Cuánto tarda en girar la cabeza, en grados por segundo.
##
## Girar de golpe es ilegible: el jugador no podría anticipar hacia dónde va a
## mirar, y con el cono eso se convierte en detecciones que se sienten
## arbitrarias. 120 son tres segundos por vuelta, ajustado jugando.
@export var turn_speed: float = 150

## Cuánto se aleja en cada salto del merodeo, en píxeles.
## Corto lo deja rondando una zona; largo lo hace cruzar el mapa.
@export var wander_radius: float = 350.0

## Cuánto se para en cada punto antes de echar a andar, en segundos.
##
## Es también el tiempo que tiene para girar la cabeza, y el giro va ahí a
## propósito: un giro anunciado por una parada se puede leer, y uno a mitad de
## camino no. El jugador no aprende su recorrido — aprende su ritmo.
@export var wander_pause: float = 1.0

## A qué ritmo merodea. Muy por debajo de `speed`, que es velocidad de caza:
## un patrullero con prisa no da miedo, da prisa.
@export var wander_speed: float = 120

## Dibuja el cono, el alcance corto y la mirada. Sólo para depurar.
@export var mostrar_vision: bool = false

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
@export_range(0.0, 1.0, 0.05) var silueta_factor: float = 1.0

## Cuánto insiste buscando antes de rendirse, en segundos.
## 8 s es el valor que el GDD asigna a la memoria de la fase Hostilidad.
@export var search_duration: float = 8.0

## Cada cuántos segundos se vuelve a entregar el destino al agente.
## Recalcular la ruta es lo único caro de la navegación: hacerlo cada fotograma,
## multiplicado por todos los infectados, es lo que hunde el rendimiento en móvil.
@export var repath_interval: float = 0.20

## Distancia a la que dos infectados empiezan a separarse. Dos cápsulas de
## radio 24 se tocan a 48 px, así que por debajo de eso ya están solapados.
@export var separation_radius: float = 48.0

## Fuerza máxima de esa separación, en píxeles por segundo. Deliberadamente
## suave: queremos que se amontonen sin fundirse, no que se eviten con cortesía.
@export var separation_strength: float = 60.0

## Cuántas veces prueba a encontrar un sitio válido al merodear antes de
## rendirse y quedarse quieto ese ciclo. Un tope, no un bucle abierto.
const INTENTOS_MERODEO: int = 8

## Sólo para el dibujo de depuración: de dónde sale la V y con cuántos tramos se
## traza el arco.
## Por debajo de esta distancia no se actualiza la mirada: la dirección a un
## punto que tienes casi debajo es ruido, no una intención.
const MIRADA_MINIMA: float = 30.0

const RADIO_CUERPO: float = 24.0
const TRAMOS_CONO: int = 48

## Amarillo limpio, ni naranja ni lima. El fondo del juego es un azul casi negro
## (#070d14), así que un amarillo saturado es lo que más separa el cono del suelo
## sin teñirlo. El relleno va muy bajo para que se lea la silueta, no la mancha.
const AMARILLO_BORDE := Color(1.0, 0.86, 0.20, 0.55)
const AMARILLO_RELLENO := Color(1.0, 0.86, 0.20, 0.10)
const ROJO_CERCA := Color(1.0, 0.35, 0.30, 0.55)

## Grupo al que se apuntan todos los infectados, para poder separarse entre sí.
const GROUP: StringName = &"infected"

## Grupo por el que se localiza al Player. Lo declara player.gd en su _ready().
const PLAYER_GROUP: StringName = &"player"

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _attack_area: Area2D = get_node_or_null("AttackArea")

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

# A qué ritmo quiere ir la conducta activa. Cada una lo fija, igual que fija a
# dónde va y si se detiene al llegar: merodear es mucho más lento que cazar.
var _velocidad_actual: float = 0.0

# A dónde va el merodeo. Aparte de `_destino` porque durante la parada ya está
# elegido pero el cuerpo todavía no camina hacia él — sólo lo encara.
var _destino_merodeo: Vector2 = Vector2.ZERO
var _tiene_merodeo: bool = false

# Lo que le queda de parada. Mientras corre, está quieto girando la cabeza.
var _pausa_restante: float = 0.0

# Si la búsqueda ya alcanzó el punto recordado. Es un interruptor y no un final:
# a partir de ahí deja de correr hacia él y se pone a registrar la zona.
var _ya_en_la_memoria: bool = false

# Objetivo dentro del área de ataque y temporizador de cooldown entre impactos.
var _target_in_range: Node2D = null
var _attack_timer: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_velocidad_actual = speed

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

	if _attack_area != null:
		_attack_area.body_entered.connect(_on_attack_area_body_entered)
		_attack_area.body_exited.connect(_on_attack_area_body_exited)


func _physics_process(delta: float) -> void:
	_procesar_ataque(delta)

	if not _navigation_started:
		_try_start_navigation()
		return

	# Decaimiento del medidor de agitación
	agitacion -= agitacion_decaimiento * delta
	agitacion = clampf(agitacion, 0.0, 1.0)

	_evaluar_transiciones(_percibir())

	# Cada conducta decide únicamente A DÓNDE quiere ir y si se detiene al
	# llegar. El movimiento en sí es común a las tres y vive en _avanzar().
	match _estado:
		Estado.RUTINA:
			_conducta_rutina(delta)
		Estado.ALERTA:
			_conducta_alerta(delta)
		Estado.PERSECUCION:
			_conducta_persecucion()
		Estado.BUSQUEDA:
			_conducta_busqueda(delta)

	_avanzar(delta)
	_actualizar_mirada(delta)

	if mostrar_vision:
		queue_redraw()


## Cambia de conducta. Pública porque la usan la percepción y las pruebas.
func cambiar_estado(nuevo: Estado) -> void:
	if nuevo == _estado:
		return

	_estado = nuevo

	if _estado == Estado.BUSQUEDA:
		_search_countdown = search_duration

	# El merodeo es de cada episodio, no del infectado: al cambiar de conducta
	# se olvida del destino que llevaba y elige uno nuevo desde donde esté.
	#
	# Eso es lo que hace que, tras perderte, se quede rondando el sitio de tu
	# error en vez de regresar a ninguna parte — la decisión de la tarea 2.4,
	# «volver a la rutina desde donde esté», cumplida sin código propio.
	_tiene_merodeo = false
	_ya_en_la_memoria = false


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
		# Encima del objetivo la dirección se vuelve ruido: un vector unitario
		# sacado de un píxel de diferencia apunta a cualquier sitio, y la cabeza
		# se pone a girar sola mientras te tiene debajo. No se puede encarar algo
		# sobre lo que estás, así que se queda mirando lo último que encaraba.
		if global_position.distance_to(_ultima_posicion_conocida) < MIRADA_MINIMA:
			return Vector2.ZERO
		return global_position.direction_to(_ultima_posicion_conocida)

	# Merodeando y parado: encara ya el sitio al que va, aunque todavía no camine.
	# Es el giro anunciado, y es lo único que hace legible un recorrido al azar.
	if _tiene_merodeo and _pausa_restante > 0.0:
		return global_position.direction_to(_destino_merodeo)

	# Si no, mira hacia donde intenta ir. Sin rumbo la mirada no se toca.
	return _rumbo


# --- Percepción --------------------------------------------------------------

## Único sitio del script que sabe que el Player existe. Devuelve si lo tiene
## detectado ahora mismo y, de paso, refresca la memoria.
func _percibir() -> bool:
	var jugador: Node2D = _jugador()
	if jugador == null:
		return false

	var distancia: float = global_position.distance_to(jugador.global_position)
	
	# Quedarse quieto te salva (sigilo), a menos que estés a quemarropa.
	# Si estás lejos y no te mueves físicamente, el infectado te ignora.
	var cuerpo := jugador as CharacterBody2D
	var se_mueve: bool = cuerpo != null and cuerpo.velocity.length_squared() > 0.001
	if distancia > close_radius and not se_mueve:
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
		agitacion = 1.0

	match _estado:
		Estado.RUTINA:
			if agitacion >= 1.0:
				cambiar_estado(Estado.PERSECUCION)
			elif agitacion > 0.0:
				cambiar_estado(Estado.ALERTA)
		Estado.ALERTA:
			if agitacion >= 1.0:
				cambiar_estado(Estado.PERSECUCION)
			elif agitacion <= 0.0:
				cambiar_estado(Estado.RUTINA)
		Estado.PERSECUCION:
			if not detectado:
				cambiar_estado(Estado.BUSQUEDA)
		Estado.BUSQUEDA:
			if detectado or agitacion >= 1.0:
				cambiar_estado(Estado.PERSECUCION)
			# Nota: Si el temporizador de BUSQUEDA finaliza, el estado pasará a 
			# RUTINA en _conducta_busqueda(). Si hay agitación restante, RUTINA
			# lo pasará a ALERTA en el siguiente frame.


# --- Conductas ---------------------------------------------------------------

## Sin nada de qué preocuparse, merodea.
func _conducta_rutina(delta: float) -> void:
	_velocidad_actual = wander_speed
	_merodear(delta, wander_pause)


## Agitado pero sin objetivo visual claro.
func _conducta_alerta(delta: float) -> void:
	_velocidad_actual = alert_speed
	_detenerse_al_llegar = true
	
	if not _tiene_memoria:
		# Si no sabe a dónde ir, simplemente deambula nervioso con menos pausas.
		_merodear(delta, wander_pause * 0.5)
		return
		
	# Camina despacio hacia la última posición conocida
	_destino = _ultima_posicion_conocida
	_tiene_destino = true


## Merodear: elegir un sitio cerca, pararse a encararlo, ir, y repetir.
##
## El orden importa. Girar **durante la parada** es lo que hace legible un
## recorrido al azar: no puedes aprender a dónde va, pero siempre ves cuándo
## va a cambiar. Si camina, puedes cruzar por detrás; si se ha parado, no.
##
## Lo usan dos conductas, y cada una decide a qué velocidad y con qué pausa.
##
## Rutina se para: es tranquila y tiene que poder leerse para que planifiques.
## Búsqueda **no se para**, porque acaba de perderte y ahí ese contrato no
## aplica — pararse dos segundos en ese momento se lee como «ha dejado de
## buscarme», que es justo lo contrario de lo que está pasando.
func _merodear(delta: float, pausa: float) -> void:
	_detenerse_al_llegar = true

	if not _tiene_merodeo:
		if not _elegir_merodeo():
			# Ningún sitio válido cerca: se queda quieto y lo reintenta al
			# fotograma siguiente. El peor caso es quedarse parado.
			_tiene_destino = false
			return
		# Un poco de azar en la parada: desincroniza a los infectados entre sí
		# y evita que el ritmo suene a metrónomo.
		_pausa_restante = pausa * randf_range(0.8, 1.2)

	if _pausa_restante > 0.0:
		_pausa_restante -= delta
		# Parado, pero ya encarando el sitio al que va. El cono barre aquí.
		_tiene_destino = false
		return

	_destino = _destino_merodeo
	_tiene_destino = true

	if _llego_a(_destino_merodeo):
		_tiene_merodeo = false


## Elige un punto al azar cerca, sobre la malla. Devuelve si lo consiguió.
##
## En anillo y no en disco: con una distancia mínima, para que no dé saltitos de
## veinte píxeles que se leerían como un temblor en vez de como merodeo.
func _elegir_merodeo() -> bool:
	var mapa: RID = _agent.get_navigation_map()
	var minimo: float = wander_radius * 0.5

	for _intento in INTENTOS_MERODEO:
		var rumbo := Vector2.from_angle(randf() * TAU)
		var tanteo: Vector2 = global_position + rumbo * randf_range(minimo, wander_radius)

		# La malla devuelve el punto navegable más cercano al tanteo, que puede
		# quedarse pegado al infectado si el tanteo cayó dentro de un muro.
		var punto: Vector2 = NavigationServer2D.map_get_closest_point(mapa, tanteo)
		if global_position.distance_to(punto) >= minimo:
			_destino_merodeo = punto
			_tiene_merodeo = true
			return true

	return false


## Si el agente ya ha terminado su ruta HACIA ESE PUNTO en concreto.
##
## La segunda mitad de la condición no es un detalle: preguntada antes de
## entregarle el destino, la navegación contesta «terminada» simplemente porque
## todavía no tiene nada que recorrer.
func _llego_a(punto: Vector2) -> bool:
	return _agent.target_position.is_equal_approx(punto) and _agent.is_navigation_finished()


func _conducta_persecucion() -> void:
	_velocidad_actual = speed

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

	# El tiempo es la ÚNICA autoridad sobre cuándo se rinde.
	#
	# Llegar al punto recordado NO termina la búsqueda. Si lo hiciera, bastaría
	# con perderle de vista estando encima de él —lo que pasa en cuanto sales de
	# su cono sin alejarte— para que se rindiera en el primer fotograma: la
	# memoria ya está donde él está, así que «he llegado» es cierto de entrada.
	# Y de paso, los segundos que el GDD asigna a cada fase no gobernarían nada.
	_search_countdown -= delta
	if _search_countdown <= 0.0:
		cambiar_estado(Estado.RUTINA)
		return

	_detenerse_al_llegar = true

	if not _ya_en_la_memoria:
		# Corriendo hacia donde te vio, a velocidad de caza.
		_velocidad_actual = speed
		_destino = _ultima_posicion_conocida
		_tiene_destino = true
		_ya_en_la_memoria = _llego_a(_ultima_posicion_conocida)
		return

	# Está donde te vio y no te ha encontrado. Afloja el paso y registra la zona
	# hasta que se le acabe la memoria. Merodear alrededor del punto es buscar:
	# el ciclo elige sus destinos cerca de donde está, así que ronda sin irse.
	_velocidad_actual = wander_speed
	_merodear(delta, 0.0)


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
			deseada = global_position.direction_to(next_point) * _velocidad_actual

	# Se guarda antes de sumar la repulsión, porque esto es a dónde QUIERE ir.
	# La mirada lee este dato y no la velocidad final: si leyera la velocidad,
	# un empujón de un compañero le giraría la cabeza.
	_rumbo = deseada.normalized()

	# La separación se aplica siempre, incluso parado: si no, se apilarían unos
	# encima de otros al llegar o al quedarse en rutina.
	velocity = deseada + _separation()
	move_and_slide()


## Dibujo de depuración: el cono en V saliendo de los ojos, el alcance corto y
## el alcance total. En espacio local, que aquí coincide con el global porque el
## nodo nunca rota: lo que gira es la mirada, no el cuerpo.
##
## La V arranca en el borde del cuerpo y no en su centro, que es donde de verdad
## se mide el ángulo. Son 24 px de diferencia en el vértice, imperceptibles, y a
## cambio se lee como una mirada en vez de como un gráfico de sectores.
func _draw() -> void:
	if not mostrar_vision:
		return

	var encara: float = _mirada.angle()
	var medio_cono: float = deg_to_rad(vision_angle) / 2.0

	if vision_angle >= 360.0:
		draw_arc(Vector2.ZERO, vision_radius, 0.0, TAU, TRAMOS_CONO, AMARILLO_BORDE, 1.5)
		draw_arc(Vector2.ZERO, close_radius, 0.0, TAU, 32, ROJO_CERCA, 2.0)
		return

	# La cuña: el vértice en los ojos y el borde exterior siguiendo el arco.
	var ojos: Vector2 = _mirada * RADIO_CUERPO
	var cunya := PackedVector2Array([ojos])
	for k in TRAMOS_CONO + 1:
		var avance: float = float(k) / float(TRAMOS_CONO)
		var angulo: float = encara - medio_cono + 2.0 * medio_cono * avance
		cunya.append(Vector2.from_angle(angulo) * vision_radius)

	draw_colored_polygon(cunya, AMARILLO_RELLENO)
	draw_line(ojos, Vector2.from_angle(encara - medio_cono) * vision_radius, AMARILLO_BORDE, 1.5)
	draw_line(ojos, Vector2.from_angle(encara + medio_cono) * vision_radius, AMARILLO_BORDE, 1.5)
	draw_arc(Vector2.ZERO, vision_radius, encara - medio_cono, encara + medio_cono,
		TRAMOS_CONO, AMARILLO_BORDE, 1.5)

	# El alcance corto, que no depende de hacia dónde mire.
	draw_arc(Vector2.ZERO, close_radius, 0.0, TAU, 32, ROJO_CERCA, 2.0)


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


# --- Ataque y Daño -----------------------------------------------------------

func _procesar_ataque(delta: float) -> void:
	if _target_in_range == null:
		return

	if not is_instance_valid(_target_in_range) or not _target_in_range.is_in_group(PLAYER_GROUP):
		_target_in_range = null
		_attack_timer = 0.0
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_aplicar_dano_al_objetivo()


func _aplicar_dano_al_objetivo() -> void:
	if not is_instance_valid(_target_in_range):
		return

	if _target_in_range.has_method("receive_damage"):
		_target_in_range.receive_damage(damage_amount)
	elif _target_in_range.has_node("HealthComponent"):
		var health: Node = _target_in_range.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(damage_amount)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return

	_target_in_range = body
	_attack_timer = attack_cooldown
	_aplicar_dano_al_objetivo()


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == _target_in_range:
		_target_in_range = null
		_attack_timer = 0.0
