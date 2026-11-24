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

  /// Ejecuta una escritura y muestra un mensaje comprensible si falla.
  Future<bool> _ejecutar(Future<void> Function() accion, String fallo) async {
    try {
      await accion();
      return true;
    } on TituloInvalido catch (error) {
      _mensaje(error.mensaje);
    } catch (error) {
      debugPrint('$fallo $error');
      _mensaje(fallo);
    }
    return false;
  }

  Future<void> _agregarTarea() async {
    final guardada = await _ejecutar(
      () => widget.repositorio.agregar(_tituloController.text),
      'No se pudo guardar la tarea.',
    );
    if (guardada && mounted) _tituloController.clear();
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(
      () => widget.repositorio.cambiarEstado(tarea.id, completada),
      'No se pudo actualizar la tarea.',
    );
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditar(tituloInicial: tarea.titulo),
    );
    if (nuevo == null) return;
    await _ejecutar(
      () => widget.repositorio.editarTitulo(tarea.id, nuevo),
      'No se pudo editar la tarea.',
    );
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    await _ejecutar(
      () => widget.repositorio.eliminar(tarea.id),
      'No se pudo eliminar la tarea.',
    );
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

/// Diálogo que administra y libera su propio controlador de texto.
class _DialogoEditar extends StatefulWidget {
  const _DialogoEditar({required this.tituloInicial});

  final String tituloInicial;

  @override
  State<_DialogoEditar> createState() => _DialogoEditarState();
}

class _DialogoEditarState extends State<_DialogoEditar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.tituloInicial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(controller: _controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
