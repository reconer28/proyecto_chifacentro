import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.controller,
    required this.tableId,
  });
  final AppController controller;
  final String tableId;
  Future<void> _notes(
    BuildContext context,
    OrderLine line,
    MenuProduct product,
  ) async {
    final input = TextEditingController(text: line.notes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Un toque a su gusto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.name),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              autofocus: true,
              maxLength: 250,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej. sin cebolla, poco ají…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // Wait until the dialog route has disposed its text field before disposal.
    if (notes != null) {
      await controller.changeLine(tableId, product, notes: notes);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Future<void> _send(BuildContext context, bool pending) async {
    if (!pending) {
      final confirmed = await confirmAction(
        context,
        title: '¿Enviamos el pedido?',
        message: 'Revisa cantidades y observaciones. Una vez enviado, las correcciones requerirán autorización del administrador.',
        confirm: 'Enviar pedido',
      );
      if (!confirmed || !context.mounted) {
        return;
      }
    }
    final ok = await controller.sendOrder(tableId);
    if (ok && context.mounted) {
      notifySuccess(
        context,
        controller.isDemo
            ? 'Pedido registrado en la demostración'
            : 'Pedido recibido por el servidor',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final c = controller;
      final draft = c.draftFor(tableId);
      final table = c.tables.where((t) => t.id == tableId).firstOrNull;
      final editable = !c.busy && !(draft?.pending ?? false);
      return Scaffold(
        appBar: AppBar(title: const Text('Revisar pedido')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.table_restaurant_outlined,
                        color: ChifaColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mesa ${table?.number.toString().padLeft(2, '0') ?? '—'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      const Pill('NUEVO PEDIDO', color: ChifaColors.gold),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Todo en su punto.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirma los platos y agrega indicaciones para cocina.',
                    style: TextStyle(color: ChifaColors.muted, height: 1.5),
                  ),
                  if (draft?.pending ?? false)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Paper(
                        color: Color(0xFFFFF0D5),
                        child: Text(
                          'Este envío está pendiente de confirmación. Reintenta para consultar o completar el mismo pedido. Los platos permanecen bloqueados para evitar duplicados.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
                  if (c.error != null)
                    ErrorNotice(c.error!, onDismiss: c.clearError),
                  const SizedBox(height: 22),
                  if (draft == null || draft.lines.isEmpty)
                    const EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Aún no hay platos',
                      message: 'Vuelve a la carta para comenzar tu pedido.',
                    ),
                  ...?draft?.lines.map((line) {
                    final product = c.products
                        .where((p) => p.id == line.productId)
                        .firstOrNull;
                    // Allow removal of a product even if it disappeared from the latest menu.
                    final fallback =
                        product ??
                        MenuProduct(
                          id: line.productId,
                          name: line.name,
                          description: '',
                          category: '',
                          priceCents: line.priceCents,
                          available: false,
                        );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Paper(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    line.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  money(line.totalCents),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${money(line.priceCents)} por unidad',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChifaColors.muted,
                              ),
                            ),
                            if (product == null || !product.available)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'No disponible en la carta actual. Retira este plato.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChifaColors.red,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: QuantityControl(
                                quantity: line.quantity,
                                onAdd: editable && (product?.available ?? false)
                                    ? () => c.changeLine(
                                        tableId,
                                        fallback,
                                        delta: 1,
                                      )
                                    : null,
                                onRemove: editable
                                    ? () => c.changeLine(
                                        tableId,
                                        fallback,
                                        delta: -1,
                                      )
                                    : null,
                              ),
                            ),
                            const Divider(height: 25),
                            InkWell(
                              onTap: editable
                                  ? () => _notes(context, line, fallback)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_note_rounded,
                                      size: 20,
                                      color: ChifaColors.gold,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        line.notes.isEmpty
                                            ? 'Agregar observación'
                                            : line.notes,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: line.notes.isEmpty
                                              ? ChifaColors.muted
                                              : ChifaColors.ink,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: ChifaColors.muted,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (draft != null && draft.lines.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Paper(
                      color: const Color(0xFFF0E8DB),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total del pedido',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${draft.quantity} unidades',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ChifaColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(draft.totalCents),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: ChifaColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El servidor confirmará precios y disponibilidad al recibir el pedido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: ChifaColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: editable
                          ? () async {
                              final yes = await confirmAction(
                                context,
                                title: '¿Descartar borrador?',
                                message: 'Se quitarán los platos que todavía no has enviado.',
                                confirm: 'Descartar',
                              );
                              if (yes) {
                                await c.discardDraft(tableId);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Descartar este borrador'),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                  padding: const EdgeInsets.all(20),
                  child: FilledButton.icon(
                    onPressed: c.busy
                        ? null
                        : () => _send(context, draft.pending),
                    icon: Icon(
                      draft.pending ? Icons.sync_rounded : Icons.send_rounded,
                      size: 20,
                    ),
                    label: Text(
                      c.busy
                          ? 'Procesando…'
                          : draft.pending
                          ? 'Reintentar confirmación'
                          : 'Enviar pedido · ${money(draft.totalCents)}',
                    ),
                  ),
                ),
              ),
      );
    },
  );
}
