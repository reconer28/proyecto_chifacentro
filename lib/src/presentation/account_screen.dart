import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../data/demo_repository.dart';
import 'assignment_screen.dart';
import 'widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controlador});
  final AppController controlador;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext contexto) {
    final estadoAplicacion = widget.controlador;
    final demo = estadoAplicacion.repositorio is DemoRepository
        ? estadoAplicacion.repositorio as DemoRepository
        : null;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('Mi cuenta', style: Theme.of(contexto).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          'Todo listo para un gran servicio.',
          style: TextStyle(color: ChifaColors.tenue),
        ),
        const SizedBox(height: 25),
        Paper(
          contenido: Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFFF1E3D0),
                child: Text(
                  estadoAplicacion.usuario!.nombre.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 32,
                    color: ChifaColors.dorado,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                estadoAplicacion.usuario!.nombre,
                style: Theme.of(contexto).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                '@${estadoAplicacion.usuario!.nombreUsuario} · Mozo',
                style: const TextStyle(color: ChifaColors.tenue, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Pill(
                'Sesión activa',
                icono: Icons.check_circle_outline_rounded,
              ),
              const Divider(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${estadoAplicacion.misMesas.length}',
                        style: Theme.of(contexto).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Mesas asignadas',
                        style: TextStyle(
                          fontSize: 11,
                          color: ChifaColors.tenue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${estadoAplicacion.borradores.length}',
                        style: Theme.of(contexto).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Borradores guardados',
                        style: TextStyle(
                          fontSize: 11,
                          color: ChifaColors.tenue,
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
            color: ChifaColors.tenue,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Paper(
          relleno: EdgeInsets.zero,
          contenido: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.table_restaurant_outlined,
                  color: ChifaColors.dorado,
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
                onTap: estadoAplicacion.procesando
                    ? null
                    : () => Navigator.push(
                        contexto,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AssignmentScreen(controlador: estadoAplicacion),
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
                  color: ChifaColors.dorado,
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
                onTap: estadoAplicacion.procesando
                    ? null
                    : estadoAplicacion.actualizarDatos,
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
              color: ChifaColors.tenue,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Paper(
            color: const Color(0xFFF0E9DD),
            contenido: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      color: ChifaColors.dorado,
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
                    color: ChifaColors.tenue,
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
                  value: demo.sinConexion,
                  onChanged: estadoAplicacion.procesando
                      ? null
                      : (valorActual) {
                          setState(() => demo.sinConexion = valorActual);
                          estadoAplicacion.limpiarError();
                        },
                ),
                const Text(
                  'Administrador: 2468',
                  style: TextStyle(fontSize: 11, color: ChifaColors.tenue),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: estadoAplicacion.procesando
              ? null
              : () async {
                  final autorizado = await confirmarAccion(
                    contexto,
                    titulo: '¿Cerrar sesión?',
                    mensaje: 'Tus borradores quedarán guardados para cuando vuelvas a ingresar con este usuario.',
                    confirmar: 'Cerrar sesión',
                  );
                  if (autorizado) {
                    await estadoAplicacion.cerrarSesion();
                  }
                },
          icon: const Icon(Icons.logout_rounded, size: 19),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 30),
        const Center(child: Brand(compacta: true)),
        const SizedBox(height: 14),
        const Text(
          'El sabor de siempre. Un servicio más ágil.\nVersión 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, height: 1.8, color: ChifaColors.tenue),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
