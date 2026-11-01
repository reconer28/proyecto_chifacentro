import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'review_screen.dart';
import 'widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'En atención';
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final orders = c.myOrders
        .where(
          (o) => switch (_filter) {
            'En atención' =>
              o.closedAt == null && o.status != OrderStatus.cancelled,
            'Finalizados' =>
              o.closedAt != null || o.status == OrderStatus.cancelled,
            _ => true,
          },
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await c.refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          const Pill(
            'CADA PEDIDO CUENTA',
            color: ChifaColors.gold,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          Text('Mis pedidos', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text(
            'Consulta el detalle y acompaña cada atención.',
            style: TextStyle(color: ChifaColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (c.drafts.isNotEmpty) ...[
            Text(
              'Borradores guardados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...c.drafts.values.map((d) {
              final table = c.tables
                  .where((t) => t.id == d.tableId)
                  .firstOrNull;
              final own = table?.waiterId == c.user?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Paper(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      d.pending ? Icons.sync_rounded : Icons.edit_note_rounded,
                      color: ChifaColors.gold,
                    ),
                    title: Text(
                      'Mesa ${table?.number.toString().padLeft(2, '0') ?? d.tableId}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${d.quantity} unidades · ${money(d.totalCents)}\n${d.pending
                          ? 'Envío por confirmar'
                          : own
                          ? 'Continúa tu pedido'
                          : 'Mesa reasignada: puedes descartar el borrador'}',
                      style: const TextStyle(fontSize: 11, height: 1.5),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ReviewScreen(controller: c, tableId: d.tableId),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['En atención', 'Finalizados', 'Todos']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        showCheckmark: false,
                        selectedColor: ChifaColors.ink,
                        labelStyle: TextStyle(
                          color: _filter == f
                              ? Colors.white
                              : ChifaColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Todo empieza en la mesa',
              message: 'Los pedidos que envíes aparecerán aquí. Desliza hacia abajo para actualizar su estado.',
            ),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderCard(order: o, controller: c),
            ),
          ),
        ],
      ),
    );
  }
}

class TableAccount extends StatelessWidget {
  const TableAccount({
    super.key,
    required this.controller,
    required this.tableId,
  });
  final AppController controller;
  final String tableId;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final orders = c.myOrders
        .where((o) => o.tableId == tableId && o.closedAt == null)
        .toList();
    final active = orders.where((o) => o.status != OrderStatus.cancelled);
    final total = active.fold<int>(0, (sum, o) => sum + o.totalCents);
    final canClose =
        orders.isNotEmpty &&
        active.every((o) => o.status == OrderStatus.delivered) &&
        c.draftFor(tableId) == null;
    return RefreshIndicator(
      onRefresh: () async {
        await c.refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            'La atención de esta mesa',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aquí se agrupan los pedidos de la atención actual.',
            style: TextStyle(
              color: ChifaColors.muted,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Paper(
            color: const Color(0xFFF0E8DB),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total enviado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  money(total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ChifaColors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            const EmptyState(
              icon: Icons.restaurant_outlined,
              title: 'La mesa está lista',
              message: 'Agrega platos desde la carta y envía el primer pedido.',
            ),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderCard(order: o, controller: c),
            ),
          ),
          if (orders.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: c.busy || !canClose
                  ? null
                  : () async {
                      final yes = await confirmAction(
                        context,
                        title: '¿Finalizar la atención?',
                        message:
                            'El total enviado es ${money(total)}. La mesa quedará disponible para una nueva atención. Esta acción no registra un pago.',
                        confirm: 'Cerrar mesa',
                      );
                      if (yes) {
                        final ok = await c.closeTable(tableId);
                        if (ok && context.mounted) {
                          notifySuccess(
                            context,
                            'Atención finalizada. La mesa está disponible.',
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Finalizar atención y liberar mesa'),
            ),
            const SizedBox(height: 10),
            Text(
              canClose
                  ? 'La asignación a tu usuario se conserva durante el turno.'
                  : 'Entrega los pedidos y envía o descarta el borrador antes de cerrar.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: ChifaColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.controller});
  final ServiceOrder order;
  final AppController controller;
  Color get _color => switch (order.status) {
    OrderStatus.sent => ChifaColors.gold,
    OrderStatus.preparing => ChifaColors.red,
    OrderStatus.ready || OrderStatus.delivered => ChifaColors.green,
    OrderStatus.cancelled => ChifaColors.muted,
  };
  Future<void> _cancel(BuildContext context) async {
    final reason = TextEditingController();
    final password = TextEditingController();
    final form = GlobalKey<FormState>();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular pedido'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Se anulará el pedido completo. El administrador debe autorizar esta acción.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reason,
                  maxLength: 250,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de anulación',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Indica el motivo' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Clave del administrador',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa la clave' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, (reason.text.trim(), password.text));
              }
            },
            child: const Text('Anular pedido'),
          ),
        ],
      ),
    );
    if (values != null) {
      final ok = await controller.cancelOrder(order.id, values.$1, values.$2);
      if (ok && context.mounted) {
        notifySuccess(context, 'Pedido anulado con autorización');
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    reason.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canChange =
        order.closedAt == null &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered;
    return Paper(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                money(order.totalCents),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id} · ${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')} · ${TimeOfDay.fromDateTime(order.createdAt).format(context)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChifaColors.muted,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(order.status.label, color: _color),
                    if (order.closedAt != null)
                      const Pill('Mesa cerrada', color: ChifaColors.muted),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(),
            ...order.lines.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.quantity}×',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ChifaColors.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          money(l.totalCents),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (l.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 26),
                        child: Text(
                          l.notes,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChifaColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (order.cancellationReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Motivo: ${order.cancellationReason}',
                  style: const TextStyle(
                    color: ChifaColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            if (canChange) ...[
              const Divider(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final yes = await confirmAction(
                            context,
                            title: '¿Pedido entregado?',
                            message: 'Confirma que todos los platos de este pedido ya llegaron a la mesa.',
                            confirm: 'Marcar entregado',
                          );
                          if (yes) {
                            await controller.deliverOrder(order.id);
                          }
                        },
                  icon: const Icon(Icons.room_service_outlined, size: 19),
                  label: const Text('Marcar como entregado'),
                ),
              ),
              if (order.status == OrderStatus.sent)
                TextButton.icon(
                  onPressed: controller.busy ? null : () => _cancel(context),
                  icon: const Icon(Icons.block_outlined, size: 16),
                  label: const Text(
                    'Anular con autorización',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
