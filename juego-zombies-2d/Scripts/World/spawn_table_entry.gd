class_name SpawnTableEntry
extends Resource
## Entrada individual para una tabla de aparición de infectados.
## Asocia un perfil de comportamiento con un peso de probabilidad relativo.

## Perfil de comportamiento de esta entrada.
@export var profile: InfectedProfile

## Peso relativo de probabilidad. A mayor peso relativo, mayor probabilidad
## de selección. Valores menores o iguales a cero son ignorados.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
