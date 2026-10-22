extends Node
## Componente de salud. Gestiona puntos de vida, recepción de daño e
## invulnerabilidad temporal tras cada golpe.
##
## Se conecta al nodo padre mediante señales: el componente no sabe qué es su
## dueño ni qué hace al morir. Eso lo decide quien escuche `died`.

## Emitida cada vez que la salud cambia. Incluye el valor nuevo y el máximo
## para que un HUD futuro pueda pintar la barra sin preguntar nada más.
signal health_changed(current: float, maximum: float)

## Emitida una sola vez cuando la salud llega a cero. No se vuelve a emitir
## aunque se siga llamando a take_damage después.
signal died

## Salud máxima. Editable desde el inspector para poder ajustarla por perfil
## o por dificultad sin tocar código.
@export var max_health: float = 100.0

## Segundos de invulnerabilidad tras recibir un golpe. Impide que varias
## fuentes de daño simultáneas descuenten vida en el mismo instante.
## En 0.0 la invulnerabilidad está desactivada: el cooldown vive en el
## atacante, no en la víctima.
@export var invulnerability_duration: float = 0.0

var _current_health: float = 100.0
var _dead: bool = false
var _invulnerable: bool = false
var _invulnerability_timer: float = 0.0


func _ready() -> void:
	_current_health = max_health


func _physics_process(delta: float) -> void:
	if not _invulnerable:
		return
	_invulnerability_timer -= delta
	if _invulnerability_timer <= 0.0:
		_invulnerable = false


## Resta `amount` puntos de salud. Respeta la invulnerabilidad y no hace nada
## si ya está muerto. Devuelve true si el daño se aplicó.
func take_damage(amount: float) -> bool:
	if _dead or _invulnerable:
		return false

	_current_health = maxf(_current_health - amount, 0.0)
	health_changed.emit(_current_health, max_health)

	if invulnerability_duration > 0.0:
		_invulnerable = true
		_invulnerability_timer = invulnerability_duration

	if _current_health <= 0.0:
		_dead = true
		died.emit()

	return true


## Salud actual. Lectura externa sin exponer el campo.
func current_health() -> float:
	return _current_health


## Si ya ha muerto.
func is_dead() -> bool:
	return _dead


## Restaura la salud al máximo y levanta el flag de muerte.
## Pensado para el respawn de la tarea 4.2.
func reset() -> void:
	_dead = false
	_invulnerable = false
	_current_health = max_health
	health_changed.emit(_current_health, max_health)
