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


func _ready() -> void:
	_spawn_player()
	_spawn_infected()


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


func _spawn_infected() -> void:
	if _infected_spawns == null:
		push_error("World: falta el nodo 'InfectedSpawns'; no se creó ningún infectado.")
		return

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
