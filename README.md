# Gestor de tareas local

Aplicación Flutter que administra tareas en una base **SQLite local**, sin servidor ni conexión a internet.
Permite agregar, listar, editar, marcar como completada/pendiente y eliminar.

## Cómo ejecutar

Probado con Flutter 3.47.4 (Dart 3.13.3).

```
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d chrome --web-port=8123
```

En web conviene fijar el puerto: los datos pertenecen al origen (host y puerto) y al perfil del navegador.
`flutter run -d chrome` usa un perfil temporal, así que para comprobar la persistencia al cerrar y abrir la
pestaña es mejor compilar y servir la app, y abrirla en el navegador habitual:

```
flutter build web --no-web-resources-cdn
python -m http.server 8123 -d build/web
```

Luego abre <http://localhost:8123>. Si se modifica la tabla, regenera el código con
`dart run build_runner build`.

## Tecnología elegida

**Drift + drift_flutter.** Drift permite definir tablas y consultas en Dart con tipos verificados, y
`drift_flutter` abre la base en Android, iOS, Windows, Linux, macOS y web con la misma función.

## Diseño de la tabla `tareas`

| Columna | Tipo SQLite | Restricciones | Uso |
|---|---|---|---|
| `id` | INTEGER | NOT NULL PRIMARY KEY AUTOINCREMENT | Identifica cada tarea |
| `titulo` | TEXT | NOT NULL (1 a 200 caracteres, validado en Dart) | Texto de la tarea |
| `completada` | INTEGER | NOT NULL DEFAULT 0, CHECK 0 o 1 | Estado de la tarea |

SQLite no tiene un tipo booleano propio, por lo que Drift guarda 0 (pendiente) o 1 (completada).
Cada registro se identifica por `id`; con AUTOINCREMENT, SQLite no reutiliza los de tareas eliminadas.

## Estructura

- `lib/models/tarea.dart`: modelo que Drift usa como clase de fila.
- `lib/data/app_database.dart`: tabla y apertura de la base (`app_database.g.dart` es generado).
- `lib/data/tareas_repository.dart`: validación y operaciones CRUD.
- `lib/screens/tareas_page.dart`: interfaz; escucha un `Stream` abierto en `initState`, sin consultas en `build()`.
- `web/sqlite3.wasm` y `web/drift_worker.dart.js`: recursos del release `drift-2.35.4`, la misma versión de
  `drift` en `pubspec.lock`. El segundo se publica como `drift_worker.js` y aquí se renombró.

## Pruebas automatizadas

- `test/persistencia_test.dart`: usa un archivo SQLite real, lo cierra y lo reabre. Cubre alta, estado,
  edición, eliminación, validación de títulos y tareas inexistentes.
- `test/widget_test.dart`: apertura de la pantalla y CRUD completo desde la interfaz.

## Plataformas

| Plataforma | Estado |
|---|---|
| Windows | Compilada; P1–P5 verificadas cerrando y reabriendo la app |
| Web | Compilada; P1–P6 verificadas recargando y reabriendo la pestaña |
| Android | APK de depuración compilado; falta ejecutarlo en un dispositivo |
| iOS, macOS, Linux | Previstas por diseño; no compiladas ni ejecutadas |

