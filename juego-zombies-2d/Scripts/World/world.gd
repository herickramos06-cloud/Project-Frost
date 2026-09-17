extends Node2D
## Punto de entrada del mundo: crea el Player y los infectados sobre sus marcadores.
## World entry point: creates the Player and the infected on their markers.

# El mundo es el dueño de lo que vive en él: instancia las criaturas en tiempo..
# The world owns whatever lives in it: it instantiates creatures at runtime..

# ..de ejecución en vez de tenerlas colocadas a mano en la escena.
# ..instead of having them placed by hand in the scene.
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player/player.tscn")
const INFECTED_SCENE: PackedScene = preload("res://Scenes/Infected/infected.tscn")

# Marcador que define dónde aparece el Player al iniciar el mundo.
# Marker that defines where the Player appears when the world starts.
@onready var _player_spawn: Marker2D = $PlayerSpawn

# Contenedor de marcadores: un infectado por cada hijo.
# Marker container: one infected per child.
@onready var _infected_spawns: Node2D = $InfectedSpawns

# Opcional a propósito: un mundo sin este nodo sigue funcionando, simplemente
# no se puede comprobar la holgura.
@onready var _navigation: NavigationRegion2D = get_node_or_null("Navigation") as NavigationRegion2D


func _ready() -> void:
	_spawn_player()
	_comprobar_holgura(_spawn_infected())


func _spawn_player() -> void:
	if _player_spawn == null:
		push_error("World: falta el nodo 'PlayerSpawn'; no se creó el Player.")
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	add_child(player)

	# Se posiciona DESPUÉS de add_child y con global_position (no position)..
	# Positioned AFTER add_child and with global_position (not position)..
	
	# ..para que el spawn sea correcto aunque World o PlayerSpawn tengan su propia transformación.
	# ..so the spawn is correct even if World or PlayerSpawn carry their own transform.
	
	
	player.global_position = _player_spawn.global_position


func _spawn_infected() -> Array[Node2D]:
	var creados: Array[Node2D] = []

	if _infected_spawns == null:
		push_error("World: falta el nodo 'InfectedSpawns'; no se creó ningún infectado.")
		return creados

	# Un infectado por cada marcador del contenedor. Añadir uno al nivel es..
	# One infected per marker in the container. Adding one to the level means..
	
	# ..duplicar un Marker2D en el editor: no hace falta tocar este código.
	# ..duplicating a Marker2D in the editor: this code needs no changes.
	
	for hijo in _infected_spawns.get_children():
		var marcador := hijo as Marker2D
		if marcador == null:
			push_warning("World: '%s' no es un Marker2D; se ignora." % hijo.name)
			continue

		var infected := INFECTED_SCENE.instantiate() as Node2D

		# El segundo argumento fuerza nombres legibles: Infected, Infected2,
		# The second argument forces readable names: Infected, Infected2,
		# Infected3... En lugar de @CharacterBody2D@2, que es lo que Godot
		# Infected3... instead of @CharacterBody2D@2, which is what Godot
		
		# genera por defecto y hace ilegible el árbol al depurar.
		# generates by default and makes the tree unreadable when debugging.
		
		add_child(infected, true)
		infected.global_position = marcador.global_position
		creados.append(infected)

	return creados


## La malla de navegación se encoge una distancia fija contra los muros, y los
## cuerpos que la recorren tienen su propio radio. Son dos números en dos
## archivos distintos y nada los ata: si el cuerpo pasa de la holgura, las rutas
## vuelven a salir pegadas al filo y el infectado se queda empujando contra la
## esquina sin avanzar.
##
## No rompe nada y no da error: produce un juego que funciona y se siente mal,
## que sólo se descubre jugando. Por eso se avisa al nacer.
func _comprobar_holgura(infectados: Array[Node2D]) -> void:
	if _navigation == null:
		return

	for infectado in infectados:
		var radio: float = _radio_ocupado(infectado)
		if radio <= _navigation.agent_radius:
			continue

		push_warning(
			"World: el cuerpo de '%s' ocupa %.0f px y la malla sólo deja %.0f px de holgura contra los muros. Las rutas se pegarán a las esquinas y se quedará atascado."
			% [infectado.name, radio, _navigation.agent_radius]
		)
		return


## Cuánto espacio libre necesita un cuerpo alrededor de su centro, en el peor
## eje. El horneado supone un agente circular, así que una cápsula alta pide su
## semieje mayor y no su radio: 48 px de ancho pero 80 de alto necesitan 40, no 24.
func _radio_ocupado(cuerpo: Node2D) -> float:
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
