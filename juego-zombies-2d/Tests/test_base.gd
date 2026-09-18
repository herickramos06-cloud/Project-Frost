extends SceneTree
## Base común de las pruebas headless. No se ejecuta sola.
##
## Las pruebas son guiones de `SceneTree` porque necesitan fotogramas de física
## de verdad: la navegación no está operativa hasta que el servidor sincroniza el
## mapa, y el cuerpo sólo se mueve dentro del proceso de física. Un test que no
## avance fotogramas no puede medir nada de esto.
##
## Cada prueba lleva su propio contador y termina con `resumen_y_salir()`, que
## devuelve código 1 si algo ha fallado. Así valen tanto a ojo como encadenadas.

var _ok: int = 0
var _fallos: int = 0


## Carga el mundo real, no un montaje aparte. La lección del 13 de septiembre:
## medir a través de un arnés que instancia el mundo dentro de otra escena dio
## un número falso —16 fotogramas de sincronización en vez de 3— que estuvo
## escrito en el dev_log durante días.
func cargar_mundo() -> Node:
	var mundo: Node = load("res://Scenes/World/world.tscn").instantiate()
	root.add_child(mundo)
	return mundo


func titulo(texto: String) -> void:
	print("\n-- %s --" % texto)


func comprobar(nombre: String, condicion: bool, detalle: String) -> void:
	if condicion:
		_ok += 1
	else:
		_fallos += 1
	print("  [%s] %-40s %s" % ["OK   " if condicion else "FALLO", nombre, detalle])


func resumen_y_salir() -> void:
	print("\n=== %d comprobaciones, %d fallos ===\n" % [_ok + _fallos, _fallos])
	quit(1 if _fallos > 0 else 0)


## El jugador y los infectados se localizan por grupo, igual que en el juego.
func jugador() -> Node2D:
	var nodos: Array = get_nodes_in_group(&"player")
	return null if nodos.is_empty() else nodos[0] as Node2D


func infectados() -> Array:
	return get_nodes_in_group(&"infected")


## Saca a todos los infectados del mapa para aislar al que se está midiendo.
## Sin esto, la repulsión entre ellos contamina cualquier medida de posición.
func apartar_infectados() -> void:
	for infectado in infectados():
		(infectado as Node2D).global_position = Vector2(-5000, -5000)
