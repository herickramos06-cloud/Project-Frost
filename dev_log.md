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
   * Sólo el tile de suelo lleva polígono de navegación. El de muro nunca.
   * **Antes de la primera consulta de ruta hay que esperar a que el mapa esté sincronizado**, comprobando `NavigationServer2D.map_get_iteration_id()`. Nunca contando fotogramas: el número cambia según el contexto y el dispositivo.
   * El recálculo de ruta va **por temporizador y con desfase propio por entidad**, nunca cada fotograma.

4. **Capas de colisión:**
   * Capa 1 Mundo · capa 2 Player · capa 3 Infectados. Se declaran con nombre en `project.godot`.
   * Player e infectados enmascaran **sólo la capa 1**: chocan con el mundo, se atraviesan entre sí. El daño se resolverá por zona de detección, no por empujón físico.
   * La separación entre entidades se hace con repulsión propia, no con la evitación del `NavigationAgent2D`.
   * **El radio de llegada debe ser mayor que el de separación**, o la repulsión saca a la entidad de «he llegado» y aparece un rebote permanente.

5. **Instanciación del Player:**
   * El Player nunca se coloca a mano en una escena de mundo. Cada mundo lo instancia desde `player.tscn` en su `_ready()` y lo posiciona sobre su `Marker2D` `PlayerSpawn`.
   * En `main.tscn`, `World` debe permanecer **antes** de `CameraController` en el árbol. Los nodos nuevos que se agreguen al final no rompen esta regla.

---

## Próximos Pasos

- [ ] Implementar Screen Shake dinámico al recibir daño o disparar.
- [ ] **Aplazado hasta el mapa del Capítulo 1:** configurar los límites de cámara con `set_map_limits()` a partir del `get_used_rect()` del TileMap. Con la habitación provisional actual (1344 × 768 px contra un viewport de 1280 × 720) cualquier límite dejaría la cámara casi estática. Mientras tanto, el fondo `#070d14` cubre el problema visual.
- [x] Desarrollar sistema de Joystick Virtual para Android (Completado: Etapas 1, 2 y 3).
- [x] Spawn dinámico del Player desde `World` mediante `PlayerSpawn` (Marker2D).
- [x] Capa de navegación en el TileSet, validada con un agente de prueba (Hito 009, paso 0).
- [x] **Bloque 1 completo:** escena del infectado, contenedor de spawns, navegación hasta un punto y capas de colisión (tareas 1.1 a 1.4).
- [ ] **Bloque 2:** máquina de estados, detección por distancia pura y memoria de última posición. Ahí empiezan a perseguir.
- [ ] Crear IA de persecución para el primer infectado.
- [ ] **Nunca ejecutado en un teléfono.** Quince meses construyendo para Android sin un solo arranque en Android, sin `export_presets.cfg`, sin orientación ni modo de estiramiento. Es el mayor riesgo abierto del proyecto.
- [ ] **Pendiente antes del sistema de respawn:** `CameraController` resuelve su objetivo una sola vez en `_ready()`. Cuando exista muerte/respawn y el Player se destruya y se vuelva a crear, la cámara quedará apuntando a una referencia liberada. Habrá que hacer que el objetivo se reasigne (señal desde `World` o búsqueda por grupo).
