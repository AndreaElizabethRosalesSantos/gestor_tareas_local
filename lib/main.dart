import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/tareas_repository.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada: abre la base una vez y la cierra al terminar.
class GestorTareasApp extends StatefulWidget {
  const GestorTareasApp({super.key, this.database});

  /// Base inyectada en pruebas. Si es null se abre la base persistente.
  final AppDatabase? database;

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final AppDatabase _db;
  late final TareasRepository _repositorio;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _repositorio = TareasRepository(_db);
  }

  @override
  void dispose() {
    // Solo se cierra la base que abrió este widget.
    if (widget.database == null) _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: _repositorio),
    );
  }
}
