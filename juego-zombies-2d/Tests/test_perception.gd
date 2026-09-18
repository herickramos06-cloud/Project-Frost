extends "res://Tests/test_base.gd"
## Pruebas de la percepción del infectado (Bloque 3, tareas 3.1a y 3.1b).
##
##   Godot --headless --path juego-zombies-2d --script res://Tests/test_perception.gd
##
## Cubre la línea de visión —un muro entre los dos lo ciega—, que la memoria se
## congele al taparse, y los dos rayos laterales que miden la silueta real.
##
## Las dos primeras comprobaciones van en pareja a propósito: misma distancia
## aproximada y las dos dentro del radio, así que lo único que cambia entre
## ellas es la pared. Sueltas no demostrarían nada.

const RADIO: float = 224.0

var _j: Node2D
var _i: Node2D
var _todos: Array = []
var _f: int = 0
var _fase: int = 0
var _inicio: int = 0
var _origen: Vector2


func _initialize() -> void:
	print("\n=== PERCEPCIÓN (3.1a y 3.1b) ===")
	cargar_mundo()


func _physics_process(_delta: float) -> bool:
	_f += 1

	match _fase:
		0:
			if _f == 6:
				_montaje()
			elif _f == 12:
				_linea_de_vision()
				_costados()
				_perpendicular()
				_arrancar_tras_la_pared()
		1:
			if _f - _inicio == 180:
				comprobar("tras la pared -> no se mueve",
					_i.global_position.distance_to(_origen) < 2.0,
					"recorrido %.2f px en 3 s" % _i.global_position.distance_to(_origen))
				_i.global_position = Vector2(640, 176)
				_j.global_position = Vector2(848, 176)
				_origen = _i.global_position
				_inicio = _f
				_fase = 2
		2:
			if _f - _inicio == 180:
				comprobar("a la vista -> te persigue",
					_i.global_position.distance_to(_origen) > 50.0,
					"recorre %.1f px y acaba a %.1f px de ti" % [
						_i.global_position.distance_to(_origen),
						_i.global_position.distance_to(_j.global_position)])
				resumen_y_salir()
				return true

	if _f > 3000:
		print("  TIMEOUT")
		quit(1)
		return true
	return false


func _montaje() -> void:
	_j = jugador()
	_j.set_physics_process(false)
	_todos = infectados()
	for infectado in _todos:
		infectado.set_physics_process(false)
	apartar_infectados()
	_i = _todos[0]

	titulo("montaje")
	var forma_j = _j.get_node("CollisionShape2D").shape
	# La percepción usa una sola media silueta mire desde donde mire, y eso sólo
	# es cierto con un cuerpo redondo: una cápsula alta se ve casi el doble de
	# ancha desde el lado que desde arriba.
	comprobar("el cuerpo del Player es redondo", forma_j is CircleShape2D,
		"%s de radio %.1f" % [forma_j.get_class(), forma_j.radius])
	comprobar("media_silueta() dice lo mismo que el cuerpo",
		is_equal_approx(_j.media_silueta(), forma_j.radius),
		"media_silueta() = %.1f px" % _j.media_silueta())
	comprobar("vision_mask apunta al Mundo", _i.vision_mask == 1,
		"vision_mask = %d (0 apagaría la línea de visión entera)" % _i.vision_mask)
	comprobar("silueta_factor arranca apagado", is_zero_approx(_i.silueta_factor),
		"silueta_factor = %.2f (se enciende en 3.3)" % _i.silueta_factor)
	comprobar("search_duration no contradice al GDD",
		is_equal_approx(_i.search_duration, 8.0),
		"%.1f s, y el GDD asigna 8 a la fase Hostilidad" % _i.search_duration)


func _linea_de_vision() -> void:
	titulo("línea de visión")
	apartar_infectados()
	_i.global_position = Vector2(640, 176)

	_j.global_position = Vector2(848, 176)
	var sin_muro: float = _i.global_position.distance_to(_j.global_position)
	var ve_sin_muro: bool = _i._percibir()

	_j.global_position = Vector2(656, -16)
	var con_muro: float = _i.global_position.distance_to(_j.global_position)
	var ve_con_muro: bool = _i._percibir()

	comprobar("sin muro -> detecta", ve_sin_muro, "a %.1f px" % sin_muro)
	comprobar("con muro -> NO detecta", not ve_con_muro, "a %.1f px" % con_muro)
	comprobar("y las dos dentro del radio", sin_muro <= RADIO and con_muro <= RADIO,
		"%.1f y %.1f px, radio %.0f: sólo cambia la pared" % [sin_muro, con_muro, RADIO])

	# Si el rayo chocase también con la capa de los infectados, uno plantado
	# delante de otro le taparía la vista al de atrás.
	apartar_infectados()
	_j.global_position = Vector2(400, 176)
	var puestos := [Vector2(500, 176), Vector2(560, 176), Vector2(610, 176)]
	var detectan := 0
	for k in mini(3, _todos.size()):
		_todos[k].global_position = puestos[k]
		if _todos[k]._percibir():
			detectan += 1
	comprobar("los cuerpos no tapan la visión", detectan == 3,
		"tres en fila a 100 / 160 / 210 px: detectan %d" % detectan)

	# La memoria se escribe DESPUÉS de comprobar la visión, así que al taparte
	# deja de refrescarse y queda donde te vio por última vez.
	apartar_infectados()
	_i.global_position = Vector2(640, 176)
	_j.global_position = Vector2(700, 176)
	var visto: bool = _i._percibir()
	var memoria: Vector2 = _i.ultima_posicion_conocida()
	_j.global_position = Vector2(656, -16)
	var visto_tapado: bool = _i._percibir()

	comprobar("la memoria se congela al taparse",
		visto and not visto_tapado and memoria.is_equal_approx(Vector2(700, 176)),
		"recuerda %s con el jugador a %.0f px de ahí" % [memoria, memoria.distance_to(Vector2(656, -16))])


func _costados() -> void:
	titulo("los dos rayos laterales (3.1b)")
	apartar_infectados()
	_i.global_position = Vector2(500, 176)

	# Se barre la zona de la esquina del bloque central, que es donde asomarse
	# tiene sentido. Con un solo rayo al centro hay una franja de ±26 px en la
	# que medio cuerpo tuyo está fuera y el infectado dice que no te ve.
	var posiciones: Array = []
	for dx in range(-30, 31, 5):
		for dy in range(230, 291, 10):
			posiciones.append(Vector2(340 + dx, dy))

	var rescatadas := 0
	var ya_visibles := 0
	var quitan_vision := 0
	var ejemplo := ""
	for punto in posiciones:
		_j.global_position = punto
		_i.silueta_factor = 0.0
		var con_un_rayo: bool = _i._lo_veo(_j)
		_i.silueta_factor = 1.0
		var con_tres: bool = _i._lo_veo(_j)
		if con_un_rayo:
			ya_visibles += 1
		if con_tres and not con_un_rayo:
			rescatadas += 1
			if ejemplo.is_empty():
				ejemplo = str(punto)
		if con_un_rayo and not con_tres:
			quitan_vision += 1
	_i.silueta_factor = 0.0

	comprobar("los costados cambian el resultado", rescatadas > 0,
		"%d de %d posiciones pasan de oculto a visto (p.ej. %s)" % [rescatadas, posiciones.size(), ejemplo])
	comprobar("pero no en todas", rescatadas < posiciones.size(),
		"%d ya se veían con el rayo del centro" % ya_visibles)
	# Añadir rayos sólo puede sumar visión. Si alguna vez la quita, la
	# perpendicular está mal calculada.
	comprobar("añadir costados nunca quita visión", quitan_vision == 0,
		"%d posiciones empeoran" % quitan_vision)


func _perpendicular() -> void:
	titulo("la perpendicular")
	_i.global_position = Vector2(500, 176)
	# Los costados salen perpendiculares a la línea que os une, no fijos a los
	# lados de la pantalla: si fueran fijos, al mirarte desde arriba los dos
	# rayos caerían uno detrás del otro y no medirían nada.
	for destino in [Vector2(500, 400), Vector2(800, 176), Vector2(650, 320)]:
		_j.global_position = destino
		var media: float = _j.media_silueta()
		var costado: Vector2 = _i.global_position.direction_to(destino).orthogonal() * media
		var linea: Vector2 = destino - _i.global_position
		comprobar("en ángulo recto y a %.0f px" % media,
			absf(costado.dot(linea)) < 0.01 and is_equal_approx(costado.length(), media),
			"mirando hacia %s el desvío es %s" % [destino, costado.round()])


func _arrancar_tras_la_pared() -> void:
	titulo("de extremo a extremo")
	apartar_infectados()
	_i.global_position = Vector2(640, 176)
	_j.global_position = Vector2(656, -16)
	_i.set_physics_process(true)
	_origen = _i.global_position
	_inicio = _f
	_fase = 1
