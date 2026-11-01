import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import 'account_screen.dart';
import 'orders_screen.dart';
import 'tables_screen.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
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
    if (state == AppLifecycleState.resumed && !widget.controller.busy) {
      widget.controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 22,
        title: const Brand(compact: true),
        actions: [
          IconButton(
            onPressed: c.busy ? null : c.refresh,
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.sync_rounded, color: ChifaColors.muted),
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: c.busy
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
                if (c.isDemo)
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
                          color: ChifaColors.gold,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Demostración · Datos de ejemplo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ChifaColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (c.error != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: ErrorNotice(c.error!, onDismiss: c.clearError),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: [
                      TablesScreen(controller: c),
                      OrdersScreen(controller: c),
                      AccountScreen(controller: c),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: ChifaColors.red),
            label: 'Mis mesas',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(
              Icons.receipt_long_rounded,
              color: ChifaColors.red,
            ),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: ChifaColors.red),
            label: 'Mi cuenta',
          ),
        ],
      ),
    );
  }
}
