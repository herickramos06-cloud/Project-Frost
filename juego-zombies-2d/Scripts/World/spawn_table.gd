class_name SpawnTable
extends Resource
## Tabla de aparición de infectados por probabilidades ponderadas.
## Define qué perfiles de comportamiento aparecen en un mapa, zona o capítulo,
## permitiendo balancear y escalar la dificultad mediante Resources sin tocar código.

## Lista de entradas ponderadas (perfil + peso) que componen la tabla.
@export var entries: Array[SpawnTableEntry] = []


## Selecciona aleatoriamente un perfil según los pesos relativos de las entradas.
## Retorna null si la tabla está vacía, no tiene entradas válidas o la suma de pesos es <= 0.
func pick_profile() -> InfectedProfile:
	if entries.is_empty():
		return null

	var peso_total: float = 0.0
	for entry in entries:
		if entry != null and entry.profile != null:
			peso_total += maxf(entry.weight, 0.0)

	if peso_total <= 0.0:
		return null

	var tirada: float = randf() * peso_total
	var acumulado: float = 0.0

	for entry in entries:
		if entry == null or entry.profile == null:
			continue
		var peso_valido: float = maxf(entry.weight, 0.0)
		if peso_valido <= 0.0:
			continue
		acumulado += peso_valido
		if tirada <= acumulado:
			return entry.profile

	# Respaldo defensivo ante ligeras discrepancias de precisión en punto flotante
	for i in range(entries.size() - 1, -1, -1):
		var e: SpawnTableEntry = entries[i]
		if e != null and e.profile != null and e.weight > 0.0:
			return e.profile

	return null
