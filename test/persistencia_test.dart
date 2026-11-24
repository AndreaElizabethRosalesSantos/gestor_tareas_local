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

  // Hace como si cerrara y volviera a abrir la app.
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

  test('el estado completado se conserva al reabrir', () async {
    final id = await repo.agregar('Estudiar');
    await repo.cambiarEstado(id, true);
    await reabrir();
    expect((await repo.observarTareas().first).single.completada, isTrue);

    await repo.cambiarEstado(id, false);
    await reabrir();
    expect((await repo.observarTareas().first).single.completada, isFalse);
  });

  test('el título editado se conserva al reabrir', () async {
    final id = await repo.agregar('Antes');
    await repo.editarTitulo(id, 'Después');
    await reabrir();
    expect((await repo.observarTareas().first).single.titulo, 'Después');
  });

  test('una tarea eliminada no reaparece ni se reutiliza su id', () async {
    final id = await repo.agregar('Borrar');
    await repo.eliminar(id);
    await reabrir();
    expect(await repo.observarTareas().first, isEmpty);
    expect(await repo.agregar('Nueva'), greaterThan(id));
  });

  test('rechaza títulos vacíos, con solo espacios o muy largos', () async {
    for (final titulo in ['', '   ', 'x' * 201]) {
      await expectLater(repo.agregar(titulo), throwsA(isA<TituloInvalido>()));
    }
    expect(await repo.observarTareas().first, isEmpty);

    final id = await repo.agregar('  Válida  ');
    await expectLater(
      repo.editarTitulo(id, ' '),
      throwsA(isA<TituloInvalido>()),
    );
    expect((await repo.observarTareas().first).single.titulo, 'Válida');
  });

  test('avisa si la tarea ya no existe', () async {
    await expectLater(repo.eliminar(99), throwsA(isA<TareaNoEncontrada>()));
    await expectLater(
      repo.cambiarEstado(99, true),
      throwsA(isA<TareaNoEncontrada>()),
    );
  });
}
