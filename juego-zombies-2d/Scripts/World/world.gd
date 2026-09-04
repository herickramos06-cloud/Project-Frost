extends Node2D
## Punto de entrada del mundo: crea el Player y lo coloca sobre PlayerSpawn.
## World entry point: creates the Player and places it on PlayerSpawn.

# El mundo es el dueño del Player: lo instancia en tiempo de ejecución en vez
# The world owns the Player: it instantiates it at runtime instead of
# de tenerlo colocado a mano en la escena.
# having it placed by hand in the scene.
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player/player.tscn")

# Marcador que define dónde aparece el Player al iniciar el mundo.
# Marker that defines where the Player appears when the world starts.
@onready var _player_spawn: Marker2D = $PlayerSpawn


func _ready() -> void:
	_spawn_player()


func _spawn_player() -> void:
	if _player_spawn == null:
		push_error("World: falta el nodo 'PlayerSpawn'; no se creó el Player.")
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	add_child(player)

	# Se posiciona DESPUÉS de add_child y con global_position (no position)
	# Positioned AFTER add_child and with global_position (not position)
	# para que el spawn sea correcto aunque World o PlayerSpawn tengan
	# so the spawn is correct even if World or PlayerSpawn carry
	# su propia transformación.
	# their own transform.
	player.global_position = _player_spawn.global_position
