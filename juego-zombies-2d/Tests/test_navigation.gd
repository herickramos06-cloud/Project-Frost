extends "res://Tests/test_base.gd"
## Pruebas de la malla de navegación (Bloque 1.5).
##
##   Godot --headless --path juego-zombies-2d --script res://Tests/test_navigation.gd
##
## Existe por un fallo concreto: la navegación de Godot calcula la ruta como si
## el agente fuera un punto sin cuerpo, así que la ruta más corta sale pegada al
## filo del muro. Un cuerpo con radio que la sigue empuja contra la pared en
## perpendicular exacta, y deslizar una velocidad perpendicular deja cero. El
## infectado pedía la misma dirección imposible para siempre.
##
## Por eso la prueba clave no es «¿llega?» sino **la holgura de cada punto de
## ruta**: una ruta correcta no es lo mismo que una ruta recorrible.

const HOLGURA_MINIMA: float = 26.0
const CELDA: float = 32.0
const FOTOGRAMAS_POR_RUTA: int = 1800  # 30 s de margen; salen antes al llegar
const LLEGADA: float = 70.0

# Cada caso: nombre, dónde empieza el infectado, dónde está el jugador, y cómo
# se mueve el jugador (0 quieto, 1 alejándose, 2 acercándose).
#
# Los casos A y B son los que importan: antes del 1.5 se quedaban clavados para
# siempre, y son esconderse y huir — las dos únicas cosas que hace el jugador.
const CASOS: Array = [
	["ruta 1  hueco de 5 tiles      ", Vector2(640, 176), Vector2(656, -16), 0],
	["ruta 2  ARTERIA norte<->sur   ", Vector2(1150, 120), Vector2(1044, 660), 0],
	["ruta 3  esquina a la alcoba   ", Vector2(200, 176), Vector2(880, -160), 0],
	["ruta 4  ruta larga completa   ", Vector2(78, 701), Vector2(900, -48), 0],
	["caso A  jugador QUIETO        ", Vector2(640, 176), Vector2(656, -16), 0],
	["caso B  jugador se ALEJA      ", Vector2(640, 176), Vector2(656, -16), 1],
	["caso C  jugador se ACERCA     ", Vector2(640, 176), Vector2(656, -16), 2],
]

var _mundo: Node
var _nav: NavigationRegion2D
var _ground: TileMapLayer
var _walls: TileMapLayer
var _j: Node2D
var _i: Node2D

var _muros: Dictionary = {}
var _pisables: Array = []

var _f: int = 0
var _fase: int = 0
var _caso: int = 0
var _inicio_caso: int = 0
var _incursiones: int = 0


func _initialize() -> void:
	print("\n=== NAVEGACIÓN (Bloque 1.5) ===")
	_mundo = cargar_mundo()


func _physics_process(_delta: float) -> bool:
	_f += 1

	match _fase:
		0:
			if _f == 6:
				_preparar()
			elif _f == 20:
				_medir_malla()
				_fase = 1
				_lanzar_caso()
		1:
			_mover_jugador()
			if _caso_terminado():
				_anotar_caso()
		2:
			_contar_incursiones()
			if _f - _inicio_caso == 900:
				comprobar(
					"cero incursiones en celda de muro",
					_incursiones == 0,
					"%d en 900 fotogramas x %d infectados" % [_incursiones, infectados().size()]
				)
				resumen_y_salir()
				return true

	if _f > 30000:
		print("  TIMEOUT")
		quit(1)
		return true
	return false


# --- Montaje -----------------------------------------------------------------

func _preparar() -> void:
	_j = jugador()
	_j.set_physics_process(false)
	for infectado in infectados():
		infectado.set_physics_process(false)
	apartar_infectados()
	_i = infectados()[0]

	_nav = _mundo.get_node("Navigation") as NavigationRegion2D
	_ground = _mundo.get_node("Ground") as TileMapLayer
	_walls = _mundo.get_node("Walls") as TileMapLayer

	for celda in _walls.get_used_cells():
		_muros[celda] = true

	var rect: Rect2i = _walls.get_used_rect()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var celda := Vector2i(x, y)
			if _ground.get_cell_source_id(celda) != -1 and _walls.get_cell_source_id(celda) == -1:
				_pisables.append(Vector2(celda) * CELDA + Vector2(CELDA, CELDA) / 2.0)

	# La navegación por tile tiene que estar apagada: su polígono llega al filo
	# del muro, así que las dos superficies a la vez devuelven el fallo original.
	titulo("montaje")
	comprobar("navegación por tile apagada", not _ground.navigation_enabled,
		"Ground.navigation_enabled = %s" % _ground.navigation_enabled)
	comprobar("malla horneada instalada", _nav.navigation_polygon != null,
		"%d polígonos, holgura %.0f px" % [_nav.navigation_polygon.get_polygon_count(), _nav.agent_radius])
	comprobar("la holgura cubre el cuerpo del infectado",
		_nav.agent_radius >= _radio_de(_i),
		"cuerpo %.0f px contra holgura %.0f px" % [_radio_de(_i), _nav.agent_radius])


# --- Malla -------------------------------------------------------------------

func _medir_malla() -> void:
	titulo("la malla")

	var inicio := Time.get_ticks_usec()
	for _n in 5:
		_nav._hornear(_ground, _walls)
	print("         coste del horneado: %.2f ms" % ((Time.get_ticks_usec() - inicio) / 5000.0))

	var mapa: RID = _nav.get_navigation_map()

	# LA comprobación de esta prueba. No basta con que la ruta llegue: cada
	# punto por el que pasa tiene que tener sitio para el cuerpo.
	var muestra: Array = []
	for k in range(0, _pisables.size(), 37):
		muestra.append(_pisables[k])

	var rutas := 0
	var puntos := 0
	var estrechos := 0
	var peor := 99999.0
	for desde in muestra:
		for hasta in muestra:
			if desde == hasta:
				continue
			var ruta: PackedVector2Array = NavigationServer2D.map_get_path(mapa, desde, hasta, true)
			if ruta.size() < 2:
				continue
			rutas += 1
			# Los extremos los fija quien pide la ruta, no la malla: sólo se
			# miden los puntos intermedios, que son los que la malla decide.
			for k in range(1, ruta.size() - 1):
				puntos += 1
				var holgura := _distancia_al_muro(ruta[k])
				peor = minf(peor, holgura)
				if holgura < HOLGURA_MINIMA:
					estrechos += 1

	comprobar("ningún punto de ruta roza un muro", estrechos == 0,
		"%d rutas, %d puntos intermedios, peor holgura %.1f px" % [rutas, puntos, peor])

	var origen: Vector2 = NavigationServer2D.map_get_closest_point(mapa, Vector2(78, 701))
	var aisladas := 0
	for punto in _pisables:
		var cercano: Vector2 = NavigationServer2D.map_get_closest_point(mapa, punto)
		var ruta: PackedVector2Array = NavigationServer2D.map_get_path(mapa, origen, cercano, true)
		if ruta.size() < 2 or ruta[ruta.size() - 1].distance_to(cercano) > 1.0:
			aisladas += 1

	comprobar("encoger la malla no aisló ninguna zona", aisladas == 0,
		"%d/%d celdas alcanzables desde el spawn" % [_pisables.size() - aisladas, _pisables.size()])

	titulo("rutas de extremo a extremo")


# --- Rutas -------------------------------------------------------------------

func _lanzar_caso() -> void:
	apartar_infectados()
	_i.global_position = CASOS[_caso][1]
	_j.global_position = CASOS[_caso][2]
	# Sin percepción y sin olvido: lo que se mide aquí es si el cuerpo puede
	# recorrer la ruta, no si te ve. Mezclarlo daría dos sospechosos.
	_i.vision_mask = 0
	_i.detection_radius = 100000.0
	_i.cambiar_estado(0)
	_i.set_physics_process(true)
	_inicio_caso = _f


func _mover_jugador() -> void:
	var t: float = float(_f - _inicio_caso) / 60.0
	match CASOS[_caso][3]:
		1:
			_j.global_position = Vector2(minf(656.0 + 60.0 * t, 900.0), -16)
		2:
			_j.global_position = Vector2(maxf(656.0 - 60.0 * t, 80.0), -16)


func _caso_terminado() -> bool:
	var transcurrido: int = _f - _inicio_caso
	if transcurrido <= 30:
		return false
	return _i.global_position.distance_to(_j.global_position) < LLEGADA \
		or transcurrido >= FOTOGRAMAS_POR_RUTA


func _anotar_caso() -> void:
	var distancia: float = _i.global_position.distance_to(_j.global_position)
	var llego: bool = distancia < LLEGADA
	var segundos: float = float(_f - _inicio_caso) / 60.0
	comprobar(CASOS[_caso][0], llego,
		("alcanzado en %5.2f s" % segundos) if llego else "no llega en 30 s")

	_caso += 1
	if _caso < CASOS.size():
		_lanzar_caso()
		return

	titulo("regresión del Bloque 1")
	_j.global_position = Vector2(200, 600)
	var posiciones := [Vector2(640, 176), Vector2(200, 176), Vector2(1000, 600)]
	var lista: Array = infectados()
	for k in mini(3, lista.size()):
		lista[k].global_position = posiciones[k]
		lista[k].set_physics_process(true)
		lista[k].cambiar_estado(0)
	_fase = 2
	_inicio_caso = _f


func _contar_incursiones() -> void:
	for infectado in infectados():
		var pos: Vector2 = (infectado as Node2D).global_position
		if _muros.has(Vector2i(floor(pos.x / CELDA), floor(pos.y / CELDA))):
			_incursiones += 1


# --- Geometría ---------------------------------------------------------------

## Distancia del punto al muro más cercano. Se miran sólo las celdas vecinas:
## un muro a más de dos celdas no puede ser el más cercano.
func _distancia_al_muro(punto: Vector2) -> float:
	var celda := Vector2i(floor(punto.x / CELDA), floor(punto.y / CELDA))
	var minima := 99999.0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var vecina := celda + Vector2i(dx, dy)
			if not _muros.has(vecina):
				continue
			var esquina := Vector2(vecina) * CELDA
			var cercano := Vector2(
				clampf(punto.x, esquina.x, esquina.x + CELDA),
				clampf(punto.y, esquina.y, esquina.y + CELDA)
			)
			minima = minf(minima, punto.distance_to(cercano))
	return minima


## Cuánto sitio libre necesita un cuerpo. A una cápsula se le pide su semieje
## mayor y no su radio: el horneado supone un agente circular, y una cápsula
## alta en cenital necesita su media altura, no su anchura.
func _radio_de(cuerpo: Node2D) -> float:
	var colision := cuerpo.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision == null or colision.shape == null:
		return 0.0
	var forma: Shape2D = colision.shape
	if forma is CircleShape2D:
		return (forma as CircleShape2D).radius
	if forma is CapsuleShape2D:
		var capsula := forma as CapsuleShape2D
		return maxf(capsula.radius, capsula.height / 2.0)
	return 0.0
