# PROJECT-FROST — Registro de Desarrollo (Dev Log)

Registro de decisiones de diseño, soluciones a problemas técnicos y convenciones del proyecto.

---

## 2026-06-03

### Movimiento del Jugador
* **Sistema:** Player Movement
* **Decisión:** Implementar `CharacterBody2D` y leer el movimiento en `_physics_process` usando `Input.get_vector()`.
* **Motivo:** Asegura un movimiento top-down uniforme en 8 direcciones con velocidad constante en diagonales. Prepara el terreno para el joystick virtual en Android.
* **Archivos:** [player.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/player.gd) | [player.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/player.tscn)
* **Configuración:** Controles WASD + Flechas. Velocidad base: `500.0 px/s`.

---

### Controlador de Cámara Modular (Diseño Inicial)
* **Sistema:** Camera Controller
* **Decisión:** Separar la cámara del nodo del jugador e instanciarla como hermano en la escena principal.
* **Motivo:** Desacoplar el comportamiento de la cámara del transform directo del jugador, facilitando efectos como zoom, screen shake y límites del mapa.
* **Archivos:** [camera_controller.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/camera_controller.gd) | [camera_controller.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/camera_controller.tscn) | [main.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/main.tscn)

---

## 2026-06-29

### Correcciones en la Cámara y Seguimiento

#### Problema 1: Bloqueo de Movimiento del Jugador
* **Síntoma:** El Player no se movía cuando la cámara estaba activa.
* **Causa Raíz:** La cámara estaba instanciada como hija del Player mientras su script intentaba posicionarla usando `global_position`. Esto generaba una referencia circular de transforms que anulaba el movimiento físico neto.
* **Solución:** Se extrajo la cámara para ser un nodo hermano del Player en [main.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/main.tscn).

#### Problema 2: Fallo de Asignación del Target (Cámara no seguía)
* **Síntoma:** La cámara se quedaba estática en el origen.
* **Causa Raíz:** La variable `@export var follow_target: Node2D` recibía un `NodePath` en el inspector del archivo `.tscn`, lo que causaba un fallo silencioso de asignación en runtime (dejando el target como `null`).
* **Solución:** Se cambió el export a `follow_target_path: NodePath` y se resolvió a nodo real en `_ready()` mediante `get_node()`.

#### Problema 3: Efecto Elástico o de "Resorte" (Rubber-Banding)
* **Síntoma:** Al desplazarse, el personaje se sentía amarrado y regresaba a la posición de origen.
* **Causa Raíz:** Conflicto de procesamiento entre la interpolación (`lerp`) manual hecha en `_process()` por código y la actualización del viewport del nodo `Camera2D` de Godot en C++.
* **Solución:** Se cambió la actualización de la cámara a `_physics_process()` para sincronizarla al frame exacto de las físicas del Player, delegando la interpolación al sistema nativo mediante `position_smoothing_enabled = true`.

---

## 2026-07-03

### Auditoría y Reparación de Referencias Rotas
* **Sistema:** Reorganización del Proyecto / Integridad de Recursos
* **Decisión:** Reparar y re-enlazar todas las dependencias y rutas rotas causadas por la reorganización de directorios sin alterar la lógica de juego ni eliminar los recursos duplicados.
* **Motivo:** Asegurar que el proyecto cargue y abra en Godot Engine 4.6 sin errores, permitiendo continuar con el flujo normal de desarrollo.
* **Archivos:** [main.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/main.tscn) | [player.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/player.tscn) | [camera_controller.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Player/camera_controller.tscn) | [virtual_jostick.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/UI/virtual_jostick.tscn)
* **Correcciones Realizadas:**
  1. Se actualizó la ruta a `camera_controller.tscn` en `main.tscn` a `res://Scenes/Player/camera_controller.tscn`.
  2. Se corrigió el script de control en las escenas `player.tscn` (raíz y subcarpeta) a `res://Scripts/Player/player.gd`.
  3. Se corrigió el script de control de cámara a `res://Scripts/Player/camera_controller.gd`.
  4. Se corrigió el script en ambas escenas de `virtual_jostick.tscn` a `res://Scripts/UI/virtual_jostick.gd`.
  5. Se re-enlazó la textura `base_placeholder.jpeg` en `Scenes/UI/virtual_jostick.tscn` a la ubicación correcta en `res://Assets/Placeholders/Base_Placeholder.jpeg`.

---

## Convenciones de Arquitectura

1. **Estructura de Carpetas:**
   * Todos los scripts de jugabilidad se guardan en subcarpetas temáticas de `Scripts/` (e.g., `Scripts/Player/`, `Scripts/UI/`).
   * Todas las escenas empaquetadas se guardan en subcarpetas temáticas de `Scenes/` (e.g., `Scenes/Player/`, `Scenes/UI/`).

2. **Control de Cámara:**
   * Las cámaras de seguimiento dinámico deben ser hermanas del objetivo (nunca hijas) para evitar bucles de transformaciones.
   * Usar siempre el suavizado nativo del motor (`position_smoothing`) en lugar de interpolaciones por código que entren en conflicto con el motor.

---

## Próximos Pasos

- [ ] Implementar Screen Shake dinámico al recibir daño o disparar.
- [ ] Configurar límites de pantalla de la cámara usando un TileMap.
- [ ] Desarrollar sistema de Joystick Virtual para Android.
- [ ] Crear IA de persecución para el primer infectado.
