import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import 'account_screen.dart';
import 'orders_screen.dart';
import 'tables_screen.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controlador});
  final AppController controlador;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _indice = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.controlador.procesando) {
      widget.controlador.actualizarDatos();
    }
  }

  @override
  Widget build(BuildContext contexto) {
    final estadoAplicacion = widget.controlador;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 22,
        title: const Brand(compacta: true),
        actions: [
          IconButton(
            onPressed: estadoAplicacion.procesando
                ? null
                : estadoAplicacion.actualizarDatos,
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.sync_rounded, color: ChifaColors.tenue),
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: estadoAplicacion.procesando
              ? const LinearProgressIndicator(minHeight: 3)
              : const SizedBox(height: 3),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              children: [
                if (estadoAplicacion.esDemo)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF0E7D7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 7,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 14,
                          color: ChifaColors.dorado,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Demostración · Datos de ejemplo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ChifaColors.tenue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (estadoAplicacion.error != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: ErrorNotice(
                        estadoAplicacion.error!,
                        alCerrar: estadoAplicacion.limpiarError,
                      ),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _indice,
                    children: [
                      TablesScreen(controlador: estadoAplicacion),
                      OrdersScreen(controlador: estadoAplicacion),
                      AccountScreen(controlador: estadoAplicacion),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(
              Icons.grid_view_rounded,
              color: ChifaColors.rojo,
            ),
            label: 'Mis mesas',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(
              Icons.receipt_long_rounded,
              color: ChifaColors.rojo,
            ),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: ChifaColors.rojo),
            label: 'Mi cuenta',
          ),
        ],
      ),
    );
  }
}
