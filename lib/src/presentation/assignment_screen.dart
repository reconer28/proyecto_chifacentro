import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import 'widgets.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  late final Set<String> _selected = widget.controller.myTables
      .map((t) => t.id)
      .toSet();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final ok = await widget.controller.assignTables(
      _selected.toList(),
      _password.text,
    );
    _password.clear();
    if (ok && mounted) {
      notifySuccess(context, 'Mesas asignadas a tu turno');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
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
                    color: ChifaColors.gold,
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prepara tu turno',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona las mesas que atenderás. El administrador confirma la asignación con su clave.',
                    style: TextStyle(color: ChifaColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (c.tables.isEmpty)
                    const EmptyState(
                      icon: Icons.cloud_download_outlined,
                      title: 'Sin mesas descargadas',
                      message: 'Vuelve al salón y actualiza los datos antes de asignar mesas.',
                    ),
                  ...c.tables.map((t) {
                    final other =
                        t.waiterId != null && t.waiterId != c.user!.id;
                    final locked =
                        t.waiterId == c.user!.id &&
                        (t.occupied || c.draftFor(t.id) != null);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Paper(
                        padding: EdgeInsets.zero,
                        child: CheckboxListTile(
                          value: _selected.contains(t.id),
                          onChanged: c.busy || other || locked
                              ? null
                              : (v) => setState(() {
                                  if (v!) {
                                    _selected.add(t.id);
                                  } else {
                                    _selected.remove(t.id);
                                  }
                                }),
                          title: Text(
                            'Mesa ${t.number.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            other
                                ? 'Asignada a otro mozo'
                                : locked
                                ? 'Con atención o borrador activo'
                                : '${t.zone} · ${t.seats} personas',
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            other
                                ? Icons.lock_outline_rounded
                                : Icons.table_restaurant_outlined,
                            color: other ? ChifaColors.muted : ChifaColors.gold,
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
                    key: _form,
                    child: TextFormField(
                      controller: _password,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      enabled: !c.busy,
                      decoration: const InputDecoration(
                        labelText: 'Clave del administrador',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'El administrador debe ingresar su clave'
                          : null,
                    ),
                  ),
                  if (c.isDemo)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Clave de prueba: 2468',
                        style: TextStyle(
                          fontSize: 12,
                          color: ChifaColors.muted,
                        ),
                      ),
                    ),
                  if (c.error != null) ErrorNotice(c.error!),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: c.busy || c.tables.isEmpty ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Confirmar ${_selected.length} mesas'),
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
