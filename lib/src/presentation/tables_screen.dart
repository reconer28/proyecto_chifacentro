import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'assignment_screen.dart';
import 'menu_screen.dart';
import 'widgets.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String _filter = 'Todas';
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tables = c.myTables;
    final occupied = tables.where((t) => t.occupied).length;
    final filtered = tables
        .where(
          (t) => switch (_filter) {
            'Libres' => !t.occupied,
            'En atención' => t.occupied,
            'Borradores' => c.draftFor(t.id) != null,
            _ => true,
          },
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await c.refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${c.user!.name.split(' ').first}',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Una buena atención empieza aquí.',
                              style: TextStyle(
                                color: ChifaColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEADFCF),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.user!.name.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ChifaColors.gold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 23),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: ChifaColors.red,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.wb_sunny_outlined,
                              size: 16,
                              color: Color(0xFFECC98E),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TU SALÓN, DE UN VISTAZO',
                                style: TextStyle(
                                  color: Color(0xFFECC98E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _Stat('${tables.length}', 'Asignadas'),
                            _Stat('$occupied', 'En atención'),
                            _Stat('${tables.length - occupied}', 'Libres'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mis mesas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AssignmentScreen(controller: c),
                                ),
                              ),
                        icon: const Icon(Icons.tune_rounded, size: 17),
                        label: const Text('Asignar'),
                      ),
                    ],
                  ),
                  const Text(
                    'Selecciona una mesa para tomar su pedido.',
                    style: TextStyle(color: ChifaColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todas', 'Libres', 'En atención', 'Borradores']
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                                showCheckmark: false,
                                selectedColor: ChifaColors.ink,
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFE4DCD0),
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: _filter == f
                                      ? Colors.white
                                      : ChifaColors.muted,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.table_restaurant_outlined,
                title: tables.isEmpty
                    ? 'Tu turno empieza con una mesa'
                    : 'Sin mesas en este estado',
                message: tables.isEmpty
                    ? 'Asigna tus mesas con la autorización del administrador. Si aún están cargando, usa actualizar.'
                    : 'Prueba con otro filtro para ver tus mesas.',
                action: tables.isEmpty
                    ? FilledButton(
                        onPressed: c.busy
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AssignmentScreen(controller: c),
                                ),
                              ),
                        child: const Text('Asignar mis mesas'),
                      )
                    : null,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.crossAxisExtent < 285
                      ? 1
                      : (constraints.crossAxisExtent > 620 ? 3 : 2),
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(225),
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final t = filtered[i];
                  final draft = c.draftFor(t.id);
                  return _TableCard(
                    table: t,
                    draft: draft,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MenuScreen(controller: c, tableId: t.id),
                      ),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 15,
                    color: ChifaColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      c.lastUpdated == null
                          ? 'Desliza hacia abajo para actualizar'
                          : 'Actualizado a las ${TimeOfDay.fromDateTime(c.lastUpdated!).format(context)} · Desliza para actualizar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ChifaColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.number, this.label);
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFEBCBC3)),
        ),
      ],
    ),
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.draft,
    required this.onTap,
  });
  final DiningTable table;
  final OrderDraft? draft;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = table.occupied ? ChifaColors.red : ChifaColors.green;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: table.occupied
              ? const Color(0xFFE7C4BC)
              : const Color(0xFFE6E1D7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    '${table.seats} personas',
                    style: const TextStyle(
                      fontSize: 10,
                      color: ChifaColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 45,
                  color: table.occupied
                      ? ChifaColors.red
                      : const Color(0xFFB6A48A),
                ),
              ),
              const Spacer(),
              Text(
                'Mesa ${table.number.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                table.zone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: ChifaColors.muted),
              ),
              const SizedBox(height: 12),
              if (draft != null)
                Pill(
                  draft!.pending
                      ? 'Por confirmar'
                      : 'Borrador · ${draft!.quantity}',
                  color: ChifaColors.gold,
                  icon: Icons.edit_note_rounded,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        table.occupied ? 'En atención' : 'Disponible',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (table.occupied)
                      Text(
                        money(table.totalCents),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_rounded, size: 17, color: color),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
