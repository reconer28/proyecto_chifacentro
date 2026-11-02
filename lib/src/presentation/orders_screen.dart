import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'review_screen.dart';
import 'widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.controlador});
  final AppController controlador;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filtro = 'En atención';
  @override
  Widget build(BuildContext contexto) {
    final estadoAplicacion = widget.controlador;
    final pedidos = estadoAplicacion.misPedidos
        .where(
          (pedidoActual) => switch (_filtro) {
            'En atención' =>
              pedidoActual.fechaCierre == null &&
                  pedidoActual.estado != OrderStatus.cancelled,
            'Finalizados' =>
              pedidoActual.fechaCierre != null ||
                  pedidoActual.estado == OrderStatus.cancelled,
            _ => true,
          },
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await estadoAplicacion.actualizarDatos();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          const Pill(
            'CADA PEDIDO CUENTA',
            color: ChifaColors.dorado,
            icono: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'Mis pedidos',
            style: Theme.of(contexto).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta el detalle y acompaña cada atención.',
            style: TextStyle(color: ChifaColors.tenue, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (estadoAplicacion.borradores.isNotEmpty) ...[
            Text(
              'Borradores guardados',
              style: Theme.of(contexto).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...estadoAplicacion.borradores.values.map((borradorActual) {
              final mesa = estadoAplicacion.mesas
                  .where((mesaActual) => mesaActual.id == borradorActual.idMesa)
                  .firstOrNull;
              final esPropia = mesa?.idMozo == estadoAplicacion.usuario?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Paper(
                  relleno: EdgeInsets.zero,
                  contenido: ListTile(
                    leading: Icon(
                      borradorActual.pendiente
                          ? Icons.sync_rounded
                          : Icons.edit_note_rounded,
                      color: ChifaColors.dorado,
                    ),
                    title: Text(
                      'Mesa ${mesa?.numero.toString().padLeft(2, '0') ?? borradorActual.idMesa}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${borradorActual.cantidad} unidades · ${formatearImporte(borradorActual.totalCentimos)}\n${borradorActual.pendiente
                          ? 'Envío por confirmar'
                          : esPropia
                          ? 'Continúa tu pedido'
                          : 'Mesa reasignada: puedes descartar el borrador'}',
                      style: const TextStyle(fontSize: 11, height: 1.5),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: estadoAplicacion.procesando
                        ? null
                        : () => Navigator.push(
                            contexto,
                            MaterialPageRoute<void>(
                              builder: (_) => ReviewScreen(
                                controlador: estadoAplicacion,
                                idMesa: borradorActual.idMesa,
                              ),
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
                    (filtroActual) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filtroActual),
                        selected: _filtro == filtroActual,
                        onSelected: (_) =>
                            setState(() => _filtro = filtroActual),
                        showCheckmark: false,
                        selectedColor: ChifaColors.tinta,
                        labelStyle: TextStyle(
                          color: _filtro == filtroActual
                              ? Colors.white
                              : ChifaColors.tenue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (pedidos.isEmpty)
            const EmptyState(
              icono: Icons.receipt_long_outlined,
              titulo: 'Todo empieza en la mesa',
              mensaje: 'Los pedidos que envíes aparecerán aquí. Desliza hacia abajo para actualizar su estado.',
            ),
          ...pedidos.map(
            (pedidoActual) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderCard(
                pedido: pedidoActual,
                controlador: estadoAplicacion,
              ),
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
    required this.controlador,
    required this.idMesa,
  });
  final AppController controlador;
  final String idMesa;
  @override
  Widget build(BuildContext contexto) {
    final estadoAplicacion = controlador;
    final pedidos = estadoAplicacion.misPedidos
        .where(
          (pedidoActual) =>
              pedidoActual.idMesa == idMesa && pedidoActual.fechaCierre == null,
        )
        .toList();
    final activos = pedidos.where(
      (pedidoActual) => pedidoActual.estado != OrderStatus.cancelled,
    );
    final total = activos.fold<int>(
      0,
      (suma, pedidoActual) => suma + pedidoActual.totalCentimos,
    );
    final puedeCerrar =
        pedidos.isNotEmpty &&
        activos.every(
          (pedidoActual) => pedidoActual.estado == OrderStatus.delivered,
        ) &&
        estadoAplicacion.borradorDeMesa(idMesa) == null;
    return RefreshIndicator(
      onRefresh: () async {
        await estadoAplicacion.actualizarDatos();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            'La atención de esta mesa',
            style: Theme.of(contexto).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aquí se agrupan los pedidos de la atención actual.',
            style: TextStyle(
              color: ChifaColors.tenue,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Paper(
            color: const Color(0xFFF0E8DB),
            contenido: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total enviado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  formatearImporte(total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ChifaColors.rojo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (pedidos.isEmpty)
            const EmptyState(
              icono: Icons.restaurant_outlined,
              titulo: 'La mesa está lista',
              mensaje: 'Agrega platos desde la carta y envía el primer pedido.',
            ),
          ...pedidos.map(
            (pedidoActual) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderCard(
                pedido: pedidoActual,
                controlador: estadoAplicacion,
              ),
            ),
          ),
          if (pedidos.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: estadoAplicacion.procesando || !puedeCerrar
                  ? null
                  : () async {
                      final autorizado = await confirmarAccion(
                        contexto,
                        titulo: '¿Finalizar la atención?',
                        mensaje:
                            'El total enviado es ${formatearImporte(total)}. La mesa quedará disponible para una nueva atención. Esta acción no registra un pago.',
                        confirmar: 'Cerrar mesa',
                      );
                      if (autorizado) {
                        final exito = await estadoAplicacion.cerrarMesa(idMesa);
                        if (exito && contexto.mounted) {
                          mostrarConfirmacion(
                            contexto,
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
              puedeCerrar
                  ? 'La asignación a tu usuario se conserva durante el turno.'
                  : 'Entrega los pedidos y envía o descarta el borrador antes de cerrar.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: ChifaColors.tenue,
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
  const OrderCard({super.key, required this.pedido, required this.controlador});
  final ServiceOrder pedido;
  final AppController controlador;
  Color get _color => switch (pedido.estado) {
    OrderStatus.sent => ChifaColors.dorado,
    OrderStatus.preparing => ChifaColors.rojo,
    OrderStatus.ready || OrderStatus.delivered => ChifaColors.verde,
    OrderStatus.cancelled => ChifaColors.tenue,
  };
  Future<void> _anular(BuildContext contexto) async {
    final motivo = TextEditingController();
    final contrasena = TextEditingController();
    final form = GlobalKey<FormState>();
    final valores = await mostrarDialogoConCampos<(String, String)>(
      contexto,
      campos: [motivo, contrasena],
      constructor: (contexto) => AlertDialog(
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
                  controller: motivo,
                  maxLength: 250,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de anulación',
                  ),
                  validator: (valorActual) =>
                      valorActual == null || valorActual.trim().isEmpty
                      ? 'Indica el motivo'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contrasena,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Clave del administrador',
                  ),
                  validator: (valorActual) =>
                      valorActual == null || valorActual.isEmpty
                      ? 'Ingresa la clave'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(contexto, (motivo.text.trim(), contrasena.text));
              }
            },
            child: const Text('Anular pedido'),
          ),
        ],
      ),
    );
    if (valores != null) {
      final exito = await controlador.anularPedido(
        pedido.id,
        valores.$1,
        valores.$2,
      );
      if (exito && contexto.mounted) {
        mostrarConfirmacion(contexto, 'Pedido anulado con autorización');
      }
    }
  }

  @override
  Widget build(BuildContext contexto) {
    final puedeModificar =
        pedido.fechaCierre == null &&
        pedido.estado != OrderStatus.cancelled &&
        pedido.estado != OrderStatus.delivered;
    return Paper(
      relleno: EdgeInsets.zero,
      contenido: Theme(
        data: Theme.of(contexto).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Mesa ${pedido.numeroMesa.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                formatearImporte(pedido.totalCentimos),
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
                  '#${pedido.id} · ${pedido.fechaCreacion.day.toString().padLeft(2, '0')}/${pedido.fechaCreacion.month.toString().padLeft(2, '0')} · ${TimeOfDay.fromDateTime(pedido.fechaCreacion).format(contexto)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChifaColors.tenue,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(pedido.estado.etiqueta, color: _color),
                    if (pedido.fechaCierre != null)
                      const Pill('Mesa cerrada', color: ChifaColors.tenue),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(),
            ...pedido.detalles.map(
              (detalleActual) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${detalleActual.cantidad}×',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ChifaColors.rojo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            detalleActual.nombre,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatearImporte(detalleActual.totalCentimos),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (detalleActual.observaciones.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 26),
                        child: Text(
                          detalleActual.observaciones,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChifaColors.tenue,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (pedido.motivoAnulacion != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Motivo: ${pedido.motivoAnulacion}',
                  style: const TextStyle(
                    color: ChifaColors.tenue,
                    fontSize: 12,
                  ),
                ),
              ),
            if (puedeModificar) ...[
              const Divider(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: controlador.procesando
                      ? null
                      : () async {
                          final autorizado = await confirmarAccion(
                            contexto,
                            titulo: '¿Pedido entregado?',
                            mensaje: 'Confirma que todos los platos de este pedido ya llegaron a la mesa.',
                            confirmar: 'Marcar entregado',
                          );
                          if (autorizado) {
                            await controlador.entregarPedido(pedido.id);
                          }
                        },
                  icon: const Icon(Icons.room_service_outlined, size: 19),
                  label: const Text('Marcar como entregado'),
                ),
              ),
              if (pedido.estado == OrderStatus.sent)
                TextButton.icon(
                  onPressed: controlador.procesando
                      ? null
                      : () => _anular(contexto),
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
