import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false, this.compact = false});
  final bool light;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 39 : 50,
        height: compact ? 39 : 50,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: .12) : ChifaColors.red,
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
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: light ? Colors.white : ChifaColors.ink,
              ),
            ),
            Text(
              'TRADICIÓN EN CADA PEDIDO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 7.5 : 9,
                letterSpacing: 1.45,
                color: light ? const Color(0xFFECC98E) : ChifaColors.muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = ChifaColors.green, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
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
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFECE5DC)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
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
          child: Icon(icon, size: 40, color: ChifaColors.gold),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: ChifaColors.muted, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key, this.onDismiss});
  final String message;
  final VoidCallback? onDismiss;
  @override
  Widget build(BuildContext context) => Container(
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
          color: ChifaColors.red,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: ChifaColors.red,
            ),
          ),
        ),
        if (onDismiss != null)
          InkWell(
            onTap: onDismiss,
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
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: onRemove,
        tooltip: 'Quitar una unidad',
        icon: const Icon(Icons.remove_rounded, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: ChifaColors.cream,
          minimumSize: const Size(42, 42),
        ),
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$quantity',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      IconButton(
        onPressed: onAdd,
        tooltip: 'Agregar una unidad',
        icon: const Icon(Icons.add_rounded, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: ChifaColors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE7E0D6),
          minimumSize: const Size(42, 42),
        ),
      ),
    ],
  );
}

/// Original vector dish illustration; no remote image dependency.
class DishArt extends StatelessWidget {
  const DishArt({super.key, this.category = 'Chaufas', this.size = 94});
  final String category;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _DishPainter(category)),
  );
}

class _DishPainter extends CustomPainter {
  _DishPainter(this.category);
  final String category;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint();
    p.color = const Color(0xFFF0E3CB);
    canvas.drawCircle(const Offset(50, 50), 48, p);
    if (category == 'Bebidas') {
      p.color = const Color(0xFFE2B74F);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 22, 36, 60),
          const Radius.circular(8),
        ),
        p,
      );
      p.color = const Color(0xFF773B61);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 35, 30, 44),
          const Radius.circular(6),
        ),
        p,
      );
      p.color = Colors.white.withValues(alpha: .65);
      canvas.drawRect(const Rect.fromLTWH(39, 40, 4, 27), p);
      p.color = ChifaColors.red;
      p.strokeWidth = 4;
      canvas.drawLine(const Offset(58, 45), const Offset(65, 14), p);
    } else {
      p.color = const Color(0xFFD9C6A6);
      canvas.drawOval(const Rect.fromLTWH(10, 53, 80, 35), p);
      p.color = const Color(0xFFFCFBF5);
      canvas.drawOval(const Rect.fromLTWH(8, 20, 84, 64), p);
      p.color = const Color(0xFFD49B49);
      canvas.drawOval(const Rect.fromLTWH(17, 28, 66, 45), p);
      final rng = math.Random(category.hashCode);
      for (var i = 0; i < 100; i++) {
        final x = 50 + (rng.nextDouble() - .5) * 58;
        final y = 50 + (rng.nextDouble() - .5) * 36;
        if (((x - 50) / 30) * ((x - 50) / 30) +
                ((y - 50) / 19) * ((y - 50) / 19) >
            1) {
          continue;
        }
        p.color = [
          const Color(0xFFF6D38C),
          const Color(0xFFE5B569),
          const Color(0xFF775330),
          const Color(0xFF63904C),
          const Color(0xFFCD693B),
        ][i % 5];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, category == 'Tallarines' ? 11 : 4.5, 2.8),
            const Radius.circular(2),
          ),
          p,
        );
      }
      p.color = const Color(0xFF493322);
      p.strokeWidth = 2.8;
      p.strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(62, 29), const Offset(92, 8), p);
      canvas.drawLine(const Offset(65, 35), const Offset(98, 17), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DishPainter oldDelegate) =>
      oldDelegate.category != category;
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

void notifySuccess(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: ChifaColors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
