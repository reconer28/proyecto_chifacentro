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
    required this.controlador,
    required this.idMesa,
  });
  final AppController controlador;
  final String idMesa;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _busqueda = TextEditingController();
  String _categoria = 'Todos';
  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String _normalizar(String textoOriginal) {
    var valor = textoOriginal.toLowerCase();
    const acentuadas = 'áéíóúüñ';
    const sinAcentos = 'aeiouun';
    for (var indice = 0; indice < acentuadas.length; indice++) {
      valor = valor.replaceAll(acentuadas[indice], sinAcentos[indice]);
    }
    return valor;
  }

  @override
  Widget build(BuildContext contexto) => AnimatedBuilder(
    animation: widget.controlador,
    builder: (contexto, _) {
      final estadoAplicacion = widget.controlador;
      final mesa = estadoAplicacion.mesas
          .where((mesaActual) => mesaActual.id == widget.idMesa)
          .firstOrNull;
      final esPropia =
          estadoAplicacion.usuario != null &&
          mesa?.idMozo == estadoAplicacion.usuario!.id;
      final borrador = estadoAplicacion.borradorDeMesa(widget.idMesa);
      final categorias = [
        'Todos',
        ...estadoAplicacion.productos
            .map((productoActual) => productoActual.categoria)
            .toSet(),
      ];
      final productosVisibles = estadoAplicacion.productos
          .where(
            (productoActual) =>
                (_categoria == 'Todos' ||
                    productoActual.categoria == _categoria) &&
                _normalizar(
                  '${productoActual.nombre} ${productoActual.descripcion}',
                ).contains(_normalizar(_busqueda.text.trim())),
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
                  'Mesa ${mesa?.numero.toString().padLeft(2, '0') ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                Text(
                  mesa?.zona ?? 'Mesa no disponible',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChifaColors.tenue,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: estadoAplicacion.procesando
                    ? null
                    : estadoAplicacion.actualizarDatos,
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
                    if (estadoAplicacion.procesando)
                      const LinearProgressIndicator(minHeight: 2),
                    if (estadoAplicacion.error != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 145),
                        child: SingleChildScrollView(
                          child: ErrorNotice(
                            estadoAplicacion.error!,
                            alCerrar: estadoAplicacion.limpiarError,
                          ),
                        ),
                      ),
                    if (!esPropia)
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
                                      color: ChifaColors.dorado,
                                      icono:
                                          Icons.local_fire_department_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '¿Qué van a disfrutar?',
                                      style: Theme.of(contexto)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _busqueda,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar un plato o bebida',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                        ),
                                        suffixIcon: _busqueda.text.isEmpty
                                            ? null
                                            : IconButton(
                                                onPressed: () => setState(
                                                  () => _busqueda.clear(),
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
                                  children: categorias
                                      .map(
                                        (categoriaActual) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(categoriaActual),
                                            showCheckmark: false,
                                            selected:
                                                categoriaActual == _categoria,
                                            onSelected: (_) => setState(
                                              () =>
                                                  _categoria = categoriaActual,
                                            ),
                                            selectedColor: ChifaColors.rojo,
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color(0xFFE7E0D6),
                                            ),
                                            labelStyle: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  categoriaActual == _categoria
                                                  ? Colors.white
                                                  : ChifaColors.tenue,
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
                                  '${productosVisibles.length} opciones para compartir',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ChifaColors.tenue,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: productosVisibles.isEmpty
                                    ? const SingleChildScrollView(
                                        child: EmptyState(
                                          icono: Icons.search_off_rounded,
                                          titulo: 'No encontramos ese sabor',
                                          mensaje: 'Prueba con otro nombre o categoría.',
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          22,
                                          0,
                                          22,
                                          22,
                                        ),
                                        itemCount: productosVisibles.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (contexto, indice) {
                                          final productoActual =
                                              productosVisibles[indice];
                                          final cantidad =
                                              borrador?.detalles
                                                  .where(
                                                    (detalleActual) =>
                                                        detalleActual
                                                            .idProducto ==
                                                        productoActual.id,
                                                  )
                                                  .firstOrNull
                                                  ?.cantidad ??
                                              0;
                                          final puedeEditar =
                                              esPropia &&
                                              !estadoAplicacion.procesando &&
                                              !(borrador?.pendiente ?? false);
                                          return Paper(
                                            relleno: const EdgeInsets.all(14),
                                            contenido: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Opacity(
                                                  opacity:
                                                      productoActual.disponible
                                                      ? 1
                                                      : .4,
                                                  child: DishArt(
                                                    categoria: productoActual
                                                        .categoria,
                                                    tamano: 76,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (productoActual
                                                              .destacado &&
                                                          productoActual
                                                              .disponible)
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
                                                                  .dorado,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ),
                                                      Text(
                                                        productoActual.nombre,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        productoActual
                                                            .descripcion,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          height: 1.45,
                                                          color:
                                                              ChifaColors.tenue,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        formatearImporte(
                                                          productoActual
                                                              .precioCentimos,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              ChifaColors.rojo,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child:
                                                            !productoActual
                                                                .disponible
                                                            ? const Pill(
                                                                'Agotado',
                                                                color:
                                                                    ChifaColors
                                                                        .tenue,
                                                              )
                                                            : cantidad == 0
                                                            ? IconButton.filled(
                                                                onPressed:
                                                                    puedeEditar
                                                                    ? () => estadoAplicacion.modificarDetalle(
                                                                        widget
                                                                            .idMesa,
                                                                        productoActual,
                                                                        variacion:
                                                                            1,
                                                                      )
                                                                    : null,
                                                                tooltip:
                                                                    'Agregar ${productoActual.nombre}',
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
                                                                cantidad:
                                                                    cantidad,
                                                                alAgregar:
                                                                    puedeEditar
                                                                    ? () => estadoAplicacion.modificarDetalle(
                                                                        widget
                                                                            .idMesa,
                                                                        productoActual,
                                                                        variacion:
                                                                            1,
                                                                      )
                                                                    : null,
                                                                alQuitar:
                                                                    puedeEditar
                                                                    ? () => estadoAplicacion.modificarDetalle(
                                                                        widget
                                                                            .idMesa,
                                                                        productoActual,
                                                                        variacion:
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
                          TableAccount(
                            controlador: estadoAplicacion,
                            idMesa: widget.idMesa,
                          ),
                        ],
                      ),
                    ),
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
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    child: FilledButton(
                      onPressed: estadoAplicacion.procesando
                          ? null
                          : () => Navigator.push(
                              contexto,
                              MaterialPageRoute<void>(
                                builder: (_) => ReviewScreen(
                                  controlador: estadoAplicacion,
                                  idMesa: widget.idMesa,
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
                            child: Text('${borrador.cantidad}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              borrador.pendiente
                                  ? 'Confirmar envío'
                                  : 'Ver mi pedido',
                            ),
                          ),
                          Text(formatearImporte(borrador.totalCentimos)),
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
