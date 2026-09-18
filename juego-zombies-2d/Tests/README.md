# Pruebas

Baterías headless que se ejecutan contra **el mundo real cargado como escena**,
no contra un montaje aparte. Cada una devuelve código de salida `1` si algo
falla, así que valen tanto a ojo como encadenadas.

## Cómo se ejecutan

Desde la carpeta `juego-zombies-2d`:

```
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://Tests/test_player.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://Tests/test_perception.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://Tests/test_navigation.gd
```

Y la consola del juego real, que también es una prueba:

```
Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 300
```

Tiene que imprimir **dos líneas y ningún aviso**. Si sale alguno, es uno de los
tres guardias diciendo qué número se ha desincronizado.

**No filtres la salida cuando algo falle.** El error que costó seis intentos en
septiembre estaba impreso en pantalla y se perdió por buscar sólo los `print`
propios.

## Qué cubre cada una

| Archivo | Qué comprueba | Dura |
|---|---|---|
| `test_player.gd` | Aparición, capas, que los muros lo paren, y que cruce el pasillo norte a plena velocidad | ~10 s |
| `test_perception.gd` | Línea de visión, que los cuerpos no tapen, que la memoria se congele al taparte, y los dos rayos laterales | ~10 s |
| `test_navigation.gd` | Holgura de cada punto de ruta, conectividad, las siete rutas de extremo a extremo e incursiones en muro | ~60 s |

`test_base.gd` no se ejecuta sola: es el andamiaje común.

## Por qué existen

Hasta el 18 de septiembre las pruebas se escribían, se ejecutaban y se
borraban. Las 26 comprobaciones del Bloque 2 y las 23 del Bloque 1.5 quedaron
en el dev_log como números que ya no se podían repetir.

La que más importa es la de **holgura de ruta** en `test_navigation.gd`. El
fallo que paralizó a los infectados durante días no era que la ruta fuera
incorrecta —lo era, y las validaciones anteriores lo confirmaban— sino que
**el cuerpo no cabía por donde la ruta pasaba**. Esas validaciones se hicieron
con un agente de prueba sin cuerpo, y un punto sin cuerpo pasa por sitios que
no existen.

Cuando se pinte el mapa del Capítulo 1, esa comprobación dirá en segundos si
alguna esquina nueva vuelve a dejar una ruta sin sitio.

## Antes de exportar a Android

Esta carpeta se incluiría en el paquete. Hay que excluirla en los ajustes de
exportación cuando exista `export_presets.cfg` (tarea 0.2 del roadmap).
