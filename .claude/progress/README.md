# Progress System — Aerovisuales 4K

> Estado compartido entre subagentes para evitar trabajo redundante.

## Cómo funciona

Cada tarea (feature, fix, investigación) crea un archivo en este directorio:

```
.claude/progress/2026-06-validation-email.md
.claude/progress/2026-06-postgres-migration.md
.claude/progress/2026-06-cajita-8-proforma.md
```

## Convención de nombrado

```
YYYY-MM-[slug-corto-descriptivo].md
```

- `2026-06-` = año-mes en que empezó la tarea
- `slug-corto-descriptivo` = kebab-case, máx 5 palabras

## Estructura de cada archivo

Cada archivo de progress sigue esta plantilla obligatoria:

```markdown
# [Título de la tarea]

**Estado:** in-progress | blocked | review | done
**Iniciada:** YYYY-MM-DD
**Última actualización:** YYYY-MM-DD HH:MM

## Contexto inicial
[Qué pidió el usuario, por qué se necesita, criterios de éxito]

## Investigation
[Llenado por Investigator: qué encontró, dónde vive el código, dependencias]

## Implementation
[Llenado por Implementer: qué cambió, archivos tocados, decisiones tomadas]

## Review
[Llenado por Reviewer: hallazgos, ✅ aprobado o ❌ requiere ajustes]

## Iterations
[Si hay back-and-forth: ronda 1, ronda 2, etc.]

## Outcome
[Resultado final: qué quedó funcionando, qué pendiente]
```

## Reglas para los subagentes

1. **SIEMPRE leer** los archivos de `progress/` relevantes antes de actuar
2. **NUNCA borrar** información escrita por otro subagente — solo agregar
3. **MARCAR claramente** quién escribió qué (con header de sección)
4. **NO escribir secciones que no te corresponden** (Investigator no llena "Implementation", etc.)
5. **Actualizar el campo "Última actualización"** cada vez que toques el archivo

## Reglas para el usuario (Julio)

1. **Cuando inicies una tarea nueva:** crea el archivo de progress con la estructura
2. **Cuando una tarea se cierre:** mueve el archivo a `.claude/progress/archive/` o agrega "ARCHIVED" al frente del nombre
3. **Si la tarea queda en pausa por días:** el archivo se queda aquí (sirve para retomar contexto)
4. **No borres archivos viejos sin revisar primero:** pueden tener contexto valioso para tareas similares futuras
