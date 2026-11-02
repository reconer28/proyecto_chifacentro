import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/app.dart';
import 'package:proyecto_chifacentro/src/application/app_controller.dart';
import 'package:proyecto_chifacentro/src/data/demo_repository.dart';
import 'package:proyecto_chifacentro/src/data/local_store.dart';

class RepositorioAsignacionLenta extends DemoRepository {
  RepositorioAsignacionLenta({required super.almacenamiento})
    : super(demora: Duration.zero);
  final liberarAsignacion = Completer<void>();

  @override
  Future<void> asignarMesas(
    List<String> idsMesas,
    String claveAdministrador,
  ) async {
    await liberarAsignacion.future;
    await super.asignarMesas(idsMesas, claveAdministrador);
  }
}

void main() {
  testWidgets('El mozo ingresa, agrega platos y envia el pedido de su mesa', (
    probador,
  ) async {
    final almacenamiento = MemoryStore();
    final estadoAplicacion = AppController(
      repositorio: DemoRepository(
        almacenamiento: almacenamiento,
        demora: Duration.zero,
      ),
      almacenamiento: almacenamiento,
    );
    addTearDown(estadoAplicacion.dispose);
    await probador.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => probador.binding.setSurfaceSize(null));
    await probador.pumpWidget(ChifaApp(controlador: estadoAplicacion));
    await probador.enterText(find.byType(TextFormField).at(0), 'mozo');
    await probador.enterText(find.byType(TextFormField).at(1), '123456');
    await probador.ensureVisible(find.text('Comenzar mi turno'));
    await probador.tap(find.text('Comenzar mi turno'));
    await probador.pumpAndSettle();
    expect(find.text('Hola, Diego'), findsOneWidget);
    await probador.ensureVisible(find.text('Mesa 01'));
    await probador.tap(find.text('Mesa 01'));
    await probador.pumpAndSettle();
    await probador.tap(find.byTooltip('Agregar Arroz chaufa de pollo'));
    await probador.pumpAndSettle();
    await probador.tap(find.text('Ver mi pedido'));
    await probador.pumpAndSettle();
    expect(find.text('Todo en su punto.'), findsOneWidget);
    await probador.tap(find.text('Agregar observación'));
    await probador.pumpAndSettle();
    await probador.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Sin cebolla',
    );
    await probador.tap(find.text('Guardar'));
    await probador.pumpAndSettle();
    await probador.tap(find.text('Enviar pedido · S/ 18.00'));
    await probador.pumpAndSettle();
    await probador.tap(find.text('Enviar pedido'));
    await probador.pumpAndSettle();
    expect(estadoAplicacion.pedidos, hasLength(1));
    expect(estadoAplicacion.pedidos.single.totalCentimos, 1800);
    expect(
      estadoAplicacion.pedidos.single.detalles.single.observaciones,
      'Sin cebolla',
    );
    expect(estadoAplicacion.borradores, isEmpty);
    expect(probador.takeException(), isNull);
  });

  for (final ancho in [320.0, 430.0]) {
    testWidgets('Login y salon no desbordan a ${ancho.toInt()} px', (
      probador,
    ) async {
      final almacenamiento = MemoryStore();
      final estadoAplicacion = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(estadoAplicacion.dispose);
      await probador.binding.setSurfaceSize(Size(ancho, 780));
      addTearDown(() => probador.binding.setSurfaceSize(null));
      await probador.pumpWidget(ChifaApp(controlador: estadoAplicacion));
      await probador.pumpAndSettle();
      expect(probador.takeException(), isNull);
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      await probador.pumpAndSettle();
      await probador.ensureVisible(find.text('Mesa 01'));
      await probador.pumpAndSettle();
      await probador.tap(find.text('Mesa 01'));
      await probador.pumpAndSettle();
      await probador.tap(find.byTooltip('Agregar Arroz chaufa de pollo'));
      await probador.pumpAndSettle();
      await probador.tap(find.text('Ver mi pedido'));
      await probador.pumpAndSettle();
    });
  }

  testWidgets('Volver durante una asignación no utiliza campos ya liberados', (
    probador,
  ) async {
    final almacenamiento = MemoryStore();
    final repositorio = RepositorioAsignacionLenta(
      almacenamiento: almacenamiento,
    );
    final controlador = AppController(
      repositorio: repositorio,
      almacenamiento: almacenamiento,
    );
    addTearDown(controlador.dispose);
    await probador.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => probador.binding.setSurfaceSize(null));
    await controlador.iniciarSesion('mozo', '123456');
    await probador.pumpWidget(ChifaApp(controlador: controlador));
    await probador.pumpAndSettle();
    await probador.tap(find.text('Asignar'));
    await probador.pumpAndSettle();
    await probador.scrollUntilVisible(
      find.text('Confirmar 4 mesas'),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await probador.enterText(find.byType(TextFormField), '2468');
    await probador.ensureVisible(find.text('Confirmar 4 mesas'));
    await probador.tap(find.text('Confirmar 4 mesas'));
    await probador.pump();
    expect(controlador.procesando, isTrue);
    await probador.pageBack();
    await probador.pump(const Duration(milliseconds: 350));
    repositorio.liberarAsignacion.complete();
    await probador.pumpAndSettle();
    expect(controlador.procesando, isFalse);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(probador.takeException(), isNull);
  });
}
