extends NavigationRegion2D
## Genera la malla de navegación del mundo a partir de los tiles, dejando
## holgura suficiente para que quepa el cuerpo de quien la recorre.
##
## Existe porque el polígono de navegación por tile llega hasta el filo mismo
## del muro. La ruta más corta sale entonces pegada a la pared, y un cuerpo con
## radio se queda empujando contra ella en perpendicular exacta — donde el
## deslizamiento de move_and_slide() vale cero y el infectado no avanza nunca.
## Encogiendo la malla, esa ruta deja de poder calcularse.
##
## OJO: el TileSet conserva su capa de navegación por tile, pero está apagada a
## propósito en la capa Ground. Ese polígono llega hasta el filo del muro y es
## exactamente lo que este nodo existe para evitar — así que **editarlo no tiene
## ningún efecto** mientras esto siga así. Se conserva, y no se borra, para poder
## volver atrás si algún día se descarta este enfoque.

## Capa que define dónde se puede pisar.
@export var ground_path: NodePath

## Capa de muros. Define el borde exterior del mundo y qué celdas se excluyen.
@export var walls_path: NodePath

## Holgura contra los muros, en píxeles. 26 es el radio del infectado (24) más
## 2 de margen: con holgura exactamente cero decide el coma flotante, y un solo
## píxel de solape reproduce el atasco entero.
@export var agent_radius: float = 26.0

# Tamaño de celda. Se lee del TileSet en lugar de escribirse aquí, para que no
# haya dos sitios que puedan discrepar el día que cambie.
var _tile: Vector2 = Vector2(32, 32)


func _ready() -> void:
	var ground := get_node_or_null(ground_path) as TileMapLayer
	var walls := get_node_or_null(walls_path) as TileMapLayer

	if ground == null or walls == null:
		push_error("NavigationBaker: faltan las capas de tiles; el mundo se queda sin navegación.")
		return

	if ground.tile_set != null:
		_tile = Vector2(ground.tile_set.tile_size)

	# Las dos superficies a la vez se solapan, y la del tile llega al filo del
	# muro: volverían las rutas pegadas a las esquinas sin que nada lo indicara.
	if ground.navigation_enabled:
		push_warning("NavigationBaker: '%s' tiene la navegación por tile encendida además de esta malla. Son dos superficies superpuestas y las rutas volverán a pegarse a los muros." % ground.name)

	navigation_polygon = _hornear(ground, walls)


## Un contorno transitable que abarca el mundo, y una obstrucción por cada
## celda que no se puede pisar. El horneado resta las segundas del primero y
## encoge el resultado en `agent_radius`.
func _hornear(ground: TileMapLayer, walls: TileMapLayer) -> NavigationPolygon:
	var geometria := NavigationMeshSourceGeometryData2D.new()

	# Los muros son el borde del mundo: lo que quede fuera de su rectángulo no
	# forma parte del nivel y no debe ser navegable.
	var mundo: Rect2i = walls.get_used_rect()
	geometria.add_traversable_outline(_contorno(mundo.position, mundo.end))

	for y in range(mundo.position.y, mundo.end.y):
		for x in range(mundo.position.x, mundo.end.x):
			var celda := Vector2i(x, y)
			if _es_pisable(ground, walls, celda):
				continue
			geometria.add_obstruction_outline(_contorno(celda, celda + Vector2i.ONE))

	var malla := NavigationPolygon.new()
	malla.agent_radius = agent_radius
	NavigationServer2D.bake_from_source_geometry_data(malla, geometria)
	return malla


## Tiene suelo y no tiene muro encima. Es la misma regla que ya rige el mapa:
## la capa Ground significa «dónde se puede estar», no «dónde pinté suelo».
func _es_pisable(ground: TileMapLayer, walls: TileMapLayer, celda: Vector2i) -> bool:
	return ground.get_cell_source_id(celda) != -1 and walls.get_cell_source_id(celda) == -1


## Rectángulo en píxeles a partir de dos esquinas expresadas en celdas.
func _contorno(desde: Vector2i, hasta: Vector2i) -> PackedVector2Array:
	var a := Vector2(desde) * _tile
	var b := Vector2(hasta) * _tile
	return PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
