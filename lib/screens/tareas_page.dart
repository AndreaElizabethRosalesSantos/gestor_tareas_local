import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tareas_repository.dart';
import '../models/tarea.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repositorio});

  final TareasRepository repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  StreamSubscription<List<Tarea>>? _suscripcion;
  List<Tarea> _tareas = [];
  bool _cargando = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    // La consulta se abre una sola vez aquí, nunca dentro de build().
    _suscripcion = widget.repositorio.observarTareas().listen(
      (tareas) => setState(() {
        _tareas = tareas;
        _cargando = false;
        _errorCarga = null;
      }),
      onError: (Object error) {
        debugPrint('Error al leer la base: $error');
        setState(() {
          _cargando = false;
          _errorCarga = 'No se pudieron cargar las tareas guardadas.';
        });
      },
    );
  }

  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text;
    if (titulo.trim().isEmpty) {
      _mensaje('Escribe un título para la tarea.');
      return;
    }
    try {
      await widget.repositorio.agregar(titulo);
      if (mounted) _tituloController.clear();
    } catch (error) {
      debugPrint('Error al guardar: $error');
      _mensaje('No se pudo guardar la tarea.');
    }
  }

  void _alternarCompletada(Tarea tarea, bool completada) {
    _mensaje('Implementar actualización de tarea');
  }

  void _editarTarea(Tarea tarea) {
    _mensaje('Implementar edición de título');
  }

  void _eliminarTarea(Tarea tarea) {
    _mensaje('Implementar eliminación de tarea');
  }

  void _mensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _errorCarga != null
                  ? Center(child: Text(_errorCarga!))
                  : _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: (valor) {
                                if (valor != null) {
                                  _alternarCompletada(tarea, valor);
                                }
                              },
                            ),
                            title: Text(tarea.titulo),
                            subtitle: Text('ID: ${tarea.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _eliminarTarea(tarea),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
