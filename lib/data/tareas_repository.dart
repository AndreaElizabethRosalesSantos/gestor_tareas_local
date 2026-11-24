import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';

/// Única clase que consulta la base; la interfaz no contiene SQL.
class TareasRepository {
  TareasRepository(this._db);

  final AppDatabase _db;

  /// SELECT reactivo: emite la lista otra vez después de cada escritura.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch();
  }

  /// INSERT. Devuelve el id generado por SQLite.
  Future<int> agregar(String titulo) {
    return _db
        .into(_db.tareas)
        .insert(TareasCompanion.insert(titulo: titulo.trim()));
  }
}
