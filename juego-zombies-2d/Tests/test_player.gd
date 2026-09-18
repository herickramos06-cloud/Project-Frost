extends "res://Tests/test_base.gd"
## Pruebas del Player: aparición, colisión con los muros y paso por el pasillo.
##
##   Godot --headless --path juego-zombies-2d --script res://Tests/test_player.gd
##
## El Player se mueve inyectando el vector directamente en el InputManager, que
## es exactamente lo que hace el joystick. Así se prueba la cadena real de
## entrada y no un atajo que la salte.

const CELDA: float = 32.0
const VELOCIDAD: float = 180.0
const SEGUNDOS: int = 120  # 2 s a 60 fps

var _j: Node2D
var _input: Node
var _f: int = 0
var _paso: int = 0
var _inicio: int = 0
var _origen: Vector2


func _initialize() -> void:
	print("\n=== PLAYER ===")
	cargar_mundo()


func _physics_process(_delta: float) -> bool:
	_f += 1

	if _f == 6:
		# El autoload no se resuelve por nombre en un guion de arranque, porque
		# se registra después de compilarlo. Se busca en el árbol.
		_input = root.get_node_or_null("InputManager")
		_j = jugador()
		for infectado in infectados():
			infectado.set_physics_process(false)
		apartar_infectados()

		titulo("montaje")
		comprobar("el InputManager está vivo", _input != null, str(_input))
		if _input == null:
			resumen_y_salir()
			return true
		var forma = _j.get_node("CollisionShape2D").shape
		comprobar("aparece sobre su marcador",
			_j.global_position.is_equal_approx(Vector2(78, 701)), str(_j.global_position))
		comprobar("capa 2 y máscara 1", _j.collision_layer == 2 and _j.collision_mask == 1,
			"choca con el Mundo y atraviesa a los infectados")
		comprobar("el cuerpo es redondo", forma is CircleShape2D,
			"%s de radio %.1f" % [forma.get_class(), forma.radius])

		titulo("los muros lo paran")
		_empujar(Vector2.LEFT)
		return false

	if _f - _inicio == SEGUNDOS and _paso == 0:
		# El muro oeste acaba en x=32 y el radio es 26, así que el borde exacto
		# está en 58. Si lo atravesara, x bajaría de 32.
		comprobar("muro oeste: no lo atraviesa", _j.global_position.x > CELDA,
			"se para en x = %.1f (muro hasta 32 + radio 26)" % _j.global_position.x)
		_paso = 1
		_empujar(Vector2.DOWN)
		return false

	if _f - _inicio == SEGUNDOS and _paso == 1:
		comprobar("muro sur: no lo atraviesa", _j.global_position.y < 736.0,
			"se para en y = %.1f (muro desde 736 − radio 26)" % _j.global_position.y)
		titulo("el pasillo norte, de 96 px de alto")
		_paso = 2
		_j.global_position = Vector2(200, -48)  # centrado en el pasillo
		_empujar(Vector2.RIGHT)
		return false

	if _f - _inicio == SEGUNDOS and _paso == 2:
		_anotar_pasillo("lo recorre a plena velocidad")
		_paso = 3
		_j.global_position = Vector2(200, -70)  # pegado al techo
		_empujar(Vector2.RIGHT)
		return false

	if _f - _inicio == SEGUNDOS and _paso == 3:
		_anotar_pasillo("y también pegado al techo")
		_paso = 4
		_j.global_position = Vector2(700, -48)
		_empujar(Vector2.LEFT)
		return false

	if _f - _inicio == SEGUNDOS and _paso == 4:
		_anotar_pasillo("y de vuelta hacia el hueco")
		_input.set_joystick_vector(Vector2.ZERO)
		resumen_y_salir()
		return true

	if _f > 1500:
		print("  TIMEOUT")
		quit(1)
		return true
	return false


func _empujar(direccion: Vector2) -> void:
	_input.set_joystick_vector(direccion)
	_origen = _j.global_position
	_inicio = _f


## Con el cuerpo redondo el pasillo deja 44 px de margen, así que cruzarlo no
## debería costar ni un píxel. La cápsula de 88 px de alto sólo dejaba 8 y se
## arrastraba. El máximo teórico en 2 s son 360 px.
func _anotar_pasillo(nombre: String) -> void:
	var recorrido: float = _j.global_position.distance_to(_origen)
	var maximo: float = VELOCIDAD * float(SEGUNDOS) / 60.0
	comprobar(nombre, recorrido > maximo * 0.95,
		"%.1f px en 2 s, máximo teórico %.0f" % [recorrido, maximo])
