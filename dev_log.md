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

## 2026-07-04

### Joystick Virtual (Etapa 1: Estructura e Interacción Base)
* **Sistema:** Interfaz de Usuario / Controles Táctiles (Android)
* **Decisión:** Implementar detección de toque y arrastre del Stick usando `_gui_input` nativo en el script de control, acoplado al área del nodo.
* **Motivo:** Evita cálculos redundantes de colisiones o posiciones globales al delegar la detección al propio árbol de UI (Control), dejando listo el sistema para control multitáctil independiente en fases posteriores.
* **Archivos:** [virtual_jostick.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/UI/virtual_jostick.gd) | [virtual_jostick.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/virtual_jostick.tscn) | [project.godot](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/project.godot)
* **Correcciones Realizadas:**
  1. **Anclas y offsets de UI:** Se corrigieron valores corruptos en `virtual_jostick.tscn` que enviaban el joystick fuera de la pantalla. Se restablecieron a la esquina inferior izquierda.
  2. **Emulación táctil:** Habilitada la opción `pointing/emulate_touch_from_mouse` para simular toques de Android con el ratón de PC.
  3. **Error de RefCounted:** Corregido el error de herencia nativa provocado por el archivo `virtual_jostick.gd` vacío, inicializando el script correctamente con `extends Control`.

## 2026-07-22

### Joystick Virtual (Etapa 2: Límite Radial y Consolidación de Escenas)
* **Sistema:** Interfaz de Usuario / Controles Táctiles (Android)
* **Decisión:** 
  1. Implementar restricción de movimiento del Stick para mantenerlo dentro del radio del joystick usando `Vector2.limit_length()`.
  2. Exponer un parámetro exportable `@export_range` (`max_radius_ratio`) para ajustar el rango máximo de desplazamiento.
  3. Consolidar el árbol de escenas eliminando los duplicados obsoletos de la raíz de `Scenes/` y migrando las dependencias de `main.tscn` a las subcarpetas correctas (`Scenes/Player/` y `Scenes/UI/`).
* **Motivo:** Lograr una sensación de control táctil profesional evitando que el stick salga de la base visual. Resolver la ambigüedad y confusión de desarrollo provocada por las escenas huérfanas/duplicadas en la estructura de archivos.
* **Archivos:** [virtual_jostick.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/UI/virtual_jostick.gd) | [main.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/main.tscn) | [player.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Player/player.tscn) | [virtual_jostick.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/UI/virtual_jostick.tscn)

---

### Joystick Virtual (Etapa 3: Integración y Desacoplamiento de Controles)
* **Sistema:** Entrada de Usuario / Arquitectura
* **Decisión:** Implementar un Autoload `InputManager` como intermediario neutro entre el emisor (`VirtualJoystick`) y el consumidor (`Player`).
* **Motivo:** Desacoplar la física del jugador de la interfaz gráfica y los métodos de captura específicos. Cumple con los principios de Responsabilidad Única (SRP) y Abierto/Cerrado (OCP).
* **Archivos:** [input_manager.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Core/input_manager.gd) | [player.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Player/player.gd) | [virtual_jostick.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/UI/virtual_jostick.gd)
* **Detalles y Correcciones:**
  1. **Simplificación Móvil (YAGNI):** Se removió el soporte de teclado redundante del InputManager, haciendo que responda estrictamente al joystick, confiando en la emulación de clic/toque en PC.
  2. **Resolución de Referencia a Autoload:** Se corrigió un bug donde el joystick verificaba la existencia del Autoload mediante `Engine.has_singleton("InputManager")`. Como los Autoloads no son singletons nativos de C++ sino nodos del árbol de escena, se removió la verificación para llamar al manager directamente, resolviendo el fallo de transmisión de datos.

---

## 2026-09-03

### Spawn Dinámico del Player (Instanciación desde World)
* **Sistema:** World / Ciclo de Vida del Player
* **Decisión:** Retirar el Player colocado a mano en `main.tscn` y hacer que `world.gd` lo instancie en `_ready()` a partir de `player.tscn`, posicionándolo sobre un `Marker2D` llamado `PlayerSpawn`.
* **Motivo:** El mundo pasa a ser el dueño del ciclo de vida del Player. El punto de aparición se vuelve un dato editable visualmente en el editor en lugar de una posición fija incrustada en la escena principal, lo que permite escalar a nuevos mundos y habitaciones sin duplicar el Player en cada escena.
* **Archivos:** [world.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/World/world.gd) | [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn) | [main.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/main.tscn)
* **Detalles y Correcciones:**
  1. **Nueva carpeta `Scripts/World/`:** Creada para alojar `world.gd`, siguiendo la convención temática ya establecida (`Scripts/Player/`, `Scripts/UI/`, `Scripts/Core/`).
  2. **Posicionamiento con `global_position`:** El Player se coloca *después* de `add_child()` y usando `global_position` (no `position`), para que el spawn siga siendo correcto aunque `World` o `PlayerSpawn` reciban su propia transformación en el futuro.
  3. **Repunte del target de cámara:** Al mover el Player dentro de `World`, la ruta `follow_target_path` de `CameraController` pasó de `"../Player"` a `"../World/Player"`.
  4. **Orden de nodos en `main.tscn`:** `World` se movió al primer lugar, por delante de `CameraController`. Godot ejecuta `_ready()` de los hijos en orden de árbol, así que `World` debe crear al Player *antes* de que la cámara resuelva su `NodePath`; de lo contrario `get_node()` falla y deja la cámara sin objetivo.
  5. **Cambio de velocidad heredado:** El nodo manual sobrescribía `speed = 400.0`. Al instanciarse desde `player.tscn`, el Player ahora usa el valor por defecto de `player.gd` (`450.0`). Aceptado; el parámetro sigue siendo editable desde el script o el inspector.
* **Verificación:** Ejecutado en Godot 4.6.2 headless. Player creado en `World/Player` sobre las coordenadas exactas de `PlayerSpawn` (comprobado tanto en la posición heredada `(362, 179)` como tras reubicar el marcador a `(78, 701)` desde el editor); movimiento vía `InputManager` funcional; colisiones confirmadas (empujado 3s contra los muros norte y oeste, se detuvo con `is_on_wall: true` en lugar de atravesarlos); cámara con distancia `0.0` al Player; sin errores en consola.

---

## Convenciones de Arquitectura

1. **Estructura de Carpetas:**
   * Todos los scripts de jugabilidad se guardan en subcarpetas temáticas de `Scripts/` (e.g., `Scripts/Player/`, `Scripts/UI/`).
   * Todas las escenas empaquetadas se guardan en subcarpetas temáticas de `Scenes/` (e.g., `Scenes/Player/`, `Scenes/UI/`).

2. **Control de Cámara:**
   * Las cámaras de seguimiento dinámico deben ser hermanas del objetivo (nunca hijas) para evitar bucles de transformaciones.
   * Usar siempre el suavizado nativo del motor (`position_smoothing`) en lugar de interpolaciones por código que entren en conflicto con el motor.

3. **Instanciación del Player:**
   * El Player nunca se coloca a mano en una escena de mundo. Cada mundo lo instancia desde `player.tscn` en su `_ready()` y lo posiciona sobre su `Marker2D` `PlayerSpawn`.
   * En `main.tscn`, `World` debe permanecer **antes** de `CameraController` en el árbol. Los nodos nuevos que se agreguen al final no rompen esta regla.

---

## Próximos Pasos

- [ ] Implementar Screen Shake dinámico al recibir daño o disparar.
- [ ] Configurar límites de pantalla de la cámara usando un TileMap.
- [x] Desarrollar sistema de Joystick Virtual para Android (Completado: Etapas 1, 2 y 3).
- [x] Spawn dinámico del Player desde `World` mediante `PlayerSpawn` (Marker2D).
- [ ] Crear IA de persecución para el primer infectado.
- [ ] **Pendiente antes del sistema de respawn:** `CameraController` resuelve su objetivo una sola vez en `_ready()`. Cuando exista muerte/respawn y el Player se destruya y se vuelva a crear, la cámara quedará apuntando a una referencia liberada. Habrá que hacer que el objetivo se reasigne (señal desde `World` o búsqueda por grupo).
