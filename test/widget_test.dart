import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/app.dart';
import 'package:proyecto_chifacentro/src/application/app_controller.dart';
import 'package:proyecto_chifacentro/src/data/demo_repository.dart';
import 'package:proyecto_chifacentro/src/data/local_store.dart';

void main() {
  testWidgets('El mozo ingresa, agrega platos y envia el pedido de su mesa', (
    tester,
  ) async {
    final store = MemoryStore();
    final c = AppController(
      repository: DemoRepository(store: store, delay: Duration.zero),
      store: store,
    );
    addTearDown(c.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChifaApp(controller: c));
    await tester.enterText(find.byType(TextFormField).at(0), 'mozo');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(find.text('Comenzar mi turno'));
    await tester.tap(find.text('Comenzar mi turno'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Diego'), findsOneWidget);
    await tester.ensureVisible(find.text('Mesa 01'));
    await tester.tap(find.text('Mesa 01'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar Arroz chaufa de pollo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mi pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Todo en su punto.'), findsOneWidget);
    await tester.tap(find.text('Enviar pedido · S/ 18.00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar pedido'));
    await tester.pumpAndSettle();
    expect(c.orders, hasLength(1));
    expect(c.orders.single.totalCents, 1800);
    expect(c.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('Login y salon no desbordan a ${width.toInt()} px', (
      tester,
    ) async {
      final store = MemoryStore();
      final c = AppController(
        repository: DemoRepository(store: store, delay: Duration.zero),
        store: store,
      );
      addTearDown(c.dispose);
      await tester.binding.setSurfaceSize(Size(width, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ChifaApp(controller: c));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await c.login('mozo', '123456');
      await tester.pumpAndSettle();
    });
  }
}
