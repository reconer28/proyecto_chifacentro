import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.clara = false, this.compacta = false});
  final bool clara;
  final bool compacta;
  @override
  Widget build(BuildContext contexto) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compacta ? 39 : 50,
        height: compacta ? 39 : 50,
        decoration: BoxDecoration(
          color: clara ? Colors.white.withValues(alpha: .12) : ChifaColors.rojo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.ramen_dining_rounded,
          color: Color(0xFFECC98E),
          size: 28,
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHIFA CENTRO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compacta ? 14 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: clara ? Colors.white : ChifaColors.tinta,
              ),
            ),
            Text(
              'TRADICIÓN EN CADA PEDIDO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compacta ? 7.5 : 9,
                letterSpacing: 1.45,
                color: clara ? const Color(0xFFECC98E) : ChifaColors.tenue,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.texto, {
    super.key,
    this.color = ChifaColors.verde,
    this.icono,
  });
  final String texto;
  final Color color;
  final IconData? icono;
  @override
  Widget build(BuildContext contexto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class Paper extends StatelessWidget {
  const Paper({
    super.key,
    required this.contenido,
    this.relleno = const EdgeInsets.all(18),
    this.color = Colors.white,
  });
  final Widget contenido;
  final EdgeInsetsGeometry relleno;
  final Color color;
  @override
  Widget build(BuildContext contexto) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFECE5DC)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: relleno, child: contenido),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });
  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;
  @override
  Widget build(BuildContext contexto) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF1E8DD),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 40, color: ChifaColors.dorado),
        ),
        const SizedBox(height: 20),
        Text(
          titulo,
          style: Theme.of(contexto).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          mensaje,
          style: const TextStyle(color: ChifaColors.tenue, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (accion != null) ...[const SizedBox(height: 20), accion!],
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.mensaje, {super.key, this.alCerrar});
  final String mensaje;
  final VoidCallback? alCerrar;
  @override
  Widget build(BuildContext contexto) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9DF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: ChifaColors.rojo,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            mensaje,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: ChifaColors.rojo,
            ),
          ),
        ),
        if (alCerrar != null)
          InkWell(
            onTap: alCerrar,
            child: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.close, size: 18),
            ),
          ),
      ],
    ),
  );
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.cantidad,
    required this.alAgregar,
    required this.alQuitar,
  });
  final int cantidad;
  final VoidCallback? alAgregar;
  final VoidCallback? alQuitar;
  @override
  Widget build(BuildContext contexto) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: alQuitar,
        tooltip: 'Quitar una unidad',
        icon: const Icon(Icons.remove_rounded, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: ChifaColors.crema,
          minimumSize: const Size(42, 42),
        ),
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$cantidad',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      IconButton(
        onPressed: alAgregar,
        tooltip: 'Agregar una unidad',
        icon: const Icon(Icons.add_rounded, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: ChifaColors.rojo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE7E0D6),
          minimumSize: const Size(42, 42),
        ),
      ),
    ],
  );
}

/// Dibuja los platos sin depender de imágenes externas.
class DishArt extends StatelessWidget {
  const DishArt({super.key, this.categoria = 'Chaufas', this.tamano = 94});
  final String categoria;
  final double tamano;
  @override
  Widget build(BuildContext contexto) => SizedBox(
    width: tamano,
    height: tamano,
    child: CustomPaint(painter: _DishPainter(categoria)),
  );
}

class _DishPainter extends CustomPainter {
  _DishPainter(this.categoria);
  final String categoria;
  @override
  void paint(Canvas lienzo, Size tamano) {
    lienzo.save();
    lienzo.scale(tamano.width / 100, tamano.height / 100);
    final pincel = Paint();
    pincel.color = const Color(0xFFF0E3CB);
    lienzo.drawCircle(const Offset(50, 50), 48, pincel);
    if (categoria == 'Bebidas') {
      pincel.color = const Color(0xFFE2B74F);
      lienzo.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 22, 36, 60),
          const Radius.circular(8),
        ),
        pincel,
      );
      pincel.color = const Color(0xFF773B61);
      lienzo.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 35, 30, 44),
          const Radius.circular(6),
        ),
        pincel,
      );
      pincel.color = Colors.white.withValues(alpha: .65);
      lienzo.drawRect(const Rect.fromLTWH(39, 40, 4, 27), pincel);
      pincel.color = ChifaColors.rojo;
      pincel.strokeWidth = 4;
      lienzo.drawLine(const Offset(58, 45), const Offset(65, 14), pincel);
    } else {
      pincel.color = const Color(0xFFD9C6A6);
      lienzo.drawOval(const Rect.fromLTWH(10, 53, 80, 35), pincel);
      pincel.color = const Color(0xFFFCFBF5);
      lienzo.drawOval(const Rect.fromLTWH(8, 20, 84, 64), pincel);
      pincel.color = const Color(0xFFD49B49);
      lienzo.drawOval(const Rect.fromLTWH(17, 28, 66, 45), pincel);
      final aleatorio = math.Random(categoria.hashCode);
      for (var indice = 0; indice < 100; indice++) {
        final x = 50 + (aleatorio.nextDouble() - .5) * 58;
        final y = 50 + (aleatorio.nextDouble() - .5) * 36;
        if (((x - 50) / 30) * ((x - 50) / 30) +
                ((y - 50) / 19) * ((y - 50) / 19) >
            1) {
          continue;
        }
        pincel.color = [
          const Color(0xFFF6D38C),
          const Color(0xFFE5B569),
          const Color(0xFF775330),
          const Color(0xFF63904C),
          const Color(0xFFCD693B),
        ][indice % 5];
        lienzo.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, categoria == 'Tallarines' ? 11 : 4.5, 2.8),
            const Radius.circular(2),
          ),
          pincel,
        );
      }
      pincel.color = const Color(0xFF493322);
      pincel.strokeWidth = 2.8;
      pincel.strokeCap = StrokeCap.round;
      lienzo.drawLine(const Offset(62, 29), const Offset(92, 8), pincel);
      lienzo.drawLine(const Offset(65, 35), const Offset(98, 17), pincel);
    }
    lienzo.restore();
  }

  @override
  bool shouldRepaint(_DishPainter delegadoAnterior) =>
      delegadoAnterior.categoria != categoria;
}

Future<T?> mostrarDialogoConCampos<T>(
  BuildContext contexto, {
  required WidgetBuilder constructor,
  required List<TextEditingController> campos,
}) async {
  final dialogo = DialogRoute<T>(context: contexto, builder: constructor);
  try {
    return await Navigator.of(contexto, rootNavigator: true).push(dialogo);
  } finally {
    // La animación de cierre debe terminar antes de liberar los campos.
    await dialogo.completed;
    for (final campo in campos) {
      campo.dispose();
    }
  }
}

Future<bool> confirmarAccion(
  BuildContext contexto, {
  required String titulo,
  required String mensaje,
  required String confirmar,
}) async =>
    await showDialog<bool>(
      context: contexto,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(confirmar),
          ),
        ],
      ),
    ) ??
    false;

void mostrarConfirmacion(BuildContext contexto, String texto) {
  ScaffoldMessenger.of(contexto).showSnackBar(
    SnackBar(
      content: Text(texto),
      backgroundColor: ChifaColors.verde,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
