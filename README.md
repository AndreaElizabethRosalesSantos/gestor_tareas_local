# Gestor de tareas local

Aplicación Flutter que administra tareas en una base **SQLite local**, sin servidor ni conexión a internet.

## Tecnología elegida

**Drift + drift_flutter.** Drift permite definir tablas y consultas en Dart con tipos verificados, y
`drift_flutter` abre la base en Android, iOS, Windows, Linux, macOS y web con la misma función.

## Diseño de la tabla `tareas`

| Columna | Tipo SQLite | Restricciones | Uso |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Identifica cada tarea |
| `titulo` | TEXT | NOT NULL, entre 1 y 200 caracteres | Texto de la tarea |
| `completada` | INTEGER (0/1) | NOT NULL DEFAULT 0 | Estado de la tarea |

SQLite no tiene un tipo booleano propio, por lo que Drift guarda 0 (pendiente) o 1 (completada).
Cada registro se identifica por `id`; con AUTOINCREMENT, SQLite no reutiliza los de tareas eliminadas.
