class_name InfectedProfile
extends Resource
## Perfil de fase de un infectado. Define las velocidades, radios, umbrales y
## decaimiento que configuran su comportamiento. Tres perfiles cubren el arco
## del GDD: Alteración (desorientado), Hostilidad (amenaza estándar) y
## Adaptación (cazador persistente).
##
## Es un Resource: se edita en el inspector, se guarda como .tres y se
## comparte entre todas las instancias de la misma fase sin coste adicional.
## El infectado lo recibe al nacer y nunca lo modifica.


@export_group("Identidad")

## Nombre legible de la fase, para depuración y UI futura.
@export var fase_nombre: String = ""


@export_group("Movimiento")

## Velocidad de persecución y carrera hacia la memoria, en píxeles por segundo.
@export var speed: float = 220.0

## Velocidad de investigación en estado Alerta.
@export var alert_speed: float = 70.0

## Velocidad de deambulación en Rutina y registro local en Búsqueda.
@export var wander_speed: float = 120.0

## Límite de giro de la mirada, en grados por segundo.
@export var turn_speed: float = 150.0


@export_group("Percepción")

## Alcance máximo del cono de visión, en píxeles.
@export var vision_radius: float = 190.0

## Apertura total del cono de visión, en grados.
@export_range(10.0, 360.0, 5.0) var vision_angle: float = 100.0

## Radio de detección a 360° (a quemarropa), en píxeles.
@export var close_radius: float = 64.0


@export_group("Merodeo")

## Radio máximo de cada salto de merodeo, en píxeles.
@export var wander_radius: float = 350.0

## Duración base de la parada de inspección entre saltos, en segundos.
@export var wander_pause: float = 1.0


@export_group("Persistencia")

## Tiempo de búsqueda tras perder al jugador, en segundos.
@export var search_duration: float = 8.0

## Decaimiento de agitación por segundo sin estímulos.
@export var agitacion_decaimiento: float = 0.08


@export_group("Combate")

## Daño por impacto al jugador.
@export var damage_amount: float = 20.0

## Segundos entre golpes consecutivos.
@export var attack_cooldown: float = 1.0


@export_group("Reglas de fase")

## Estado máximo al que puede escalar este perfil.
## 0 = RUTINA, 1 = ALERTA, 2 = PERSECUCION.
## La lógica que lo aplica pertenece a la tarea 5.2.
@export_range(0, 2) var max_estado: int = 2

