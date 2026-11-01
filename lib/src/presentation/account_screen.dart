import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../data/demo_repository.dart';
import 'assignment_screen.dart';
import 'widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final demo = c.repository is DemoRepository
        ? c.repository as DemoRepository
        : null;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('Mi cuenta', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          'Todo listo para un gran servicio.',
          style: TextStyle(color: ChifaColors.muted),
        ),
        const SizedBox(height: 25),
        Paper(
          child: Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFFF1E3D0),
                child: Text(
                  c.user!.name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 32,
                    color: ChifaColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(c.user!.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              Text(
                '@${c.user!.username} · Mozo',
                style: const TextStyle(color: ChifaColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Pill(
                'Sesión activa',
                icon: Icons.check_circle_outline_rounded,
              ),
              const Divider(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${c.myTables.length}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Mesas asignadas',
                        style: TextStyle(
                          fontSize: 11,
                          color: ChifaColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${c.drafts.length}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Borradores guardados',
                        style: TextStyle(
                          fontSize: 11,
                          color: ChifaColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'MI TURNO',
          style: TextStyle(
            fontSize: 10,
            color: ChifaColors.muted,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Paper(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.table_restaurant_outlined,
                  color: ChifaColors.gold,
                ),
                title: const Text(
                  'Asignar mis mesas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Requiere clave del administrador',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: c.busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AssignmentScreen(controller: c),
                        ),
                      ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.sync_rounded,
                  color: ChifaColors.gold,
                ),
                title: const Text(
                  'Actualizar datos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Mesas, carta y estados de los pedidos',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: c.busy ? null : c.refresh,
              ),
            ],
          ),
        ),
        if (demo != null) ...[
          const SizedBox(height: 22),
          const Text(
            'DEMOSTRACIÓN',
            style: TextStyle(
              fontSize: 10,
              color: ChifaColors.muted,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Paper(
            color: const Color(0xFFF0E9DD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      color: ChifaColors.gold,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Explora el flujo completo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Los platos, precios y mesas son ejemplos. Los pedidos se guardan en este celular para probar la atención.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: ChifaColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Simular falta de conexión',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Prueba la recuperación de un envío',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: demo.offline,
                  onChanged: c.busy
                      ? null
                      : (v) {
                          setState(() => demo.offline = v);
                          c.clearError();
                        },
                ),
                const Text(
                  'Administrador: 2468',
                  style: TextStyle(fontSize: 11, color: ChifaColors.muted),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: c.busy
              ? null
              : () async {
                  final yes = await confirmAction(
                    context,
                    title: '¿Cerrar sesión?',
                    message: 'Tus borradores quedarán guardados para cuando vuelvas a ingresar con este usuario.',
                    confirm: 'Cerrar sesión',
                  );
                  if (yes) {
                    await c.logout();
                  }
                },
          icon: const Icon(Icons.logout_rounded, size: 19),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 30),
        const Center(child: Brand(compact: true)),
        const SizedBox(height: 14),
        const Text(
          'El sabor de siempre. Un servicio más ágil.\nVersión 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, height: 1.8, color: ChifaColors.muted),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
