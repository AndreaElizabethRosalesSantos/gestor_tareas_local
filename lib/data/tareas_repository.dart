import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';

// Error para cuando el título no es válido.
class TituloInvalido implements Exception {
  const TituloInvalido(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

// Error para cuando la tarea ya no existe.
class TareaNoEncontrada implements Exception {
  const TareaNoEncontrada(this.id);

  final int id;

  @override
  String toString() => 'No existe la tarea con ID $id.';
}

// Aquí están todas las operaciones con la base.
class TareasRepository {
  TareasRepository(this._db);

  static const longitudMaxima = 200;

  final AppDatabase _db;

  // Revisa que el título no esté vacío ni sea muy largo.
  static String validarTitulo(String titulo) {
    final limpio = titulo.trim();
    if (limpio.isEmpty) {
      throw const TituloInvalido('El título no puede estar vacío.');
    }
    if (limpio.length > longitudMaxima) {
      throw const TituloInvalido(
        'El título admite máximo $longitudMaxima caracteres.',
      );
    }
    return limpio;
  }

  // Consultar (SELECT). La lista se actualiza sola cuando algo cambia.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch();
  }

  // Agregar (INSERT). Regresa el id que le puso SQLite.
  Future<int> agregar(String titulo) async {
    final limpio = validarTitulo(titulo);
    return _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  // Cambiar el título (UPDATE).
  Future<void> editarTitulo(int id, String titulo) async {
    final limpio = validarTitulo(titulo);
    await _actualizar(id, TareasCompanion(titulo: Value(limpio)));
  }

  // Marcar como completada o pendiente (UPDATE).
  Future<void> cambiarEstado(int id, bool completada) {
    return _actualizar(id, TareasCompanion(completada: Value(completada)));
  }

  // Eliminar por id (DELETE).
  Future<void> eliminar(int id) async {
    final filas = await (_db.delete(
      _db.tareas,
    )..where((t) => t.id.equals(id))).go();
    if (filas == 0) throw TareaNoEncontrada(id);
  }

  Future<void> _actualizar(int id, TareasCompanion cambios) async {
    final filas = await (_db.update(
      _db.tareas,
    )..where((t) => t.id.equals(id))).write(cambios);
    if (filas == 0) throw TareaNoEncontrada(id);
  }
}
