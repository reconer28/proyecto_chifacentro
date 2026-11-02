import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import 'widgets.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key, required this.controlador});
  final AppController controlador;
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  late final Set<String> _seleccionadas = widget.controlador.misMesas
      .map((mesaActual) => mesaActual.id)
      .toSet();
  final _contrasena = TextEditingController();
  final _formulario = GlobalKey<FormState>();
  @override
  void dispose() {
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) {
      return;
    }
    final exito = await widget.controlador.asignarMesas(
      _seleccionadas.toList(),
      _contrasena.text,
    );
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _contrasena.clear();
    if (exito) {
      mostrarConfirmacion(context, 'Mesas asignadas a tu turno');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext contexto) => AnimatedBuilder(
    animation: widget.controlador,
    builder: (contexto, _) {
      final estadoAplicacion = widget.controlador;
      return Scaffold(
        appBar: AppBar(title: const Text('Asignar mesas')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  const Pill(
                    'AUTORIZACIÓN DEL ADMINISTRADOR',
                    color: ChifaColors.dorado,
                    icono: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prepara tu turno',
                    style: Theme.of(contexto).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona las mesas que atenderás. El administrador confirma la asignación con su clave.',
                    style: TextStyle(color: ChifaColors.tenue, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (estadoAplicacion.mesas.isEmpty)
                    const EmptyState(
                      icono: Icons.cloud_download_outlined,
                      titulo: 'Sin mesas descargadas',
                      mensaje: 'Vuelve al salón y actualiza los datos antes de asignar mesas.',
                    ),
                  ...estadoAplicacion.mesas.map((mesaActual) {
                    final deOtroMozo =
                        mesaActual.idMozo != null &&
                        mesaActual.idMozo != estadoAplicacion.usuario!.id;
                    final bloqueada =
                        mesaActual.idMozo == estadoAplicacion.usuario!.id &&
                        (mesaActual.ocupada ||
                            estadoAplicacion.borradorDeMesa(mesaActual.id) !=
                                null);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Paper(
                        relleno: EdgeInsets.zero,
                        contenido: CheckboxListTile(
                          value: _seleccionadas.contains(mesaActual.id),
                          onChanged:
                              estadoAplicacion.procesando ||
                                  deOtroMozo ||
                                  bloqueada
                              ? null
                              : (valorActual) => setState(() {
                                  if (valorActual!) {
                                    _seleccionadas.add(mesaActual.id);
                                  } else {
                                    _seleccionadas.remove(mesaActual.id);
                                  }
                                }),
                          title: Text(
                            'Mesa ${mesaActual.numero.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            deOtroMozo
                                ? 'Asignada a otro mozo'
                                : bloqueada
                                ? 'Con atención o borrador activo'
                                : '${mesaActual.zona} · ${mesaActual.capacidad} personas',
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            deOtroMozo
                                ? Icons.lock_outline_rounded
                                : Icons.table_restaurant_outlined,
                            color: deOtroMozo
                                ? ChifaColors.tenue
                                : ChifaColors.dorado,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Form(
                    key: _formulario,
                    child: TextFormField(
                      controller: _contrasena,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      enabled: !estadoAplicacion.procesando,
                      decoration: const InputDecoration(
                        labelText: 'Clave del administrador',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (valorActual) =>
                          valorActual == null || valorActual.isEmpty
                          ? 'El administrador debe ingresar su clave'
                          : null,
                    ),
                  ),
                  if (estadoAplicacion.esDemo)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Clave de prueba: 2468',
                        style: TextStyle(
                          fontSize: 12,
                          color: ChifaColors.tenue,
                        ),
                      ),
                    ),
                  if (estadoAplicacion.error != null)
                    ErrorNotice(estadoAplicacion.error!),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        estadoAplicacion.procesando ||
                            estadoAplicacion.mesas.isEmpty
                        ? null
                        : _guardar,
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Confirmar ${_seleccionadas.length} mesas'),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
