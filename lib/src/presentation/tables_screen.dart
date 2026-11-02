import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'assignment_screen.dart';
import 'menu_screen.dart';
import 'widgets.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, required this.controlador});
  final AppController controlador;
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String _filtro = 'Todas';
  @override
  Widget build(BuildContext contexto) {
    final estadoAplicacion = widget.controlador;
    final mesas = estadoAplicacion.misMesas;
    final ocupada = mesas.where((mesaActual) => mesaActual.ocupada).length;
    final mesasFiltradas = mesas
        .where(
          (mesaActual) => switch (_filtro) {
            'Libres' => !mesaActual.ocupada,
            'En atención' => mesaActual.ocupada,
            'Borradores' =>
              estadoAplicacion.borradorDeMesa(mesaActual.id) != null,
            _ => true,
          },
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await estadoAplicacion.actualizarDatos();
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
                              'Hola, ${estadoAplicacion.usuario!.nombre.split(' ').first}',
                              style: Theme.of(contexto).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Una buena atención empieza aquí.',
                              style: TextStyle(
                                color: ChifaColors.tenue,
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
                          estadoAplicacion.usuario!.nombre.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ChifaColors.dorado,
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
                      color: ChifaColors.rojo,
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
                            _Stat('${mesas.length}', 'Asignadas'),
                            _Stat('$ocupada', 'En atención'),
                            _Stat('${mesas.length - ocupada}', 'Libres'),
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
                          style: Theme.of(contexto).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: estadoAplicacion.procesando
                            ? null
                            : () => Navigator.push(
                                contexto,
                                MaterialPageRoute<void>(
                                  builder: (_) => AssignmentScreen(
                                    controlador: estadoAplicacion,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.tune_rounded, size: 17),
                        label: const Text('Asignar'),
                      ),
                    ],
                  ),
                  const Text(
                    'Selecciona una mesa para tomar su pedido.',
                    style: TextStyle(color: ChifaColors.tenue, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todas', 'Libres', 'En atención', 'Borradores']
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
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFE4DCD0),
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: _filtro == filtroActual
                                      ? Colors.white
                                      : ChifaColors.tenue,
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
          if (mesasFiltradas.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icono: Icons.table_restaurant_outlined,
                titulo: mesas.isEmpty
                    ? 'Tu turno empieza con una mesa'
                    : 'Sin mesas en este estado',
                mensaje: mesas.isEmpty
                    ? 'Asigna tus mesas con la autorización del administrador. Si aún están cargando, usa actualizar.'
                    : 'Prueba con otro filtro para ver tus mesas.',
                accion: mesas.isEmpty
                    ? FilledButton(
                        onPressed: estadoAplicacion.procesando
                            ? null
                            : () => Navigator.push(
                                contexto,
                                MaterialPageRoute<void>(
                                  builder: (_) => AssignmentScreen(
                                    controlador: estadoAplicacion,
                                  ),
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
              builder: (contexto, restricciones) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: restricciones.crossAxisExtent < 285
                      ? 1
                      : (restricciones.crossAxisExtent > 620 ? 3 : 2),
                  mainAxisExtent: MediaQuery.textScalerOf(contexto).scale(225),
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                ),
                delegate: SliverChildBuilderDelegate((contexto, indice) {
                  final mesaActual = mesasFiltradas[indice];
                  final borrador = estadoAplicacion.borradorDeMesa(
                    mesaActual.id,
                  );
                  return _TableCard(
                    mesa: mesaActual,
                    borrador: borrador,
                    alTocar: estadoAplicacion.procesando
                        ? null
                        : () => Navigator.push(
                            contexto,
                            MaterialPageRoute<void>(
                              builder: (_) => MenuScreen(
                                controlador: estadoAplicacion,
                                idMesa: mesaActual.id,
                              ),
                            ),
                          ),
                  );
                }, childCount: mesasFiltradas.length),
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
                    color: ChifaColors.tenue,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      estadoAplicacion.ultimaActualizacion == null
                          ? 'Desliza hacia abajo para actualizar'
                          : 'Actualizado a las ${TimeOfDay.fromDateTime(estadoAplicacion.ultimaActualizacion!).format(contexto)} · Desliza para actualizar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ChifaColors.tenue,
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
  const _Stat(this.numero, this.etiqueta);
  final String numero;
  final String etiqueta;
  @override
  Widget build(BuildContext contexto) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numero,
          style: const TextStyle(
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 11, color: Color(0xFFEBCBC3)),
        ),
      ],
    ),
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.mesa,
    required this.borrador,
    required this.alTocar,
  });
  final DiningTable mesa;
  final OrderDraft? borrador;
  final VoidCallback? alTocar;
  @override
  Widget build(BuildContext contexto) {
    final color = mesa.ocupada ? ChifaColors.rojo : ChifaColors.verde;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: mesa.ocupada
              ? const Color(0xFFE7C4BC)
              : const Color(0xFFE6E1D7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
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
                    '${mesa.capacidad} personas',
                    style: const TextStyle(
                      fontSize: 10,
                      color: ChifaColors.tenue,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 45,
                  color: mesa.ocupada
                      ? ChifaColors.rojo
                      : const Color(0xFFB6A48A),
                ),
              ),
              const Spacer(),
              Text(
                'Mesa ${mesa.numero.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                mesa.zona,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: ChifaColors.tenue),
              ),
              const SizedBox(height: 12),
              if (borrador != null)
                Pill(
                  borrador!.pendiente
                      ? 'Por confirmar'
                      : 'Borrador · ${borrador!.cantidad}',
                  color: ChifaColors.dorado,
                  icono: Icons.edit_note_rounded,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mesa.ocupada ? 'En atención' : 'Disponible',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (mesa.ocupada)
                      Text(
                        formatearImporte(mesa.totalCentimos),
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
