import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';

/// Error de validación con un mensaje que se puede mostrar al usuario.
class TituloInvalido implements Exception {
  const TituloInvalido(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// La tarea que se quería modificar ya no existe.
class TareaNoEncontrada implements Exception {
  const TareaNoEncontrada(this.id);

  final int id;

  @override
  String toString() => 'No existe la tarea con ID $id.';
}

/// Única clase que consulta la base; la interfaz no contiene SQL.
class TareasRepository {
  TareasRepository(this._db);

  static const longitudMaxima = 200;

  final AppDatabase _db;

  /// Quita espacios de los extremos y rechaza títulos no válidos.
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

  /// SELECT reactivo: emite la lista otra vez después de cada escritura.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch();
  }

  /// INSERT. Devuelve el id generado por SQLite.
  Future<int> agregar(String titulo) async {
    final limpio = validarTitulo(titulo);
    return _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  /// UPDATE del título.
  Future<void> editarTitulo(int id, String titulo) async {
    final limpio = validarTitulo(titulo);
    await _actualizar(id, TareasCompanion(titulo: Value(limpio)));
  }

  /// UPDATE del estado.
  Future<void> cambiarEstado(int id, bool completada) {
    return _actualizar(id, TareasCompanion(completada: Value(completada)));
  }

  /// DELETE por identificador.
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
