import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'orders_screen.dart';
import 'review_screen.dart';
import 'widgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.controller,
    required this.tableId,
  });
  final AppController controller;
  final String tableId;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _search = TextEditingController();
  String _category = 'Todos';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    var value = s.toLowerCase();
    const accented = 'áéíóúüñ';
    const plain = 'aeiouun';
    for (var i = 0; i < accented.length; i++) {
      value = value.replaceAll(accented[i], plain[i]);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final table = c.tables.where((t) => t.id == widget.tableId).firstOrNull;
      final own = table?.waiterId == c.user?.id;
      final draft = c.draftFor(widget.tableId);
      final categories = [
        'Todos',
        ...c.products.map((p) => p.category).toSet(),
      ];
      final visible = c.products
          .where(
            (p) =>
                (_category == 'Todos' || p.category == _category) &&
                _normalize('${p.name} ${p.description}')
                    .contains(_normalize(_search.text.trim())),
          )
          .toList();
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa ${table?.number.toString().padLeft(2, '0') ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                Text(
                  table?.zone ?? 'Mesa no disponible',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChifaColors.muted,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: c.busy ? null : c.refresh,
                tooltip: 'Actualizar carta y pedidos',
                icon: const Icon(Icons.sync_rounded),
              ),
              const SizedBox(width: 8),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'La carta'),
                Tab(text: 'Cuenta de mesa'),
              ],
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    if (c.busy) const LinearProgressIndicator(minHeight: 2),
                    if (c.error != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 145),
                        child: SingleChildScrollView(
                          child: ErrorNotice(c.error!, onDismiss: c.clearError),
                        ),
                      ),
                    if (!own)
                      const ErrorNotice(
                        'Esta mesa ya no está asignada a tu usuario. Vuelve al salón y actualiza.',
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  22,
                                  22,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Pill(
                                      'DEL WOK A TU MESA',
                                      color: ChifaColors.gold,
                                      icon:
                                          Icons.local_fire_department_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '¿Qué van a disfrutar?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _search,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar un plato o bebida',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                        ),
                                        suffixIcon: _search.text.isEmpty
                                            ? null
                                            : IconButton(
                                                onPressed: () => setState(
                                                  () => _search.clear(),
                                                ),
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                                tooltip: 'Limpiar búsqueda',
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                child: Row(
                                  children: categories
                                      .map(
                                        (cat) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(cat),
                                            showCheckmark: false,
                                            selected: cat == _category,
                                            onSelected: (_) =>
                                                setState(() => _category = cat),
                                            selectedColor: ChifaColors.red,
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color(0xFFE7E0D6),
                                            ),
                                            labelStyle: TextStyle(
                                              fontSize: 12,
                                              color: cat == _category
                                                  ? Colors.white
                                                  : ChifaColors.muted,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  16,
                                  22,
                                  10,
                                ),
                                child: Text(
                                  '${visible.length} opciones para compartir',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ChifaColors.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: visible.isEmpty
                                    ? const SingleChildScrollView(
                                        child: EmptyState(
                                          icon: Icons.search_off_rounded,
                                          title: 'No encontramos ese sabor',
                                          message: 'Prueba con otro nombre o categoría.',
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          22,
                                          0,
                                          22,
                                          22,
                                        ),
                                        itemCount: visible.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          final p = visible[i];
                                          final quantity =
                                              draft?.lines
                                                  .where(
                                                    (l) => l.productId == p.id,
                                                  )
                                                  .firstOrNull
                                                  ?.quantity ??
                                              0;
                                          final editable =
                                              own &&
                                              !c.busy &&
                                              !(draft?.pending ?? false);
                                          return Paper(
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Opacity(
                                                  opacity: p.available ? 1 : .4,
                                                  child: DishArt(
                                                    category: p.category,
                                                    size: 76,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (p.featured &&
                                                          p.available)
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                bottom: 5,
                                                              ),
                                                          child: Text(
                                                            'FAVORITO DE LA CASA',
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              letterSpacing: .8,
                                                              color: ChifaColors
                                                                  .gold,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ),
                                                      Text(
                                                        p.name,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        p.description,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          height: 1.45,
                                                          color:
                                                              ChifaColors.muted,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        money(p.priceCents),
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              ChifaColors.red,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: !p.available
                                                            ? const Pill(
                                                                'Agotado',
                                                                color:
                                                                    ChifaColors
                                                                        .muted,
                                                              )
                                                            : quantity == 0
                                                            ? IconButton.filled(
                                                                onPressed:
                                                                    editable
                                                                    ? () => c.changeLine(
                                                                        widget
                                                                            .tableId,
                                                                        p,
                                                                        delta:
                                                                            1,
                                                                      )
                                                                    : null,
                                                                tooltip:
                                                                    'Agregar ${p.name}',
                                                                icon: const Icon(
                                                                  Icons
                                                                      .add_rounded,
                                                                ),
                                                                style: IconButton.styleFrom(
                                                                  minimumSize:
                                                                      const Size(
                                                                        44,
                                                                        44,
                                                                      ),
                                                                ),
                                                              )
                                                            : QuantityControl(
                                                                quantity:
                                                                    quantity,
                                                                onAdd: editable
                                                                    ? () => c.changeLine(
                                                                        widget
                                                                            .tableId,
                                                                        p,
                                                                        delta:
                                                                            1,
                                                                      )
                                                                    : null,
                                                                onRemove:
                                                                    editable
                                                                    ? () => c.changeLine(
                                                                        widget
                                                                            .tableId,
                                                                        p,
                                                                        delta:
                                                                            -1,
                                                                      )
                                                                    : null,
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                          TableAccount(controller: c, tableId: widget.tableId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: draft == null || draft.lines.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    child: FilledButton(
                      onPressed: c.busy
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ReviewScreen(
                                  controller: c,
                                  tableId: widget.tableId,
                                ),
                              ),
                            ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${draft.quantity}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              draft.pending
                                  ? 'Confirmar envío'
                                  : 'Ver mi pedido',
                            ),
                          ),
                          Text(money(draft.totalCents)),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );
}
