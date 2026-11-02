import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.controlador,
    required this.idMesa,
  });
  final AppController controlador;
  final String idMesa;
  Future<void> _editarObservaciones(
    BuildContext contexto,
    OrderLine detalle,
    MenuProduct producto,
  ) async {
    final entrada = TextEditingController(text: detalle.observaciones);
    final observaciones = await mostrarDialogoConCampos<String>(
      contexto,
      campos: [entrada],
      constructor: (contexto) => AlertDialog(
        title: const Text('Un toque a su gusto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detalle.nombre),
              const SizedBox(height: 16),
              TextField(
                controller: entrada,
                autofocus: true,
                maxLength: 250,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej. sin cebolla, poco ají…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, entrada.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (observaciones != null) {
      await controlador.modificarDetalle(
        idMesa,
        producto,
        observaciones: observaciones,
      );
    }
  }

  Future<void> _enviar(BuildContext contexto, bool pendiente) async {
    if (!pendiente) {
      final confirmado = await confirmarAccion(
        contexto,
        titulo: '¿Enviamos el pedido?',
        mensaje: 'Revisa cantidades y observaciones. Una vez enviado, las correcciones requerirán autorización del administrador.',
        confirmar: 'Enviar pedido',
      );
      if (!confirmado || !contexto.mounted) {
        return;
      }
    }
    final exito = await controlador.enviarPedido(idMesa);
    if (exito &&
        contexto.mounted &&
        ModalRoute.of(contexto)?.isCurrent == true) {
      mostrarConfirmacion(
        contexto,
        controlador.esDemo
            ? 'Pedido registrado en la demostración'
            : 'Pedido recibido por el servidor',
      );
      Navigator.pop(contexto);
    }
  }

  @override
  Widget build(BuildContext contexto) => AnimatedBuilder(
    animation: controlador,
    builder: (contexto, _) {
      final estadoAplicacion = controlador;
      final borrador = estadoAplicacion.borradorDeMesa(idMesa);
      final mesa = estadoAplicacion.mesas
          .where((mesaActual) => mesaActual.id == idMesa)
          .firstOrNull;
      final puedeDescartar =
          !estadoAplicacion.procesando && !(borrador?.pendiente ?? false);
      final esPropia =
          estadoAplicacion.usuario != null &&
          mesa?.idMozo == estadoAplicacion.usuario!.id;
      final puedeEditar = puedeDescartar && esPropia;
      return Scaffold(
        appBar: AppBar(title: const Text('Revisar pedido')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.table_restaurant_outlined,
                            color: ChifaColors.dorado,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Mesa ${mesa?.numero.toString().padLeft(2, '0') ?? '—'}',
                            style: Theme.of(contexto).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Pill('NUEVO PEDIDO', color: ChifaColors.dorado),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Todo en su punto.',
                    style: Theme.of(contexto).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirma los platos y agrega indicaciones para cocina.',
                    style: TextStyle(color: ChifaColors.tenue, height: 1.5),
                  ),
                  if (borrador?.pendiente ?? false)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Paper(
                        color: Color(0xFFFFF0D5),
                        contenido: Text(
                          'Este envío está pendiente de confirmación. Reintenta para consultar o completar el mismo pedido. Los platos permanecen bloqueados para evitar duplicados.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
                  if (estadoAplicacion.error != null)
                    ErrorNotice(
                      estadoAplicacion.error!,
                      alCerrar: estadoAplicacion.limpiarError,
                    ),
                  const SizedBox(height: 22),
                  if (borrador == null || borrador.detalles.isEmpty)
                    const EmptyState(
                      icono: Icons.shopping_bag_outlined,
                      titulo: 'Aún no hay platos',
                      mensaje: 'Vuelve a la carta para comenzar tu pedido.',
                    ),
                  ...?borrador?.detalles.map((detalle) {
                    final producto = estadoAplicacion.productos
                        .where(
                          (productoActual) =>
                              productoActual.id == detalle.idProducto,
                        )
                        .firstOrNull;
                    // Permite quitar un producto aunque ya no aparezca en la carta actual.
                    final productoAnterior =
                        producto ??
                        MenuProduct(
                          id: detalle.idProducto,
                          nombre: detalle.nombre,
                          descripcion: '',
                          categoria: '',
                          precioCentimos: detalle.precioCentimos,
                          disponible: false,
                        );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Paper(
                        contenido: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    detalle.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatearImporte(detalle.totalCentimos),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${formatearImporte(detalle.precioCentimos)} por unidad',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChifaColors.tenue,
                              ),
                            ),
                            if (producto == null || !producto.disponible)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'No disponible en la carta actual. Retira este plato.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChifaColors.rojo,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: QuantityControl(
                                cantidad: detalle.cantidad,
                                alAgregar:
                                    puedeEditar &&
                                        (producto?.disponible ?? false)
                                    ? () => estadoAplicacion.modificarDetalle(
                                        idMesa,
                                        productoAnterior,
                                        variacion: 1,
                                      )
                                    : null,
                                alQuitar: puedeEditar
                                    ? () => estadoAplicacion.modificarDetalle(
                                        idMesa,
                                        productoAnterior,
                                        variacion: -1,
                                      )
                                    : null,
                              ),
                            ),
                            const Divider(height: 25),
                            InkWell(
                              onTap: puedeEditar
                                  ? () => _editarObservaciones(
                                      contexto,
                                      detalle,
                                      productoAnterior,
                                    )
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
                                      color: ChifaColors.dorado,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        detalle.observaciones.isEmpty
                                            ? 'Agregar observación'
                                            : detalle.observaciones,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: detalle.observaciones.isEmpty
                                              ? ChifaColors.tenue
                                              : ChifaColors.tinta,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: ChifaColors.tenue,
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
                  if (borrador != null && borrador.detalles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Paper(
                      color: const Color(0xFFF0E8DB),
                      contenido: Row(
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
                                  '${borrador.cantidad} unidades',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ChifaColors.tenue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatearImporte(borrador.totalCentimos),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: ChifaColors.rojo,
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
                        color: ChifaColors.tenue,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: puedeDescartar
                          ? () async {
                              final autorizado = await confirmarAccion(
                                contexto,
                                titulo: '¿Descartar borrador?',
                                mensaje: 'Se quitarán los platos que todavía no has enviado.',
                                confirmar: 'Descartar',
                              );
                              if (autorizado) {
                                await estadoAplicacion.descartarBorrador(
                                  idMesa,
                                );
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
        bottomNavigationBar: borrador == null || borrador.detalles.isEmpty
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: FilledButton.icon(
                    onPressed:
                        estadoAplicacion.procesando ||
                            (!esPropia && !borrador.pendiente)
                        ? null
                        : () => _enviar(contexto, borrador.pendiente),
                    icon: Icon(
                      borrador.pendiente
                          ? Icons.sync_rounded
                          : Icons.send_rounded,
                      size: 20,
                    ),
                    label: Text(
                      estadoAplicacion.procesando
                          ? 'Procesando…'
                          : borrador.pendiente
                          ? 'Reintentar confirmación'
                          : 'Enviar pedido · ${formatearImporte(borrador.totalCentimos)}',
                    ),
                  ),
                ),
              ),
      );
    },
  );
}
