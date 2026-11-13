extends Node2D
## Punto de entrada del mundo: crea el Player y los infectados sobre sus marcadores.
## World entry point: creates the Player and the infected on their markers.

# El mundo es el dueño de lo que vive en él: instancia las criaturas en tiempo..
# The world owns whatever lives in it: it instantiates creatures at runtime..

# ..de ejecución en vez de tenerlas colocadas a mano en la escena.
# ..instead of having them placed by hand in the scene.
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player/player.tscn")
const INFECTED_SCENE: PackedScene = preload("res://Scenes/Infected/infected.tscn")

@export_group("Perfiles de Infectados")
## Perfil de fase Alteración (fase temprana, desorientado).
@export var perfil_alteracion: InfectedProfile = preload("res://Resources/Infected/perfil_alteracion.tres")
## Perfil de fase Hostilidad (fase estándar de referencia).
@export var perfil_hostilidad: InfectedProfile = preload("res://Resources/Infected/perfil_hostilidad.tres")
## Perfil de fase Adaptación (cazador persistente).
@export var perfil_adaptacion: InfectedProfile = preload("res://Resources/Infected/perfil_adaptacion.tres")

@export_group("Generación y Probabilidades")
## Tabla de aparición de infectados por probabilidades ponderadas para este nivel/capítulo.
@export var spawn_table: SpawnTable = preload("res://Resources/World/tabla_default.tres")

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


func _spawn_player() -> Node2D:
	if not is_inside_tree():
		return null

	if _player_spawn == null:
		push_error("World: falta el nodo 'PlayerSpawn'; no se creó el Player.")
		return null

	var player := PLAYER_SCENE.instantiate() as Node2D
	player.player_died.connect(_on_player_died.bind(player))
	add_child(player)

	# Se posiciona DESPUÉS de add_child y con global_position (no position)..
	# Positioned AFTER add_child and with global_position (not position)..
	
	# ..para que el spawn sea correcto aunque World o PlayerSpawn tengan su propia transformación.
	# ..so the spawn is correct even if World or PlayerSpawn carry their own transform.
	player.global_position = _player_spawn.global_position
	return player


## Gestiona la muerte del Player: retira y destruye la instancia muerta de forma
## segura y crea un nuevo Player sobre el marcador de spawn en el siguiente frame.
func _on_player_died(dead_player: Node2D) -> void:
	if is_instance_valid(dead_player):
		dead_player.queue_free()

	_spawn_player.call_deferred()


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

		# Inyectar el perfil de fase ANTES de add_child para que _ready() inicialice con los datos finales.
		var perfil_asignado: InfectedProfile = _resolver_perfil_para_marcador(marcador)
		if infected.has_method("set_profile"):
			infected.set_profile(perfil_asignado)

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


## Resuelve qué perfil de fase corresponde a un marcador de spawn.
## 1. Comprueba si el marcador tiene override manual por metadato ("profile" o "fase").
## 2. Si no tiene metadato, consulta la tabla de aparición ponderada (spawn_table).
## 3. Si no hay tabla o está vacía, recurre al perfil de Hostilidad por defecto.
func _resolver_perfil_para_marcador(marcador: Marker2D) -> InfectedProfile:
	if marcador.has_meta("profile"):
		var meta_profile = marcador.get_meta("profile")
		if meta_profile is InfectedProfile:
			return meta_profile
		if meta_profile is String:
			match meta_profile.to_lower():
				"alteracion", "alteración":
					return perfil_alteracion
				"adaptacion", "adaptación":
					return perfil_adaptacion
				"hostilidad":
					return perfil_hostilidad

	if marcador.has_meta("fase"):
		var meta_fase: String = str(marcador.get_meta("fase")).to_lower()
		match meta_fase:
			"alteracion", "alteración":
				return perfil_alteracion
			"adaptacion", "adaptación":
				return perfil_adaptacion
			"hostilidad":
				return perfil_hostilidad

	# Si el marcador no tiene un metadato explícito, resuelve mediante la tabla ponderada
	if spawn_table != null:
		var perfil_seleccionado: InfectedProfile = spawn_table.pick_profile()
		if perfil_seleccionado != null:
			return perfil_seleccionado

	# Fallback seguro
	return perfil_hostilidad if perfil_hostilidad != null else perfil_alteracion


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
