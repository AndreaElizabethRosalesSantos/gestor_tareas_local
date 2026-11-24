import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

void main() {
  late Directory carpeta;
  late File archivo;
  late AppDatabase db;
  late TareasRepository repo;

  void abrir() {
    db = AppDatabase(NativeDatabase(archivo));
    repo = TareasRepository(db);
  }

  /// Simula cerrar la app: cierra la base y abre el mismo archivo.
  Future<void> reabrir() async {
    await db.close();
    abrir();
  }

  setUp(() {
    carpeta = Directory.systemTemp.createTempSync('tareas_test');
    archivo = File('${carpeta.path}/prueba.sqlite');
    abrir();
  });

  tearDown(() async {
    await db.close();
    carpeta.deleteSync(recursive: true);
  });

  test('tres tareas permanecen después de cerrar y reabrir', () async {
    await repo.agregar('Uno');
    await repo.agregar('Dos');
    await repo.agregar('Tres');

    await reabrir();

    final tareas = await repo.observarTareas().first;
    expect(tareas.map((t) => t.titulo), ['Uno', 'Dos', 'Tres']);
    expect(tareas.every((t) => !t.completada), isTrue);
  });
}
