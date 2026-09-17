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

## 2026-09-04

### Fondo del Mundo y Respaldo de la Documentación
* **Sistema:** Render / Cámara / Documentación
* **Decisión:**
  1. Definir `default_clear_color` en `#070d14` —el "negro profundo" de la paleta del GDD §07— para el área situada fuera del mapa.
  2. **Aplazar** la configuración de los límites de cámara hasta que exista el mapa del Capítulo 1.
  3. Incorporar al control de versiones la bitácora y el dev dashboard, que hasta ahora quedaban fuera del repositorio.
* **Motivo:** La cámara siempre se centra en el Player, así que al acercarse a cualquier muro encuadraba zonas sin tiles pintados y mostraba el gris por defecto de Godot, con aspecto de error. Había dos soluciones posibles: limitar la cámara con `set_map_limits()` o pintar el fondo. La habitación actual mide 1344 × 768 px contra un viewport de 1280 × 720, es decir **apenas 64 px de recorrido horizontal**; cualquier límite correcto dejaría la cámara prácticamente estática. Como el cuarto es provisional y el mapa del Capítulo 1 será mucho mayor, limitar hoy resolvería bien un problema que todavía no existe y a cambio congelaría la cámara. El color de fondo elimina el defecto visual **sin imponer ninguna restricción a la cámara** y sigue siendo válido cuando el mapa crezca. En cuanto a la documentación, sólo el GDD estaba versionado: el dashboard permanecía sin rastrear y la bitácora vivía en la carpeta de descargas, de modo que un fallo de disco se habría llevado ambos.
* **Archivos:** [project.godot](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/project.godot) | [bitacora.md](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/docs/bitacora.md) | [antesala_dev_dashboard.html](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/docs/gdd/antesala_dev_dashboard.html)
* **Detalles y Correcciones:**
  1. **Lectura del borde del mapa:** El área exterior deja de leerse como un fallo de render y pasa a leerse como oscuridad, coherente con el GDD §07 ("las zonas oscuras son más peligrosas") y con la ambientación de una base sin iluminar.
  2. **`set_map_limits()` sigue sin llamador** en `camera_controller.gd`. Se aplicará cuando el mapa del Capítulo 1 exista; como el rectángulo se calcularía con `get_used_rect()`, el código servirá para cualquier tamaño sin ajustar números a mano.
  3. **Ubicación de la documentación:** La bitácora se traslada a `docs/bitacora.md` y el dashboard pierde el sufijo de descarga duplicada de su nombre de archivo, ajustándose a la convención de minúsculas con guion bajo que ya usaba el GDD.
* **Verificación:** Godot 4.6.2 headless: `ProjectSettings` devuelve `#070d14` y `RenderingServer.get_default_clear_color()` confirma el mismo valor. `git ls-files docs` lista los tres documentos rastreados.

---

## 2026-09-06

### Limpieza del Suelo bajo los Muros (preparación para la navegación)
* **Sistema:** Mundo / Navegación
* **Decisión:** Borrar de la capa `Ground` las 123 celdas que quedaban pintadas debajo de los muros, de modo que la capa pase a significar "dónde se puede estar" y no "dónde pinté suelo".
* **Motivo:** En Godot la colisión y la navegación son **dos sistemas independientes que no se validan entre sí**. El navmesh se genera a partir de los tiles marcados como pisables, así que al añadir el polígono de navegación al tile de suelo la zona caminable habría cubierto también el área bajo los muros. La colisión seguiría intacta, de forma que el infectado no atravesaría la pared: calcularía una ruta que pasa por dentro del muro, caminaría hacia allí y se quedaría restregándose contra él. Es un fallo caro de diagnosticar porque la IA, la colisión y el mapa parecen correctos por separado. Con el suelo limpio el navmesh queda correcto por construcción, sin sistemas paralelos que mantener sincronizados.
* **Archivos:** [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn)
* **Detalles y Correcciones:**
  1. **Sin impacto visual:** Se comprobó que el tile de muro `(1,0)` es totalmente opaco —1024 de 1024 píxeles—, así que ese suelo nunca fue visible. La colisión no se tocó: vive en la capa `Walls`.
  2. **Edición quirúrgica:** Se sustituyó únicamente la línea `tile_map_data` del nodo `Ground`, dejando el resto del archivo byte a byte idéntico. No se volvió a guardar la escena completa, para no alterar los `unique_id` ni el resto de propiedades.
  3. **Regla de dibujo para el mapa del Capítulo 1:** no pintar suelo bajo un muro **sólido y opaco**. Las rejas, cristales o paredes rotas sí lo necesitan, porque se ve a través de ellas.
  4. **Ventaja secundaria:** ocultar la capa `Walls` en el editor muestra ahora la zona caminable como una silueta, con los muros como agujeros. Es una vista de depuración gratuita para cualquier fallo de navegación futuro.
* **Verificación:** Godot 4.6.2 headless. `Ground` pasa de 2697 a 2574 celdas (123 borradas, aritmética cuadrada) y quedan **0 muros con suelo debajo**. Integridad de la escena confirmada: script en la raíz, `PlayerSpawn` en `(78, 701)`, ambos TileSet enlazados, 3 hijos. Regresión completa del juego: el Player aparece sobre el spawn, la cámara lo sigue y los muros siguen bloqueando con valores idénticos a los previos al cambio (izquierda 32,5 px frente a 32,46; abajo 18,0 frente a 18,01).

---

## 2026-09-09

### Navegación del Mundo, Velocidad del Player y GDD v2
* **Sistema:** Navegación / Player / Documentación
* **Decisión:**
  1. Añadir una capa de navegación al TileSet y pintar el polígono navegable en el tile de suelo `(0,0)`, dejando el tile de muro `(1,0)` sin polígono.
  2. Fijar la velocidad del Player en **180 px/s** (antes 450).
  3. Redactar un **GDD v2** como documento nuevo, sin modificar el v1.
* **Motivo:** El TileSet no tenía ninguna capa de navegación, así que un `NavigationAgent2D` no habría tenido por dónde caminar: es el prerrequisito duro de todo el sistema de infectados. Sobre la velocidad, las cifras del GDD v1 se escribieron antes de que existieran los tiles; con un jugador de 52 px sobre tiles de 32, 450 px/s equivalía a 14 tiles por segundo y arrastraba la sensación al terreno arcade. 180 px/s conserva las proporciones del v1 subiendo la escala ~1,5×. El GDD v2 se crea aparte porque el v1 es el documento fundacional del universo y no debe corregirse: manda el v1 en identidad y lore, y el v2 en diseño, técnica y negocio.
* **Archivos:** [Laboratory_tileset.tres](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Assets/Tiles/Laboratory_tileset.tres) | [player.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Player/player.gd) | [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn) | [gdd_v2_antesala_2032.html](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/docs/gdd/gdd_v2_antesala_2032.html)
* **Detalles y Correcciones:**
  1. **Capa duplicada eliminada:** se crearon dos capas de navegación por error y se retiró la segunda, que quedaba vacía. Se comprobó antes que el polígono vivía en la capa 0.
  2. **UID restaurados a mano:** `ResourceSaver.save()` reescribió el `.tres` sin las líneas `uid://`, tanto la del propio recurso como la de la textura. Como `world.tscn` referencia el TileSet por UID, se restauraron ambas manualmente. **Conviene recordarlo antes de volver a guardar un recurso por código.**
  3. **`world.tscn` reserializado:** al cambiar el TileSet, Godot reescribió la línea `tile_map_data` de `Ground`. Verificado que no se perdió ni una celda: 2574 totales, 880 válidas, 1694 huérfanas y 0 muros con suelo debajo, idéntico a antes.
* **Verificación:** Godot 4.6.2. Polígono de 1024 px² sobre el tile `(0,0)` —el cuadrado completo— y tile de muro sin polígono. Agente de prueba sin lógica de IA: ruta de **51 puntos** de `(78, 701)` a `(1150, 120)`, recorrido real de **1289,6 px** frente a 1219,3 px en línea recta (rodea geometría), y **0,0 px de error** al llegar.

#### Lección: el mapa de navegación no está listo al arrancar
* **Síntoma:** Toda consulta de ruta devolvía vacío y `map_get_closest_point()` respondía `(0,0)` para cualquier punto, dando la impresión de que no existía superficie navegable.
* **Causa Raíz:** El servidor de navegación necesita varios fotogramas de física para sincronizar el mapa. Antes de eso responde `(0,0)`, que **parece «aquí no hay nada» cuando significa «todavía no sé dónde estás»**. La creencia extendida de que basta un fotograma es falsa: en este proyecto el mapa quedó operativo en el **fotograma 16**, y en hardware más lento pueden ser más.
* **Solución:** No contar fotogramas. Antes de la primera consulta, preguntar al mapa cuál es el punto navegable más cercano al agente: si devuelve la posición del propio agente, el mapa está listo; si devuelve `(0,0)`, todavía no. Esta regla debe aplicarse en el `infected.gd` del Hito 009.
* **Notas de diagnóstico:** dos falsas pistas costaron tiempo y quedan registradas para no repetirlas. `region_get_connections_count()` devolvía 0 y se interpretó como «regiones aisladas»: no lo eran, esa función cuenta otra cosa. Y `NavigationAgent2D` calcula la ruta de forma **asíncrona**, así que leer `get_current_navigation_path()` en el fotograma siguiente a asignar `target_position` devuelve vacío aunque todo esté bien.

---

## 2026-09-13

### Fase 1 — Bloque 1: El Cuerpo del Infectado (tareas 1.1 a 1.4)
* **Sistema:** Infectados / Navegación / Física
* **Decisión:**
  1. **1.1** — `infected.tscn` con `CharacterBody2D`, cápsula de radio 24 y alto 80, `Sprite2D` y `NavigationAgent2D`.
  2. **1.2** — Un **contenedor** `InfectedSpawns` en `world.tscn` con varios `Marker2D` dentro, y `world.gd` creando un infectado por cada hijo. No un marcador único.
  3. **1.3** — `infected.gd` con velocidad exportada de 220 px/s, espera a la sincronización del mapa, navegación hasta un punto fijo y recálculo de ruta escalonado.
  4. **1.4** — Capas de colisión repartidas (1 Mundo, 2 Player, 3 Infectados) y **repulsión suave** entre infectados en lugar de colisión física.
* **Motivo:** El contenedor se eligió porque el objetivo de densidad del GDD es de 4 a 10 infectados simultáneos, y un marcador único no puede darlo. Con él, **añadir un infectado al nivel es duplicar un `Marker2D` en el editor**: el código no se toca nunca más, ni para tres ni para veinte. Las capas se repartieron para que los infectados choquen con los muros pero atraviesen al jugador y entre sí — el daño irá por zona de detección, porque un enemigo que te empuja fuera de una puerta en plena huida se siente injusto. La repulsión se implementó a mano y no con la evitación del `NavigationAgent2D`: esa última cuesta más y hace que los infectados **se esquiven con cortesía**, que es tonalmente lo contrario de lo que pide el juego.
* **Archivos:** [infected.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Infected/infected.gd) | [infected.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Infected/infected.tscn) | [world.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/World/world.gd) | [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn) | [player.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Player/player.tscn) | [project.godot](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/project.godot)
* **Detalles y Correcciones:**
  1. **Nombres legibles al instanciar:** `add_child(nodo)` bautizaba al segundo y al tercer infectado como `@CharacterBody2D@2` y `@CharacterBody2D@3`. Se pasó a `add_child(nodo, true)`, que genera `Infected`, `Infected2`, `Infected3`. No afecta al funcionamiento, pero hace el árbol legible al depurar — y en el teléfono eso importa.
  2. **Capas con nombre en `project.godot`:** el panel de colisión del editor deja de mostrar dieciséis casillas numeradas. Ojo con los valores: la capa 3 se escribe como `4`, porque son bits.
  3. **El destino es un `@export`:** los tres infectados comparten el mismo por defecto, así que convergen. Es un artefacto de la prueba, no del diseño; dando a cada marcador un destino distinto se separan.
  4. **Los números de separación son provisionales.** El radio de 48 px sale de la geometría (dos cápsulas de radio 24 se tocan ahí), pero la fuerza de 60 px/s está elegida a ojo y **hay que validarla en dispositivo**.
* **Verificación:** Godot 4.6.2 headless, cuatro pasadas.
  * **Aparición:** los tres infectados sobre sus marcadores, todos sobre suelo válido y sobre la malla de navegación, con su agente presente.
  * **Navegación:** rutas de 38, 20 y 35 puntos; recorridos de 945, 504 y 928 px hacia el objetivo. **Cero incursiones en celda de muro** comprobando la capa `Walls` bajo cada infectado en cada uno de 900 fotogramas.
  * **Recálculo escalonado:** 40 emisiones de `path_changed` en 10 segundos por infectado — exactamente 4 por segundo, frente a las 600 que habría con recálculo por fotograma. **Quince veces menos trabajo.** Las tres cuentas atrás medidas en el mismo instante daban valores distintos, confirmando el desfase.
  * **Capas y repulsión:** Player en capa 2, infectados en capa 4, ambos con máscara 1. Los tres llegan al destino (antes dos se quedaban a 60 y 47 px empujándose) y la distancia mínima entre ellos nunca bajó de 8 px.

#### Lección 1: corrección sobre el tiempo de sincronización de la navegación
* **Qué se creía:** la entrada del 6 de septiembre registró que el mapa de navegación tardaba **16 fotogramas** en estar operativo.
* **Qué es cierto:** esa medición se hizo con un arnés de pruebas que instanciaba el mundo dentro de otra escena. **En el juego real, cargado con normalidad, el mapa sincroniza en el fotograma 3.**
* **Por qué importa:** el número **cambia según el contexto y el dispositivo**, así que nunca debe estar escrito en el código. Esto valida por partida doble la decisión de no contar fotogramas.
* **Solución adoptada:** `NavigationServer2D.map_get_iteration_id()` vale 0 hasta la primera sincronización. Es una pregunta directa al servidor —*¿has sincronizado ya?*— en lugar de inferirlo de un síntoma, y evita por completo tener que interpretar el `(0,0)`.
* **Nota de diagnóstico:** Godot **emite un error explícito** en estos casos: `NavigationServer navigation map query failed because it was made before first map synchronization`. Durante la depuración del 9 de septiembre se filtró la salida de consola buscando sólo los `print` propios y ese mensaje se perdió — era exactamente el diagnóstico que costó seis intentos deducir. **No filtrar la consola cuando algo no funciona.**

#### Lección 2: el radio de llegada debe ser mayor que el de separación
* **Síntoma:** al llegar al destino, los infectados rebotaban en el sitio indefinidamente.
* **Causa Raíz:** la tolerancia de llegada del `NavigationAgent2D` es de 10 px por defecto y el radio de separación es de 48. El bucle: llego → la repulsión me empuja 20 o 30 px → ya estoy a más de 10 px → «no he llegado» → vuelvo a caminar → me empuja otra vez. Dos números peleándose, uno diciendo «acércate» y el otro «apártate».
* **Solución:** `target_desired_distance` se deriva del radio de separación (`separation_radius * 1.25`) en lugar de escribirse suelto, **para que la relación no se rompa sola** el día que se ajuste la separación.
* **Por qué importa más allá de esta prueba:** en el Bloque 2 el destino será el Player, y varios infectados rodeándolo habrían producido el mismo temblor permanente — mezclado con percepción, persecución y máquina de estados, y por tanto mucho más difícil de diagnosticar.
* **Verificación:** **0,0 px de movimiento** en los tres durante los últimos 10 segundos, con la navegación marcada como terminada y una distribución en corona alrededor del punto.

---

## 2026-09-14

### Fase 1 — Bloque 2: El Cerebro del Infectado (tareas 2.1 a 2.4)
* **Sistema:** Infectados / Percepción / Máquina de estados
* **Decisión:**
  1. **2.1** — Máquina de estados **plana**: un `enum` y un `match` en el mismo script. Rutina, Persecución y Búsqueda. Ni un nodo por estado, ni árbol de comportamiento, ni IA por utilidad.
  2. **2.2** — Detección por **distancia pura** a 224 px (siete tiles). Sin cono, sin línea de visión, sin detección de movimiento. Ve a través de las paredes a propósito.
  3. **2.3** — **Memoria de última posición conocida** con 8 segundos de insistencia, guardada como copia del `Vector2` y no como referencia al Player.
  4. **2.4** — Volver a la rutina **desde donde esté**, sin punto de origen al que regresar.
* **Motivo:** La máquina plana se eligió porque con tres o cuatro conductas un nodo por estado es más ceremonia que ayuda, y porque el blueprint ya prevé que la complejidad real viva en el **medidor de agitación** del Bloque 3, no en la estructura de estados. La detección tosca es deliberada: la gracia de este bloque es que **algo te persiga por primera vez**, y meter raycast y conos a la vez impide saber cuál de las dos piezas falla cuando algo se sienta mal. La memoria entra desde el primer día porque sin ella la IA sólo puede ser clarividente —sabe siempre dónde estás— o amnésica —te olvida al instante—, y **las dos rompen el sigilo**.
* **Archivos:** [infected.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Infected/infected.gd) | [player.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Player/player.gd)
* **Detalles y Correcciones:**
  1. **Perseguir no tiene llegada.** El plan original paraba al alcanzar la tolerancia del agente, que son 60 px: **dos cuerpos**. El infectado habría corrido hacia el jugador para quedarse plantado a dos pasos sin tocarlo nunca. Cada conducta declara ahora si se detiene al llegar; Búsqueda sí, Persecución no.
  2. **Un solo dato de memoria.** Memoria y destino de búsqueda son la misma cosa. Separarlos en dos campos habría roto en silencio la comprobación de llegada que 2.1 ya tenía funcionando.
  3. **Cambiar de estado ya no fuerza recálculo de ruta.** El jugador quieto en el borde del radio hace entrar y salir de persecución cada fotograma; forzar un recálculo en cada cambio son **60 por segundo en vez de 4**, exactamente el ×15 que la tarea 1.3.5 existía para evitar. El temporizador es la única autoridad.
  4. **Perder al Player estando en Persecución lleva a Búsqueda.** Persecución no tiene temporizador de salida: sin esta transición, que el Player desaparezca del árbol dejaba al infectado clavado para siempre.
  5. **El Player se localiza por grupo, nunca por referencia guardada.** `is_instance_valid()` devuelve `true` para un nodo sacado del árbol pero no liberado, y con él se leería una posición obsoleta. El grupo deja de contenerlo en cuanto sale del árbol. El coste —una consulta por infectado y fotograma— está muy por debajo del bucle que la separación ya paga contra todos los demás.
  6. **Eliminados `estado_inicial` y `target_point`.** Restos de 2.1. Arrancar en Persecución sin memoria escrita manda al infectado a `(0,0)`.
  7. **`search_duration` de 5 a 8 segundos**, que es el valor de la fila «Hostilidad» del GDD. Un número del código no debe contradecir al documento de diseño.
  8. **Un solo punto del script sabe que el Player existe.** Cuando llegue la línea de visión del Bloque 3, se toca ahí y en ningún otro sitio.
* **Verificación:** Godot 4.6.2 headless, **26 comprobaciones, 0 fallos**, sobre el mundo real cargado como escena.
  * **Arranque:** los tres infectados en Rutina, sin memoria y con **0,00 px** de movimiento durante 60 fotogramas.
  * **Persecución:** entra en Persecución al cruzar el radio y se planta a **1,7 px** del jugador — no a los 60 px de la tolerancia del agente, que es lo que habría pasado con el plan original.
  * **Memoria:** al perder al jugador, la memoria queda congelada a **1132 px** de su posición real. Recorre 143 px hasta el punto recordado y se rinde en **0,65 s por llegada**, no por agotar los 8 s.
  * **Coste del recálculo:** oscilando **120 veces en 2 segundos** en el borde del radio, se registraron **7 recálculos**. Sin control habrían sido 120.
  * **Player fuera del árbol:** sale de Persecución en 3 fotogramas en lugar de quedarse clavado.
  * `main.tscn` arranca limpio, 300 fotogramas, sin un solo error en consola.

#### Lección 3: revisar el plan sale más barato que revisar el código
* **Qué pasó:** antes de escribir una línea del Bloque 2, el plan pasó por tres revisiones independientes. Salieron **26 problemas**: 9 graves, 11 medios y 6 menores. Siete se corrigieron en el plan, cuatro se rechazaron por optimización prematura o por no pertenecer a este bloque, y el resto quedaron aplazados con un bloque concreto asignado.
* **Por qué importa:** los tres hallazgos graves de verdad —la persecución que se aparca, los dos campos de memoria y el recálculo forzado— **no los habría cazado ninguna prueba automática**. Ninguno rompe nada: los tres producen un juego que funciona y se siente mal. Eso sólo se detecta leyendo el plan o jugando mucho después.
* **El que faltó:** un octavo problema apareció **probando**, no revisando. Hasta el primer recálculo, el `target_position` del agente vale `(0,0)`, que no significa «la esquina del mapa» sino «todavía nada»; el infectado caminaba hacia ahí hasta un cuarto de segundo. Ahora no se mueve hasta tener ruta entregada, y esa pausa se lee como tiempo de reacción.
* **Trampa de verificación:** la primera versión de la prueba de arranque daba verde **recorriendo una lista vacía**. El `add_child` había fallado dentro de `_ready()` —el nodo raíz todavía estaba montando la escena— y no había infectados que comprobar. Corregido con una comprobación explícita de que existen los tres. **Una prueba que no puede fallar no es una prueba.**

#### Límite conocido: Búsqueda no es alcanzable jugando todavía
* **Qué pasa:** en la habitación actual, un rectángulo vacío, **no se puede despistar a un infectado**. El infectado va a 220 px/s y el jugador camina a 180, así que la distancia sólo puede encogerse; y aunque la línea de visión existiera, no hay nada tras lo que esconderse.
* **Los números:** la diagonal de la habitación son 1548 px, cruzarla entera lleva 8,6 s caminando, y en ese tiempo el infectado recorta 344 px. Aunque la detección se rompiera justo en el límite de los 224 px, alcanza al jugador antes de que llegue al otro extremo.
* **Estado real:** Búsqueda está construida y verificada, pero hoy **sólo se alcanza forzándola**. No es una mecánica jugable todavía.
* **Cuándo se levanta:** con la **línea de visión del Bloque 3**, que hace que un muro salve, y con el **correr a 320 px/s del Hito 010**, que permite abrir distancia. Está anotado como límite en el roadmap, no como pieza terminada.

---

## 2026-09-16

### Fase 1 — Bloque 3: Los Sentidos (tareas 3.0 y 3.1a)
* **Sistema:** Mundo / Infectados / Percepción
* **Decisión:**
  1. **3.0** — Tallar geometría interior en la habitación: un bloque macizo de 29 × 6 celdas, un pasillo norte de 3 celdas de alto con una entrada de 5, y una alcoba al fondo.
  2. **3.1a** — `_percibir()` pasa de dos preguntas a tres: existe el Player, está dentro del radio, y **hay una pared en medio**. Un rayo contra la capa 1, y sólo contra la capa 1.
* **Motivo:** El criterio de verificación del Bloque 3 es *«esconderte tras un muro te salva»*, y la habitación era un rectángulo vacío — 128 celdas de muro, **todas de perímetro, cero interiores**. No había nada tras lo que esconderse, así que ni la línea de visión ni el cono ni la detección por movimiento se podían verificar jugando. Se empieza por lo que no es inteligencia artificial, igual que el Paso 0 del blueprint. Sobre 3.1a: la tarea 2.2.2 dejó escrito que un solo punto del script sabe que el Player existe, precisamente para que este cambio cupiera en un sitio.
* **Archivos:** [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn) | [infected.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/Infected/infected.gd) | [player.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Player/player.tscn)
* **Detalles y Correcciones:**
  1. **El mapa pasa a ser una U con un apéndice.** De 128 a 226 celdas de muro, 109 de ellas interiores, y 753 celdas pisables. No hay atajos: la **única** ruta entre la sala norte y la sala sur es el pasillo izquierdo. Cero suelo bajo muro, comprobado antes de seguir.
  2. **El hueco de 5 celdas del muro norte es deliberado.** Da a un pasillo estrecho con un infectado justo al otro lado de la pared: es el banco de pruebas de la línea de visión y a la vez terreno de juego.
  3. **La distancia se comprueba antes que el rayo.** Es el filtro barato: con el jugador fuera del radio no se lanza ni una consulta. Medido: **0 rayos en 300 fotogramas** a 800 px, y **exactamente uno por fotograma** dentro del radio.
  4. **La máscara es sólo la capa 1.** Si incluyera la 2, el infectado se cegaría contra el propio jugador al que apunta; si incluyera la 4, uno plantado delante de otro le taparía la vista al de atrás.
  5. **Consulta directa al espacio físico, sin nodo `RayCast2D`.** El objetivo se mueve, así que habría que reescribir su `target_position` cada fotograma de todas formas, y `force_raycast_update()` cuesta lo mismo. Un nodo menos por infectado, que en Android cuenta.
  6. **Desplazamiento de la cápsula del Player corregido a (0,0).** Estaba a (7,9) y se rechazó en la revisión del Bloque 2 por ser arte y no IA — pero al apuntar rayos al centro del cuerpo dejó de serlo. Verificado: el Player se detiene en **x = 58** contra el muro oeste (32 + radio 26) y en **y = 691,9** contra el sur (736 − semialtura 44). Exacto en los dos ejes.
  7. **Los dos rayos laterales (3.1b) quedan sin construir.** Se decidió un solo rayo al centro: la fantasía de asomarse sin que te vean la va a dar 3.3 con la detección por movimiento, que es una regla que el jugador controla, no una frontera invisible.
* **Verificación:** Godot 4.6.2 headless, sobre el mundo real cargado como escena.
  * **Par controlado:** sin muro a **208 px** detecta; con muro a **192,7 px** no detecta. Las dos dentro del radio de 224, así que lo único que cambia entre ellas es la pared.
  * **Los cuerpos no tapan:** tres infectados alineados a 100, 160 y 210 px del jugador — **los tres detectan**.
  * **La memoria se congela:** ve al jugador en (700, 176), se tapa, y la memoria se queda ahí mientras el jugador está realmente a **197 px**. Es la primera demostración de la memoria construida el 14 de septiembre.
  * **Tras la pared: 0,00 px de movimiento** en 3 s. A la vista: recorre 209 px y se planta a **1,0 px**.
  * `main.tscn`, 300 fotogramas: **2 líneas de salida en total**, cero errores, sin filtrar la consola.

---

### Bloque 1.5 — Rutas con holgura (el fallo que destapó el mapa de 3.0)
* **Sistema:** Navegación / Mundo
* **Decisión:** Dejar de generar la malla de navegación tile a tile y **hornear una sola malla para todo el mundo, encogida 26 px respecto a los muros**, en tiempo de ejecución al cargar el nivel. Y cambiar el cuerpo del infectado de cápsula 48 × 80 a **círculo de radio 24**.
* **Motivo:** Al probar 3.0 aparecieron infectados clavados en las esquinas. La causa no era percepción ni memoria: **la navegación de Godot calcula la ruta como si el agente fuera un punto sin cuerpo**, así que la ruta más corta sale pegada al filo del muro. Un cuerpo de 48 px de ancho que la sigue mete medio cuerpo en la pared, empuja en perpendicular exacta, y `move_and_slide()` no puede deslizar — deslizar consiste en restar la componente contra el muro, y si toda la velocidad va contra el muro lo que queda es cero. El infectado pide la misma dirección imposible para siempre.
* **Archivos:** [navigation_baker.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/World/navigation_baker.gd) | [world.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/World/world.tscn) | [world.gd](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scripts/World/world.gd) | [infected.tscn](file:///c:/Users/HERICK/Desktop/PROJECT-FROST/juego-zombies-2d/Scenes/Infected/infected.tscn)
* **Detalles y Correcciones:**
  1. **El diagnóstico se hizo descartando, no adivinando.** El radio del cuerpo **no** era la causa: con radio 14 en vez de 24 las rutas fallaban **en el mismo píxel y con el mismo decimal** (472,3 · 839,6 · 726,1). El post-proceso `EDGECENTERED` de Godot lo **empeoraba**. Y con memoria infinita se atascaba igual, así que tampoco era el olvido.
  2. **No era cosa de sitios estrechos, era cosa de esquinas.** También se clavaba en la esquina del bloque central, donde el pasillo mide 10 celdas de ancho — y esa esquina está en la única ruta que une las dos mitades del mapa.
  3. **Sólo se liberaba si el jugador caminaba hacia él.** Quieto: atascado. Alejándose: atascado. Acercándose: se libera en 8,6 s. Los dos casos que fallan son **esconderse y huir**, que son las dos únicas cosas que hace un jugador de sigilo — y quedarse quieto va a ser la mecánica defensiva principal a partir de 3.3.
  4. **Se hornea en ejecución, no en el editor.** El blueprint había descartado esta opción en su Decisión 1 porque *«exige volver a hornear tras cada cambio del mapa»*. Esa objeción deja de aplicar al medir el coste: **5,9 ms**. Se hornea en cada carga a partir de los tiles, así que el mapa sigue siendo la única fuente de verdad y **pintar una habitación nueva se hace exactamente igual que antes**.
  5. **La cápsula era un error de modelado para un juego cenital.** 48 px de ancho pero **80 de alto**: el horneado supone un agente circular, así que 26 px de holgura sobraban a los lados y faltaban arriba y abajo. En el pasillo norte la malla dejaba 44 px de franja pero el cuerpo sólo cabía en 16, y se pasaba el trayecto rozando. **Ruta 1: de 15,70 s a 5,77 s**, con un mínimo teórico de 5,8. De regalo, `separation_radius = 48` pasa a ser *exactamente* «dos cuerpos que se tocan» en vez de una aproximación.
  6. **Tres guardias nuevos**, porque el fallo era silencioso por naturaleza: `world.gd` compara el cuerpo real de cada infectado contra la holgura de la malla y avisa si no cabe (y a una cápsula le pide su semieje mayor, no su radio); `infected.gd` avisa si `vision_mask` está a 0; y el baker avisa si la navegación por tile sigue encendida y hay dos superficies superpuestas.
  7. **La capa de navegación del TileSet se conserva, apagada.** Editar ese polígono ya no tiene ningún efecto. Se deja documentado en la cabecera del baker en vez de borrarlo, para no quemar el camino de vuelta mientras 1.5 no se haya jugado.
* **Verificación:** **23 comprobaciones, 0 fallos.**
  * **Rutas: de 1/4 a 7/7.** Ruta 1 en 5,77 s (mínimo teórico 5,8), la arteria norte↔sur en 8,35 s, y los dos casos que nunca se soltaban —jugador quieto y jugador alejándose— en 5,75 s y 7,17 s.
  * **Holgura:** 420 rutas y 754 puntos intermedios, **ninguno a menos de 26 px de un muro**; el peor a 36,6. Antes, el punto que atascaba estaba a **0 px**.
  * **Conectividad: 753/753 celdas** alcanzables desde el spawn del Player. Encoger 26 px no aisló ni el pasillo de 3 celdas ni la alcoba.
  * **Regresión:** cero incursiones en celda de muro con los tres infectados navegando 900 fotogramas, y las 10 comprobaciones de 3.1a otra vez en verde.
  * **Polígonos de navegación: de 136 a 7**, lo que abarata cada consulta de ruta justo donde hará falta en las oleadas del Bloque 5.

#### Lección 4: una ruta correcta no es lo mismo que una ruta recorrible
* **Qué pasó:** Este fallo llevaba ahí desde el Bloque 1 y ninguna de las verificaciones anteriores podía cazarlo, aunque las dos estaban bien hechas.
* **Por qué no lo cazaron:** La del 9 de septiembre —*51 puntos de ruta, 1289,6 px, 0,0 px de error*— se hizo con **un agente de prueba sin cuerpo**. Midió si la ruta es correcta, que es una pregunta distinta de si el cuerpo puede recorrerla. Y la del Bloque 1 midió *«cero incursiones en celda de muro»*, que es literalmente **la pregunta contraria**: aquí el problema no es que entre en la pared, es que **no entra y por eso se para**.
* **Y lo que lo mantuvo invisible:** la habitación era un rectángulo vacío. **Sin esquinas interiores, ninguna ruta tenía por qué pegarse a un filo.** El fallo no apareció porque el mapa de 3.0 lo creara, sino porque fue el primer mapa capaz de revelarlo.
* **La regla que queda:** cuando se valide navegación, el agente de prueba tiene que tener **el mismo cuerpo** que quien va a recorrerla. Un punto sin cuerpo pasa por sitios que no existen.

#### Lección 5: un ajuste de depuración que apaga un sistema tiene que gritar
* **Síntoma:** La batería de regresión dio tres fallos de línea de visión. El rayo funcionaba perfectamente —se comprobó que choca con el muro en (652, 32)— pero se lanzaba con **máscara 0**, que no choca con nada.
* **Causa Raíz:** `vision_mask` se había dejado a 0 para probar el pasillo. Un cero ahí **apaga la subetapa 3.1 entera sin un error, sin un aviso y sin ningún síntoma visible** salvo que los infectados vuelvan a ver a través de las paredes — que es exactamente lo que se estaba probando.
* **Solución:** `infected.gd` avisa por consola al nacer si la máscara está a 0. En la prueba de los guardias, el aviso saltó **en el primer arranque** y señaló el problema en dos segundos.
* **Por qué importa más allá de este caso:** los tres números nuevos que introduce el 1.5 —holgura de malla, radio del cuerpo, máscara de visión— fallan todos **hacia el silencio**. Ninguno rompe nada; los tres producen un juego que funciona y se siente mal. Por eso los tres guardias, y por eso los tres avisan al arrancar y no cuando ya es tarde.
* **Nota de coordinación:** el cambio se perdió dos veces porque Godot estaba abierto con el script en su editor y volcó su buffer encima. **Con Godot abierto, un `.gd` editado desde fuera puede revertirse sin avisar.**

#### Límite conocido: 3.1b sin construir y el Player sigue en cápsula
* **3.1b** —los dos rayos laterales que miden la silueta real en vez del centro— está diseñado y decidido, pero no escrito. Con un solo rayo al centro hay una franja de ±26 px en la que lo que ves en pantalla y lo que el infectado sabe no coinciden.
* **El Player conserva su cápsula de 52 × 88.** No navega, así que no le afecta este fallo — pero el pasillo norte mide 96 px de alto y eso le deja **8 px de margen** para maniobrar. Con un círculo de radio 26 serían 44.

---

## Convenciones de Arquitectura

1. **Estructura de Carpetas:**
   * Todos los scripts de jugabilidad se guardan en subcarpetas temáticas de `Scripts/` (e.g., `Scripts/Player/`, `Scripts/UI/`).
   * Todas las escenas empaquetadas se guardan en subcarpetas temáticas de `Scenes/` (e.g., `Scenes/Player/`, `Scenes/UI/`).

2. **Control de Cámara:**
   * Las cámaras de seguimiento dinámico deben ser hermanas del objetivo (nunca hijas) para evitar bucles de transformaciones.
   * Usar siempre el suavizado nativo del motor (`position_smoothing`) en lugar de interpolaciones por código que entren en conflicto con el motor.

3. **Suelo y navegación:**
   * La capa `Ground` define el espacio caminable, no sólo el aspecto. No se pinta suelo bajo un muro sólido y opaco.
   * Colisión y navegación son sistemas independientes en Godot: nada garantiza que coincidan salvo que el mapa se dibuje de forma que coincidan.
   * **La malla de navegación se hornea en ejecución a partir de los tiles, encogida el radio del cuerpo más un margen.** El polígono por tile del TileSet queda apagado: llega hasta el filo del muro, y ahí no cabe un cuerpo. Se conserva pero no se usa, así que editarlo no tiene ningún efecto.
   * **La holgura debe cubrir el semieje MAYOR del cuerpo, no su radio.** El horneado supone un agente circular, así que una cápsula alta en un juego cenital pide su media altura. Por eso los cuerpos que navegan son círculos: en vista desde arriba la forma de colisión es la huella en el suelo, no la silueta del sprite.
   * **Antes de la primera consulta de ruta hay que esperar a que el mapa esté sincronizado**, comprobando `NavigationServer2D.map_get_iteration_id()`. Nunca contando fotogramas: el número cambia según el contexto y el dispositivo.
   * El recálculo de ruta va **por temporizador y con desfase propio por entidad**, nunca cada fotograma.
   * **La navegación se valida con un agente que tenga el mismo cuerpo que va a recorrerla.** Un punto sin cuerpo pasa por sitios que no existen, y una ruta correcta no es lo mismo que una ruta recorrible.

4. **Capas de colisión:**
   * Capa 1 Mundo · capa 2 Player · capa 3 Infectados. Se declaran con nombre en `project.godot`.
   * Player e infectados enmascaran **sólo la capa 1**: chocan con el mundo, se atraviesan entre sí. El daño se resolverá por zona de detección, no por empujón físico.
   * La separación entre entidades se hace con repulsión propia, no con la evitación del `NavigationAgent2D`.
   * **El radio de llegada debe ser mayor que el de separación**, o la repulsión saca a la entidad de «he llegado» y aparece un rebote permanente.

5. **Instanciación del Player:**
   * El Player nunca se coloca a mano en una escena de mundo. Cada mundo lo instancia desde `player.tscn` en su `_ready()` y lo posiciona sobre su `Marker2D` `PlayerSpawn`.
   * En `main.tscn`, `World` debe permanecer **antes** de `CameraController` en el árbol. Los nodos nuevos que se agreguen al final no rompen esta regla.

6. **Referencias entre entidades y percepción:**
   * Una entidad se localiza **por grupo**, nunca por `NodePath` escrito a mano ni por referencia guardada. `is_instance_valid()` devuelve `true` para un nodo sacado del árbol pero no liberado, y con él se lee una posición obsoleta; el grupo deja de contenerlo de inmediato.
   * La memoria de una posición se guarda **copiando el `Vector2`**, nunca apuntando al nodo. Una referencia sigue moviéndose; una copia es lo que se recuerda.
   * Un mismo dato no se duplica en dos campos que puedan divergir. Si la memoria es también el destino, es un solo campo.
   * **Un único punto de cada script sabe que otra entidad existe.** Cuando cambie la forma de percibirla, se toca ahí y en ningún otro sitio.
   * Los cambios de estado **no adelantan trabajo caro**. Un estado que oscila en el borde de su condición lo dispararía cada fotograma; el temporizador es la única autoridad sobre cuándo se recalcula una ruta.

7. **Fallos silenciosos:**
   * **Un número que puede desincronizarse de otro que vive en otro archivo lleva un aviso al arrancar.** Hoy son dos: la holgura de la malla contra el radio real del cuerpo, y `vision_mask` contra cero.
   * **Un ajuste de depuración que apaga un sistema entero tiene que gritar por consola** mientras esté puesto. Estos fallos no rompen nada: producen un juego que funciona y se siente mal, y eso no lo detecta ninguna prueba automática.
   * **Con Godot abierto, un `.gd` editado desde fuera puede revertirse sin avisar** cuando el editor vuelca su buffer encima.

---

## Próximos Pasos

- [ ] Implementar Screen Shake dinámico al recibir daño o disparar.
- [ ] **Aplazado hasta el mapa del Capítulo 1:** configurar los límites de cámara con `set_map_limits()` a partir del `get_used_rect()` del TileMap. Con la habitación provisional actual (1344 × 768 px contra un viewport de 1280 × 720) cualquier límite dejaría la cámara casi estática. Mientras tanto, el fondo `#070d14` cubre el problema visual.
- [x] Desarrollar sistema de Joystick Virtual para Android (Completado: Etapas 1, 2 y 3).
- [x] Spawn dinámico del Player desde `World` mediante `PlayerSpawn` (Marker2D).
- [x] Capa de navegación en el TileSet, validada con un agente de prueba (Hito 009, paso 0).
- [x] **Bloque 1 completo:** escena del infectado, contenedor de spawns, navegación hasta un punto y capas de colisión (tareas 1.1 a 1.4).
- [x] **Bloque 2 completo:** máquina de estados plana, detección por distancia pura y memoria de última posición conocida (tareas 2.1 a 2.4). Ya persiguen.
- [x] **Bloque 1.5 completo:** malla de navegación horneada en ejecución con holgura de agente, y cuerpo circular. Los infectados dejan de atascarse en las esquinas. No estaba en el roadmap: salió de probar 3.0.
- [x] **3.0 completo:** geometría interior en el mapa —bloque macizo, pasillo norte y alcoba— para poder verificar el Bloque 3 jugando.
- [x] **3.1a completo:** línea de visión con un rayo contra la capa Mundo. Un muro ya te salva, y Búsqueda pasa a ser alcanzable jugando por primera vez.
- [ ] **3.1b:** los dos rayos laterales, con la perilla de silueta apagada hasta que llegue 3.3. Diseñado y decidido, sin escribir.
- [ ] **Resto del Bloque 3:** cono de visión (3.2), detección por movimiento (3.3) y el medidor de agitación (3.4). Ahí nace el sigilo de verdad, y ahí se resuelve la oscilación en el borde del radio de detección.
- [ ] **El Player sigue en cápsula de 52 × 88.** No navega, así que el fallo del 1.5 no le afecta, pero el pasillo norte mide 96 px de alto y eso le deja 8 px de margen. Con un círculo de radio 26 serían 44.
- [ ] **Ninguna prueba está versionada.** Las 23 comprobaciones del 16 de septiembre, y las 26 del Bloque 2, se escribieron, se ejecutaron y se borraron: hoy no se pueden repetir. Decidir si las de verificación pasan a `tests/`.
- [ ] **Versionar el roadmap y el blueprint en `docs/`.** El código los cita como autoridad —«paso 3 del blueprint», «Bloque 2 del roadmap»— pero sólo existen publicados, no en el repositorio: no hay forma de saber qué decían cuando se escribió cada commit.
- [ ] **Nunca ejecutado en un teléfono.** Casi cuatro meses construyendo para Android sin un solo arranque en Android, sin `export_presets.cfg`, sin orientación ni modo de estiramiento. Es el mayor riesgo abierto del proyecto.
- [ ] **Pendiente antes del sistema de respawn:** `CameraController` resuelve su objetivo una sola vez en `_ready()`. Cuando exista muerte/respawn y el Player se destruya y se vuelva a crear, la cámara quedará apuntando a una referencia liberada. Habrá que hacer que el objetivo se reasigne (señal desde `World` o búsqueda por grupo).
