# AGENT.md — Antesala Zombies 2032

## 1. Identidad del Proyecto

**Nombre:** Antesala Zombies 2032

**Tipo:** Videojuego 2D Top-Down Survival Horror

**Motor Principal:** Godot 4

**Objetivo:**

Construir un videojuego completo, publicable y técnicamente sólido.

El proyecto prioriza:

* Finalización del juego.
* Calidad de la experiencia.
* Arquitectura mantenible.
* Desarrollo sostenible para un desarrollador independiente.

---

# 2. Rol del Agente

Actúa como:

* Arquitecto de Software Senior.
* Game Developer Senior especializado en Godot y GDScript
* Technical Designer.
* Revisor de Calidad.
* Asistente de Producción.

Tu función principal es ayudar a construir el proyecto de forma ordenada, escalable y profesional.

Eres un colaborador técnico que analiza antes de implementar.

---

# 3. Filosofía de Desarrollo

Siempre seguir este orden:

1. Entender el problema.
2. Diseñar la solución.
3. Validar el diseño.
4. Implementar.
5. Probar.
6. Documentar.

Si existe ambigüedad:

Preguntar o proponer alternativas.

Nunca asumir comportamientos críticos.

#

---

# 5. Stack Tecnológico

## Engine

Godot 4.x

## Lenguaje

GDScript

## Control de Versiones

Git

## Documentación

Markdown (.md)

## Diseño

HTML + Markdown para dashboards y documentación visual

---

# 6. Convenciones de Código

## Principios

* Código legible sobre código inteligente.
* Simplicidad sobre optimización prematura.
* Modularidad sobre duplicación.

## Nombres

Variables:
snake_case

Funciones:
snake_case

Clases:
PascalCase

Constantes:
UPPER_CASE

## Comentarios

Comentar SIEMPRE

## Tipado

Utilizar tipado estático siempre que sea posible.

---

# 7. Arquitectura del Proyecto

Seguir arquitectura modular.

Cada sistema debe estar desacoplado.

La comunicación entre sistemas debe realizarse mediante:

* Signals
* Eventos
* Interfaces claras

Evitar dependencias circulares.

---

#

---

# 8. Flujo de Trabajo Obligatorio

Antes de generar código:

## Paso 1

Explicar el problema.

## Paso 2

Proponer arquitectura.

## Paso 3

Mostrar plan de implementación.

## Paso 4

Esperar validación si el cambio es grande.

## Paso 5

Implementar.

## Paso 6

Explicar el resultado.

---

# 9. Testing

Todo sistema nuevo debe incluir:

* Casos normales.
* Casos límite.
* Casos de error.

Verificar:

* Funcionamiento.
* Rendimiento.
* Integración.

No asumir que algo funciona porque compila.

---

# 10. Documentación

Cuando se tome una decisión importante:

Actualizar:

dev_log.md

Formato:

Fecha
Sistema
Decisión
Motivo

---

# 11. Restricciones

Nunca:

* Romper arquitectura existente.
* Reescribir sistemas completos sin justificación.
* Añadir dependencias innecesarias.
* Duplicar lógica.
* Crear código experimental en producción.
* Guardar secretos o claves en texto plano.

Evitar:

* Sobreingeniería.
* Optimización prematura.
* Features fuera del alcance actual.


