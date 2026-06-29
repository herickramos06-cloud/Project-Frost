# AGENTS.md

# PROJECT-FROST

### AI Development Constitution

---

# 1. Project Overview

## Project Name

PROJECT-FROST

## Description

PROJECT-FROST (Antesala Zombies 2032) es un videojuego Survival Horror 2D Top-Down para dispositivos Android desarrollado con Godot Engine.

El objetivo es construir un juego profesional, modular, escalable y mantenible mediante una colaboración entre el desarrollador humano y agentes de IA.

La calidad del código, la arquitectura y la documentación tienen la misma prioridad que las funcionalidades.

---

# 2. Technology Stack

Engine

* Godot Engine 4.6 (Stable)

Language

* GDScript

Version Control

* Git
* GitHub

IDE

* Cursor AI

Platform

* Android

Documentation

* Markdown
* HTML (GDD,LORE,DEV_DASHBOARD,etc)

---

# 3. Project Structure

Describe brevemente el propósito de cada carpeta.

Ejemplo:

project-frost/docs
Documentación técnica, GDD, arquitectura y especificaciones.

project-frost/assets
Sprites, audio, fuentes , recursos , texturas etc.


project-frost/juego-zombies-2d: Ecosistema GODOT:

juego-zombies-2d/scenes
Escenas de Godot.

juego-zombies-2d/scripts
Lógica del juego 

project-frost/src
Otros utiles, codigo "bruto"

Nunca crear archivos fuera de la estructura establecida sin justificación.

---

# 4. Development Workflow

Seguir siempre este orden:

1. Analizar el problema.
2. Comprender el contexto.
3. Consultar documentación relevante.
4. Proponer una solución.
5. Esperar aprobación si el cambio es grande.
6. Implementar.
7. Explicar los cambios.
8. Verificar funcionamiento.

Nunca modificar múltiples sistemas simultáneamente.

---

# 5. Coding Standards

Todo código debe cumplir:

* Clean Code
* SOLID cuando sea aplicable
* Principio KISS
* Principio DRY
* Modularidad
* Alta legibilidad

Variables:
snake_case

Clases:
PascalCase

Constantes:
UPPER_CASE

Funciones pequeñas y con una única responsabilidad.

---

# 6. Architecture Principles

Priorizar:

Composición sobre herencia.

Bajo acoplamiento.

Alta cohesión.

Escalabilidad.

Reutilización.

Evitar duplicación de lógica.

Cada sistema debe poder evolucionar independientemente.

---

# 7. AI Responsibilities

Antes de escribir código el agente debe:

Analizar.
Detectar riesgos.
Identificar dependencias.
Explicar el plan.

Después:

Explicar cada cambio realizado.
Justificar decisiones técnicas.
Indicar posibles mejoras futuras.

---

# 8. Forbidden Actions

El agente NO debe:

-Modificar arquitectura sin autorización ni permiso.

-Eliminar archivos existentes sin permiso.

-Cambiar nombres públicos sin justificación.

-Duplicar lógica.

-Crear código innecesariamente complejo.

-Inventar APIs.

-Inventar nodos inexistentes.

-Ignorar errores del compilador.

-Modificar documentación sin indicar el motivo.

---

# 9. Documentation Rules

Cada nueva funcionalidad importante debe reflejarse en:

* Documentación técnica

* Comentarios cuando aporten valor

* DEV_LOG.MD

No comentar código obvio.
Documentar decisiones de arquitectura SIEMPRE.

---


# 10. Decision Hierarchy

En caso de conflicto seguir este orden:

1. GDD
2. AGENTS.md
3. Especificaciones del usuario  
5. Buenas prácticas de Godot
6. Convenciones del lenguaje
(Si tienes que modificar  alguna regla , practica, arquitectura o lo que fuera 
del agents.md QUE SEA SOLO SI EL USUARIO LO DICE)
---


# 11. Quality Checklist

Antes de finalizar cualquier tarea verificar:

✓ Compila correctamente.

✓ No rompe funcionalidades existentes.

✓ Sigue la arquitectura.

✓ Código legible.

✓ Modular.

✓ Escalable.

✓ Explicado.

✓ Sin duplicación.

✓ Compatible con Godot 4.

---

# 12. Development Philosophy

La IA no es autora del proyecto.

La IA actúa como un Ingeniero Senior que asiste al desarrollador.

Las decisiones finales pertenecen siempre al desarrollador humano.

El objetivo no es generar la mayor cantidad de código, sino CONSTRUIR un proyecto profesional, mantenible y preparado para crecer durante AÑOS.
